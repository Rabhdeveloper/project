import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class TypingScreen extends StatefulWidget {
  const TypingScreen({super.key});

  @override
  State<TypingScreen> createState() => _TypingScreenState();
}

class _TypingScreenState extends State<TypingScreen> {
  // ── Word Pools by Difficulty ─────────────────────────────────────────────────

  static const List<String> _easyWords = [
    'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'can', 'had',
    'her', 'was', 'one', 'our', 'out', 'day', 'get', 'has', 'him', 'his',
    'how', 'its', 'may', 'new', 'now', 'old', 'see', 'way', 'who', 'did',
    'let', 'say', 'she', 'too', 'use', 'big', 'run', 'set', 'try', 'ask',
    'men', 'put', 'end', 'far', 'hand', 'high', 'keep', 'last', 'long',
    'make', 'much', 'name', 'only', 'over', 'such', 'take', 'than', 'them',
    'well', 'back', 'been', 'call', 'came', 'come', 'each', 'find', 'from',
    'give', 'good', 'have', 'help', 'here', 'home', 'just', 'know', 'like',
    'live', 'look', 'most', 'part', 'read', 'some', 'that', 'then', 'time',
    'very', 'want', 'what', 'when', 'will', 'with', 'word', 'work', 'year',
    'also', 'city', 'does', 'down', 'even', 'food', 'goes', 'head', 'into',
    'life', 'line', 'love', 'many', 'more', 'move', 'need', 'open', 'page',
    'play', 'real', 'same', 'show', 'side', 'small', 'sure', 'tell', 'turn',
    'used', 'went', 'best', 'body', 'both', 'book', 'care', 'door', 'done',
    'face', 'fact', 'feel', 'form', 'girl', 'grow', 'idea', 'kind', 'land',
    'left', 'list', 'lose', 'mind', 'miss', 'next', 'plan', 'point', 'room',
    'rule', 'stop', 'talk', 'walk', 'wait', 'week', 'about', 'after',
    'again', 'being', 'below', 'every', 'first', 'found', 'great', 'group',
    'house', 'large', 'later', 'learn', 'never', 'night', 'paper', 'place',
    'plant', 'right', 'start', 'state', 'still', 'story', 'study', 'thing',
    'think', 'three', 'under', 'water', 'where', 'while', 'world', 'write',
    'young', 'begin', 'black', 'bring', 'build', 'carry', 'catch', 'clean',
    'clear', 'close', 'color', 'cover', 'cross', 'draw', 'drink', 'drive',
    'earth', 'eight', 'enjoy', 'equal', 'event', 'field', 'final', 'floor',
  ];

