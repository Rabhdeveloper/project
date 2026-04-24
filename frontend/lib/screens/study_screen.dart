import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen>
    with SingleTickerProviderStateMixin {
  // ── Timer config ────────────────────────────────────────────────────────────
  static const List<int> _focusOptions = [15, 25, 30, 45, 60];
  static const List<int> _breakOptions = [5, 10, 15];

  int _focusMinutes = 25;
  int _breakMinutes = 5;

  // ── State ────────────────────────────────────────────────────────────────────
  bool _isStudyMode = true;
  bool _isRunning = false;
  late int _secondsRemaining;
  int _sessionsCompleted = 0;
  Timer? _timer;
  late AnimationController _pulseController;
  final _apiService = ApiService();

  // ── Subjects ─────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _subjects = [];
  String? _selectedSubjectId;
  String? _selectedSubjectColor;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = _focusMinutes * 60;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _loadPreferences();
    _loadSubjects();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final focus = prefs.getInt('focus_duration') ?? 25;
    final breakD = prefs.getInt('break_duration') ?? 5;
    if (mounted) {
      setState(() {
        _focusMinutes = focus;
        _breakMinutes = breakD;
        if (!_isRunning) {
          _secondsRemaining = _isStudyMode ? _focusMinutes * 60 : _breakMinutes * 60;
        }
      });
    }
  }

  Future<void> _loadSubjects() async {
    try {
      final response = await _apiService.client.get('/api/subjects');
      if (mounted) {
        setState(() {
          _subjects = List<Map<String, dynamic>>.from(response.data);
        });
      }
    } catch (e) {
      debugPrint('Failed to load subjects: $e');
    }
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
          _isStudyMode ? _focusMinutes * 60 : _breakMinutes * 60;
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
          _isStudyMode ? _focusMinutes * 60 : _breakMinutes * 60;
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
          'duration_minutes': _focusMinutes,
          'session_type': 'focus',
          if (_selectedSubjectId != null) 'subject_id': _selectedSubjectId,
        },
      );

      // Also check achievements after each session
      try {
        final checkResponse =
            await _apiService.client.post('/api/achievements/check');
        final newlyUnlocked = checkResponse.data['newly_unlocked'] as List? ?? [];
        if (newlyUnlocked.isNotEmpty && mounted) {
          for (final badge in newlyUnlocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Text(badge['icon'] ?? '🏆', style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Achievement Unlocked: ${badge['title']}!',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFF59E0B),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (_) {}

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
          _isStudyMode ? _focusMinutes * 60 : _breakMinutes * 60;
    });
  }

  void _setFocusDuration(int minutes) {
    if (_isRunning) return;
    setState(() {
      _focusMinutes = minutes;
      if (_isStudyMode) _secondsRemaining = minutes * 60;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('focus_duration', minutes);
    });
  }

  void _setBreakDuration(int minutes) {
    if (_isRunning) return;
    setState(() {
      _breakMinutes = minutes;
      if (!_isStudyMode) _secondsRemaining = minutes * 60;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('break_duration', minutes);
    });
  }

  void _showCreateSubjectSheet() {
    final nameController = TextEditingController();
    final colors = [
      '#6366F1', '#10B981', '#F59E0B', '#EF4444', '#3B82F6',
      '#8B5CF6', '#EC4899', '#14B8A6', '#F97316',
    ];
    final icons = ['📖', '🧮', '🔬', '🌍', '🎨', '📐', '💻', '🎵', '📝', '🧪'];
    String selectedColor = colors[0];
    String selectedIcon = icons[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Subject',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Subject Name',
                    hintText: 'e.g. Mathematics',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Icon', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: icons.map((icon) {
                    final sel = selectedIcon == icon;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedIcon = icon),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFF6366F1).withOpacity(0.2)
                              : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? const Color(0xFF6366F1)
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Color', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: colors.map((hex) {
                    final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                    final sel = selectedColor == hex;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedColor = hex),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: sel ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      try {
                        await _apiService.client.post('/api/subjects', data: {
                          'name': name,
                          'color': selectedColor,
                          'icon': selectedIcon,
                        });
                        Navigator.of(ctx).pop();
                        _loadSubjects();
                      } catch (e) {
                        debugPrint('Failed to create subject: $e');
                      }
                    },
                    child: const Text(
                      'Create Subject',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress {
    final total = _isStudyMode ? _focusMinutes * 60 : _breakMinutes * 60;
    return 1.0 - (_secondsRemaining / total);
  }

  Color get _modeColor {
    if (_selectedSubjectColor != null && _isStudyMode) {
      try {
        return Color(
            int.parse(_selectedSubjectColor!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return _isStudyMode ? const Color(0xFF6366F1) : const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Timer'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              // ── Subject Tags ──────────────────────────────────────────────
              if (_subjects.isNotEmpty || true)
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Existing subjects
                      ..._subjects.map((subj) {
                        final id = subj['id'] as String;
                        final name = subj['name'] as String;
                        final icon = subj['icon'] as String? ?? '📖';
                        final colorHex = subj['color'] as String? ?? '#6366F1';
                        final isSelected = _selectedSubjectId == id;
                        Color chipColor;
                        try {
                          chipColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                        } catch (_) {
                          chipColor = const Color(0xFF6366F1);
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: Text(icon, style: const TextStyle(fontSize: 16)),
                            label: Text(name),
                            selected: isSelected,
                            selectedColor: chipColor.withOpacity(0.25),
                            backgroundColor: const Color(0xFF1E293B),
                            labelStyle: TextStyle(
                              color: isSelected ? chipColor : Colors.grey[400],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected ? chipColor : Colors.grey.withOpacity(0.15),
                            ),
                            onSelected: (_) {
                              setState(() {
                                if (isSelected) {
                                  _selectedSubjectId = null;
                                  _selectedSubjectColor = null;
                                } else {
                                  _selectedSubjectId = id;
                                  _selectedSubjectColor = colorHex;
                                }
                              });
                            },
                          ),
                        );
                      }),
                      // Add new subject chip
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 18, color: Color(0xFF6366F1)),
                        label: const Text('Add'),
                        backgroundColor: const Color(0xFF1E293B),
                        labelStyle: const TextStyle(color: Color(0xFF6366F1)),
                        side: BorderSide(
                          color: const Color(0xFF6366F1).withOpacity(0.2),
                        ),
                        onPressed: _showCreateSubjectSheet,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

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
              const SizedBox(height: 12),

              // ── Duration Picker Chips ──────────────────────────────────────
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: (_isStudyMode ? _focusOptions : _breakOptions)
                      .map((mins) {
                    final selected = _isStudyMode
                        ? _focusMinutes == mins
                        : _breakMinutes == mins;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$mins min'),
                        selected: selected,
                        selectedColor: _modeColor.withOpacity(0.25),
                        backgroundColor: const Color(0xFF0F172A),
                        labelStyle: TextStyle(
                          color: selected ? _modeColor : Colors.grey[500],
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: selected
                              ? _modeColor
                              : Colors.grey.withOpacity(0.15),
                        ),
                        visualDensity: VisualDensity.compact,
                        onSelected: _isRunning
                            ? null
                            : (_) {
                                if (_isStudyMode) {
                                  _setFocusDuration(mins);
                                } else {
                                  _setBreakDuration(mins);
                                }
                              },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),

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
              const SizedBox(height: 40),

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
              const SizedBox(height: 32),

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
                      value: '${_focusMinutes}m',
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
                      value: '${_sessionsCompleted * _focusMinutes}m',
                      icon: Icons.timer_outlined,
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
