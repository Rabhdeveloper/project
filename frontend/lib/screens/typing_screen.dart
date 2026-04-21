import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TypingScreen extends StatefulWidget {
  const TypingScreen({super.key});

  @override
  State<TypingScreen> createState() => _TypingScreenState();
}

class _TypingScreenState extends State<TypingScreen> {
  // ── Sample Passages ───────────────────────────────────────────────────────────
  static const List<String> _passages = [
    "The quick brown fox jumps over the lazy dog near the riverbank on a sunny afternoon.",
    "Success is not final, failure is not fatal: it is the courage to continue that counts.",
    "Productivity is never an accident. It is always the result of a commitment to excellence.",
    "Learning to type faster is one of the most valuable skills you can develop as a student.",
    "Every expert was once a beginner. Practice consistently and you will see great improvement.",
    "Focus on being productive instead of busy. Small daily improvements lead to stunning results.",
    "The journey of a thousand miles begins with a single step. Start now and never look back.",
  ];

  // ── State ─────────────────────────────────────────────────────────────────────
  late String _targetText;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _isStarted = false;
  bool _isFinished = false;
  int _elapsedSeconds = 0;
  Timer? _timer;

  int _correctChars = 0;
  int _errorChars = 0;
  int _currentPos = 0;

  @override
  void initState() {
    super.initState();
    _loadNewPassage();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Core Logic ────────────────────────────────────────────────────────────────

  void _loadNewPassage() {
    final rng = Random();
    _targetText = _passages[rng.nextInt(_passages.length)];
  }

  void _onTextChanged() {
    if (_isFinished) return;

    final typed = _controller.text;

    // Start timer on first keystroke
    if (!_isStarted && typed.isNotEmpty) {
      _isStarted = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsedSeconds++);
      });
    }

    setState(() {
      _currentPos = typed.length;
      _correctChars = 0;
      _errorChars = 0;

      for (int i = 0; i < typed.length && i < _targetText.length; i++) {
        if (typed[i] == _targetText[i]) {
          _correctChars++;
        } else {
          _errorChars++;
        }
      }

      // Completed
      if (typed.length >= _targetText.length) {
        _isFinished = true;
        _timer?.cancel();
        // Vibrate on finish
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _restart() {
    _timer?.cancel();
    _controller.clear();
    setState(() {
      _loadNewPassage();
      _isStarted = false;
      _isFinished = false;
      _elapsedSeconds = 0;
      _correctChars = 0;
      _errorChars = 0;
      _currentPos = 0;
    });
    _focusNode.requestFocus();
  }

  // ── Metrics ───────────────────────────────────────────────────────────────────

  int get _wpm {
    if (_elapsedSeconds == 0) return 0;
    final minutes = _elapsedSeconds / 60;
    final words = _correctChars / 5; // standard: 5 chars = 1 word
    return (words / minutes).round();
  }

  double get _accuracy {
    final total = _correctChars + _errorChars;
    if (total == 0) return 100.0;
    return (_correctChars / total * 100);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color _getCharColor(int index) {
    if (index >= _currentPos) return Colors.grey.shade600;
    final typed = _controller.text;
    if (index >= typed.length) return Colors.grey.shade600;
    return typed[index] == _targetText[index]
        ? const Color(0xFF10B981) // correct = green
        : const Color(0xFFEF4444); // wrong = red
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Typing Practice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'New text',
            onPressed: _restart,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isFinished ? _buildResults() : _buildTypingView(),
      ),
    );
  }

  // ── Typing View ───────────────────────────────────────────────────────────────

  Widget _buildTypingView() {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stats Row ────────────────────────────────────────────────────
            Row(
              children: [
                _StatChip(
                  label: 'WPM',
                  value: '$_wpm',
                  color: const Color(0xFF6366F1),
                  icon: Icons.speed_rounded,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: 'Accuracy',
                  value: '${_accuracy.toStringAsFixed(1)}%',
                  color: const Color(0xFF10B981),
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: 'Time',
                  value: _formatTime(_elapsedSeconds),
                  color: const Color(0xFFF59E0B),
                  icon: Icons.timer_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Progress Bar ─────────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _targetText.isEmpty
                    ? 0
                    : _currentPos / _targetText.length,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF6366F1),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Text Display ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isStarted
                      ? const Color(0xFF6366F1).withOpacity(0.4)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: RichText(
                text: TextSpan(
                  children: List.generate(_targetText.length, (i) {
                    final isCurrentPos = i == _currentPos;
                    return TextSpan(
                      text: _targetText[i],
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.8,
                        letterSpacing: 0.5,
                        color: _getCharColor(i),
                        fontWeight: isCurrentPos
                            ? FontWeight.bold
                            : FontWeight.normal,
                        backgroundColor: isCurrentPos
                            ? const Color(0xFF6366F1).withOpacity(0.3)
                            : Colors.transparent,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Input Field ───────────────────────────────────────────────────
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              maxLines: 3,
              enabled: !_isFinished,
              decoration: InputDecoration(
                hintText: _isStarted
                    ? 'Keep typing...'
                    : 'Tap here and start typing to begin the timer...',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 2,
                  ),
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 16),
            if (!_isStarted)
              Center(
                child: Text(
                  'Timer starts on your first keystroke',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Results View ─────────────────────────────────────────────────────────────

  Widget _buildResults() {
    final grade = _wpm >= 80
        ? '🏆 Excellent!'
        : _wpm >= 60
            ? '⭐ Great Job!'
            : _wpm >= 40
                ? '👍 Good Work!'
                : '💪 Keep Practicing!';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Grade Badge ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              grade,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // ── Results Grid ───────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ResultCard(
                  label: 'WPM',
                  value: '$_wpm',
                  icon: Icons.speed_rounded,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ResultCard(
                  label: 'Accuracy',
                  value: '${_accuracy.toStringAsFixed(1)}%',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ResultCard(
                  label: 'Time',
                  value: _formatTime(_elapsedSeconds),
                  icon: Icons.timer_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ResultCard(
                  label: 'Errors',
                  value: '$_errorChars',
                  icon: Icons.close_rounded,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // ── Try Again ─────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _restart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-Widgets ──────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