  static const List<String> _mediumWords = [
    'ability', 'absence', 'account', 'achieve', 'address', 'advance',
    'against', 'already', 'another', 'anxiety', 'applied', 'attempt',
    'balance', 'because', 'believe', 'benefit', 'between', 'brought',
    'cabinet', 'capital', 'careful', 'central', 'certain', 'chamber',
    'chapter', 'classic', 'climate', 'college', 'comfort', 'command',
    'comment', 'company', 'compare', 'complex', 'concept', 'concern',
    'confirm', 'connect', 'content', 'context', 'control', 'convert',
    'correct', 'council', 'country', 'counter', 'course', 'created',
    'culture', 'current', 'dealing', 'decided', 'decline', 'default',
    'defense', 'defense', 'deliver', 'deposit', 'deserve', 'desktop',
    'develop', 'digital', 'discuss', 'display', 'drawing', 'eastern',
    'economy', 'edition', 'element', 'emotion', 'enforce', 'episode',
    'essence', 'evening', 'evident', 'examine', 'example', 'excited',
    'execute', 'expense', 'explain', 'extreme', 'fashion', 'feature',
    'fiction', 'finally', 'finance', 'foreign', 'formula', 'forward',
    'founder', 'freedom', 'further', 'general', 'genuine', 'glimpse',
    'gravity', 'greatly', 'growing', 'habitat', 'halfway', 'handler',
    'healthy', 'helpful', 'highway', 'history', 'holding', 'horizon',
    'housing', 'however', 'hunting', 'imagine', 'improve', 'include',
    'insight', 'inspect', 'intense', 'involve', 'justice', 'kitchen',
    'leading', 'lecture', 'library', 'limited', 'logical', 'machine',
    'manager', 'massive', 'meaning', 'measure', 'medical', 'mention',
    'message', 'million', 'mineral', 'mission', 'mistake', 'mixture',
    'monitor', 'morning', 'natural', 'nervous', 'network', 'neutral',
    'notable', 'nothing', 'nowhere', 'nursing', 'obvious', 'offense',
    'operate', 'opinion', 'organic', 'outline', 'outside', 'overall',
    'package', 'parking', 'partner', 'passage', 'passion', 'patient',
    'pattern', 'payment', 'penalty', 'pension', 'perfect', 'persist',
    'picture', 'pioneer', 'plastic', 'popular', 'portion', 'poverty',
    'predict', 'premium', 'prepare', 'present', 'prevent', 'primary',
    'privacy', 'problem', 'process', 'produce', 'product', 'profile',
    'program', 'project', 'promise', 'protect', 'provide', 'publish',
    'purpose', 'quality', 'quarter', 'quickly', 'radical', 'realize',
    'receive', 'recover', 'regular', 'related', 'release', 'request',
    'require', 'resolve', 'respect', 'restore', 'revenue', 'routine',
    'satisfy', 'scholar', 'section', 'segment', 'serious', 'service',
    'shelter', 'shortly', 'similar', 'society', 'soldier', 'somehow',
    'sponsor', 'squeeze', 'storage', 'strange', 'stretch', 'student',
    'subject', 'succeed', 'success', 'summary', 'support', 'surface',
    'survive', 'teacher', 'therapy', 'through', 'tonight', 'totally',
    'tourism', 'trouble', 'turning', 'typical', 'undergo', 'variety',
    'vehicle', 'venture', 'version', 'village', 'visible', 'waiting',
    'walking', 'warning', 'weather', 'weaving', 'wedding', 'weekend',
    'welcome', 'western', 'whether', 'willing', 'winning', 'witness',
    'working', 'writing', 'academy', 'adopted', 'brother', 'ceiling',
  ];

  static const List<String> _hardWords = [
    'abbreviation', 'accommodate', 'accomplishment', 'acknowledgement',
    'administration', 'advertisement', 'approximately', 'archaeological',
    'autobiography', 'breathtaking', 'cardiovascular', 'characteristic',
    'circumference', 'collaboration', 'communication', 'comprehensive',
    'concentration', 'consciousness', 'consolidation', 'constitutional',
    'controversial', 'correspondence', 'cybersecurity', 'decommission',
    'demonstration', 'determination', 'disappointing', 'discrimination',
    'documentation', 'effectiveness', 'electromagnetic', 'encyclopedia',
    'entrepreneurial', 'environmental', 'establishment', 'extraordinary',
    'fundamentally', 'generalization', 'globalization', 'hallucination',
    'heterogeneous', 'implementation', 'improvisation', 'inappropriate',
    'independently', 'infrastructure', 'insignificant', 'institutional',
    'interpretation', 'investigation', 'justification', 'knowledgeable',
    'manufacturing', 'mathematician', 'microorganism', 'misconception',
    'misunderstand', 'multidisciplinary', 'nanotechnology', 'nevertheless',
    'nongovernmental', 'objectification', 'organizational', 'overwhelming',
    'paradoxically', 'pharmaceutical', 'philanthropist', 'philosophical',
    'photosynthesis', 'predominantly', 'unprecedented', 'professionalism',
    'proportionately', 'psychologically', 'qualifications', 'quintessential',
    'recommendation', 'rehabilitation', 'representative', 'responsibility',
    'retrospectively', 'revolutionize', 'simultaneously', 'sophistication',
    'standardization', 'straightforward', 'sustainability', 'synchronization',
    'telecommunications', 'transformation', 'transportation', 'troubleshooting',
    'uncomfortable', 'underestimate', 'understanding', 'unfortunately',
    'unquestionable', 'visualization', 'vulnerability', 'wholesomeness',
    'acknowledgment', 'approximately', 'authentication', 'compartmentalize',
    'differentiation', 'exponentially', 'fundamentalist', 'incomprehensible',
    'indistinguishable', 'initialization', 'internationalize', 'microprocessor',
    'oversimplification', 'procrastination', 'semiconductor', 'superstitious',
    'thunderstorm', 'transcontinental', 'unpredictable', 'whistleblower',
  ];

