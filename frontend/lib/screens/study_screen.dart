import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen>
    with SingleTickerProviderStateMixin {
  // ── Timer config ────────────────────────────────────────────────────────────
  static const int _studyDuration = 25 * 60; // 25 minutes in seconds
  static const int _breakDuration = 5 * 60;  // 5 minutes in seconds

  // ── State ────────────────────────────────────────────────────────────────────
  bool _isStudyMode = true;
  bool _isRunning = false;
  int _secondsRemaining = _studyDuration;
  int _sessionsCompleted = 0;
  Timer? _timer;
  late AnimationController _pulseController;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Controls ─────────────────────────────────────────────────────────────────

  void _startPause() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      _pulseController.stop();
    } else {
      setState(() => _isRunning = true);
      _pulseController.repeat(reverse: true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _onTimerComplete();
        }
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isRunning = false;
      _secondsRemaining =
          _isStudyMode ? _studyDuration : _breakDuration;
    });
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _pulseController.stop();

    final wasStudyMode = _isStudyMode;

    setState(() {
      _isRunning = false;
      if (_isStudyMode) _sessionsCompleted++;
      _isStudyMode = !_isStudyMode;
      _secondsRemaining =
          _isStudyMode ? _studyDuration : _breakDuration;
    });

    // Save completed study session to backend
    if (wasStudyMode) {
      _saveSession();
    }

    // Show completion notification
    if (mounted) {
      final message = _isStudyMode
          ? '☕ Break time over! Let\'s focus again.'
          : '🎉 Study session complete! Time to rest.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              _isStudyMode ? const Color(0xFF6366F1) : const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _saveSession() async {
    try {
      await _apiService.client.post(
        '/api/sessions',
        data: {
          'duration_minutes': 25,
          'session_type': 'focus',
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Session saved! ✅'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Don't block the timer flow — just show a subtle warning
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ Could not save session'),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _switchMode(bool toStudy) {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isRunning = false;
      _isStudyMode = toStudy;
      _secondsRemaining =
          _isStudyMode ? _studyDuration : _breakDuration;
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress {
    final total = _isStudyMode ? _studyDuration : _breakDuration;
    return 1.0 - (_secondsRemaining / total);
  }

  Color get _modeColor =>
      _isStudyMode ? const Color(0xFF6366F1) : const Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Timer'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              // ── Mode Toggle ────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeTab(
                        label: '🧠 Focus',
                        isSelected: _isStudyMode,
                        color: const Color(0xFF6366F1),
                        onTap: () => _switchMode(true),
                      ),
                    ),
                    Expanded(
                      child: _ModeTab(
                        label: '☕ Break',
                        isSelected: !_isStudyMode,
                        color: const Color(0xFF10B981),
                        onTap: () => _switchMode(false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // ── Circular Progress Timer ────────────────────────────────────
              SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background ring
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 12,
                        color: _modeColor.withOpacity(0.12),
                      ),
                    ),
                    // Progress ring
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 12,
                        color: _modeColor,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    // Pulsing glow when running
                    if (_isRunning)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, __) => Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _modeColor.withOpacity(
                                    0.08 + 0.12 * _pulseController.value),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Time display
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(_secondsRemaining),
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -2,
                            color: _modeColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isStudyMode ? 'Focus Time' : 'Break Time',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // ── Controls ───────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset
                  _ControlButton(
                    icon: Icons.refresh_rounded,
                    onTap: _reset,
                    color: Colors.grey[600]!,
                    size: 52,
                  ),
                  const SizedBox(width: 24),
                  // Start / Pause (main)
                  GestureDetector(
                    onTap: _startPause,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_modeColor, _modeColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _modeColor.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Skip
                  _ControlButton(
                    icon: Icons.skip_next_rounded,
                    onTap: _onTimerComplete,
                    color: Colors.grey[600]!,
                    size: 52,
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // ── Sessions Counter ────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Sessions Done',
                      value: '$_sessionsCompleted',
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFF10B981),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.08),
                    ),
                    _StatItem(
                      label: 'Focus Goal',
                      value: '4 sessions',
                      icon: Icons.flag_outlined,
                      color: const Color(0xFF6366F1),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.08),
                    ),
                    _StatItem(
                      label: 'Total Focus',
                      value: '${_sessionsCompleted * 25}m',
                      icon: Icons.timer_outlined,
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sub-Widgets ──────────────────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey[500],
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }
}