  // ── Time Options (in minutes) ───────────────────────────────────────────────
  static const List<int> _timeOptions = [1, 2, 3, 5, 10, 15, 30];
  static const List<String> _difficultyLabels = ['Easy', 'Medium', 'Hard'];
  static const List<Color> _difficultyColors = [
    Color(0xFF10B981), // green
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // red
  ];
  static const List<IconData> _difficultyIcons = [
    Icons.sentiment_satisfied_rounded,
    Icons.sentiment_neutral_rounded,
    Icons.sentiment_very_dissatisfied_rounded,
  ];

  // ── State ─────────────────────────────────────────────────────────────────────
  int _selectedTime = 1; // minutes
  int _selectedDifficulty = 0; // 0=easy, 1=medium, 2=hard
  bool _inSetup = true; // show setup screen first

  late String _targetText;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _apiService = ApiService();

  bool _isStarted = false;
  bool _isFinished = false;
  bool _isSaved = false;
  int _elapsedSeconds = 0;
  int _totalTimeSeconds = 60; // computed from _selectedTime
  Timer? _timer;

  int _correctChars = 0;
  int _errorChars = 0;
  int _currentPos = 0;
  int _wordsTyped = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Text Generation ─────────────────────────────────────────────────────────

  List<String> _getWordPool() {
    switch (_selectedDifficulty) {
      case 0:
        return _easyWords;
      case 1:
        return _mediumWords;
      case 2:
        return _hardWords;
      default:
        return _easyWords;
    }
  }

  String _generateText() {
    final pool = _getWordPool();
    final rng = Random();
    // Generate enough words for the selected time
    // Average typist: ~40 wpm, fast: ~80 wpm. Generate plenty (~100 wpm worth)
    final wordCount = _selectedTime * 100;
    final words = List.generate(wordCount, (_) => pool[rng.nextInt(pool.length)]);
    return words.join(' ');
  }

  // ── Setup → Start ──────────────────────────────────────────────────────────

  void _startTest() {
    _targetText = _generateText();
    _totalTimeSeconds = _selectedTime * 60;
    setState(() {
      _inSetup = false;
      _isStarted = false;
      _isFinished = false;
      _isSaved = false;
      _elapsedSeconds = 0;
      _correctChars = 0;
      _errorChars = 0;
      _currentPos = 0;
      _wordsTyped = 0;
    });
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNode.requestFocus();
    });
  }

  // ── Core Logic ────────────────────────────────────────────────────────────────

  void _onTextChanged() {
    if (_isFinished) return;

    final typed = _controller.text;

    // Start countdown on first keystroke
    if (!_isStarted && typed.isNotEmpty) {
      _isStarted = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsedSeconds++);
        // Time's up!
        if (_elapsedSeconds >= _totalTimeSeconds) {
          _finishTest();
        }
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

      // Count words typed (by spaces)
      _wordsTyped = typed.trim().isEmpty ? 0 : typed.trim().split(RegExp(r'\s+')).length;

      // If user typed all generated text (unlikely but handle it)
      if (typed.length >= _targetText.length) {
        _finishTest();
      }
    });
  }

  void _finishTest() {
    _timer?.cancel();
    setState(() => _isFinished = true);
    HapticFeedback.mediumImpact();
    _saveTypingResult();
  }

  Future<void> _saveTypingResult() async {
    try {
      await _apiService.client.post(
        '/api/typing',
        data: {
          'wpm': _wpm,
          'accuracy': double.parse(_accuracy.toStringAsFixed(1)),
          'duration_seconds': _elapsedSeconds,
        },
      );
      if (mounted) {
        setState(() => _isSaved = true);
      }
    } catch (e) {
      debugPrint('Failed to save typing result: $e');
    }
  }

  void _backToSetup() {
    _timer?.cancel();
    _controller.clear();
    setState(() {
      _inSetup = true;
      _isStarted = false;
      _isFinished = false;
      _isSaved = false;
      _elapsedSeconds = 0;
      _correctChars = 0;
      _errorChars = 0;
      _currentPos = 0;
      _wordsTyped = 0;
    });
  }

  void _retryTest() {
    _startTest();
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

  int get _remainingSeconds => (_totalTimeSeconds - _elapsedSeconds).clamp(0, _totalTimeSeconds);

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
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    if (_inSetup) return _buildSetupScreen();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_difficultyLabels[_selectedDifficulty]} • ${_selectedTime}min',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _backToSetup,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Restart',
            onPressed: _retryTest,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isFinished ? _buildResults() : _buildTypingView(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  //  SETUP SCREEN
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildSetupScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Typing Practice'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Container(
                width: double.infinity,
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
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(Icons.keyboard_alt_rounded, size: 48, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'Set Up Your Test',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Choose time and difficulty, then start typing!',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Difficulty Selection ─────────────────────────────────────────
              const Text(
                'Difficulty Level',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose word complexity for your practice',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(height: 14),
              Row(
                children: List.generate(3, (i) {
                  final isSelected = _selectedDifficulty == i;
                  final color = _difficultyColors[i];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDifficulty = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.15)
                              : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : Colors.white.withValues(alpha: 0.06),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(_difficultyIcons[i], color: color, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              _difficultyLabels[i],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isSelected ? color : Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              i == 0
                                  ? 'Simple words'
                                  : i == 1
                                      ? '7-letter words'
                                      : 'Complex words',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // ── Time Selection ──────────────────────────────────────────────
              const Text(
                'Duration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'How long do you want to practice?',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _timeOptions.map((t) {
                  final isSelected = _selectedTime == t;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTime = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 72,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : Colors.white.withValues(alpha: 0.06),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$t',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : Colors.grey[400],
                            ),
                          ),
                          Text(
                            'min',
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? const Color(0xFF6366F1).withValues(alpha: 0.7)
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // ── Start Button ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: _startTest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.4),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 28),
                  label: Text(
                    'Start ${_difficultyLabels[_selectedDifficulty]} • ${_selectedTime}min',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  //  TYPING VIEW
  // ══════════════════════════════════════════════════════════════════════════════

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
                const SizedBox(width: 10),
                _StatChip(
                  label: 'Accuracy',
                  value: '${_accuracy.toStringAsFixed(1)}%',
                  color: const Color(0xFF10B981),
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'Left',
                  value: _formatTime(_remainingSeconds),
                  color: _remainingSeconds < 30
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFF59E0B),
                  icon: Icons.timer_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Countdown Progress Bar ───────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _totalTimeSeconds > 0
                    ? _elapsedSeconds / _totalTimeSeconds
                    : 0,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _remainingSeconds < 30
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF6366F1),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _difficultyColors[_selectedDifficulty].withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _difficultyLabels[_selectedDifficulty],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _difficultyColors[_selectedDifficulty],
                    ),
                  ),
                ),
                Text(
                  '$_wordsTyped words',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Text Display ─────────────────────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isStarted
                        ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: SingleChildScrollView(
                  child: RichText(
                    text: TextSpan(
                      children: List.generate(
                        // Only render a window around the cursor for performance
                        min(_targetText.length, _currentPos + 300),
                        (i) {
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
                                  ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                                  : Colors.transparent,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Input Field ───────────────────────────────────────────────────
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              maxLines: 2,
              enabled: !_isFinished,
              decoration: InputDecoration(
                hintText: _isStarted
                    ? 'Keep typing...'
                    : 'Start typing to begin the countdown...',
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
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  //  RESULTS
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildResults() {
    final grade = _wpm >= 80
        ? '🏆 Excellent!'
        : _wpm >= 60
            ? '⭐ Great Job!'
            : _wpm >= 40
                ? '👍 Good Work!'
                : '💪 Keep Practicing!';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // ── Grade Badge ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.4),
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
          const SizedBox(height: 12),

          // ── Config Badge ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _difficultyColors[_selectedDifficulty].withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _difficultyLabels[_selectedDifficulty],
                  style: TextStyle(
                    color: _difficultyColors[_selectedDifficulty],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_selectedTime}min test',
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (_isSaved) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Saved ✅',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 28),

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
                  label: 'Words',
                  value: '$_wordsTyped',
                  icon: Icons.text_fields_rounded,
                  color: const Color(0xFF3B82F6),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ResultCard(
                  label: 'Time Used',
                  value: _formatTime(_elapsedSeconds),
                  icon: Icons.timer_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ResultCard(
                  label: 'Chars',
                  value: '${_correctChars + _errorChars}',
                  icon: Icons.abc_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Action Buttons ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _retryTest,
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _backToSetup,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[400],
                side: BorderSide(color: Colors.grey[700]!, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(Icons.settings_rounded, color: Colors.grey[400]),
              label: Text(
                'Change Settings',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
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
        border: Border.all(color: color.withValues(alpha: 0.25)),
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
