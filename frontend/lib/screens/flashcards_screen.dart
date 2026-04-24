import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  late TabController _tabController;
  List<Map<String, dynamic>> _allCards = [];
  List<Map<String, dynamic>> _reviewCards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.client.get('/api/flashcards'),
        _apiService.client.get('/api/flashcards/review'),
      ]);
      if (mounted) {
        setState(() {
          _allCards = List<Map<String, dynamic>>.from(results[0].data);
          _reviewCards = List<Map<String, dynamic>>.from(results[1].data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load flashcards: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCard(String cardId) async {
    try {
      await _apiService.client.delete('/api/flashcards/$cardId');
      _loadCards();
    } catch (_) {}
  }

  void _showCreateSheet() {
    final qController = TextEditingController();
    final aController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Flashcard',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: qController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Question',
                hintText: 'What is the question?',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: aController,
              decoration: InputDecoration(
                labelText: 'Answer',
                hintText: 'What is the answer?',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
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
                  if (qController.text.trim().isEmpty ||
                      aController.text.trim().isEmpty) return;
                  try {
                    await _apiService.client.post('/api/flashcards', data: {
                      'question': qController.text.trim(),
                      'answer': aController.text.trim(),
                    });
                    Navigator.of(ctx).pop();
                    _loadCards();
                  } catch (e) {
                    debugPrint('Failed to create flashcard: $e');
                  }
                },
                child: const Text('Create Card',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startReview() {
    if (_reviewCards.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ReviewModeScreen(
          cards: _reviewCards,
          onComplete: () => _loadCards(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🃏 Flashcards'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: Colors.grey[500],
          tabs: [
            const Tab(text: '📚 Browse'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🧠 Review'),
                  if (_reviewCards.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_reviewCards.length}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSheet,
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : TabBarView(
              controller: _tabController,
              children: [_buildBrowseTab(), _buildReviewTab()],
            ),
    );
  }

  Widget _buildBrowseTab() {
    if (_allCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style_outlined, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text('No flashcards yet.\nTap + to create one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF6366F1),
      onRefresh: _loadCards,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allCards.length,
        itemBuilder: (context, index) {
          final card = _allCards[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        card['question'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.grey[600], size: 20),
                      onPressed: () => _deleteCard(card['id']),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  card['answer'] ?? '',
                  style: TextStyle(fontSize: 13, color: Colors.grey[400], height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (card['subject_name'] != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(card['subject_name'],
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(Icons.refresh, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${card['repetitions'] ?? 0} reviews',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewTab() {
    if (_reviewCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('All caught up!\nNo cards due for review.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Text('🧠', style: TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 24),
          Text(
            '${_reviewCards.length} card${_reviewCards.length != 1 ? 's' : ''} due',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Ready to review?',
              style: TextStyle(fontSize: 15, color: Colors.grey[400])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            label: const Text('Start Review',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// ─── Review Mode Screen ─────────────────────────────────────────────────────

class _ReviewModeScreen extends StatefulWidget {
  const _ReviewModeScreen({required this.cards, required this.onComplete});

  final List<Map<String, dynamic>> cards;
  final VoidCallback onComplete;

  @override
  State<_ReviewModeScreen> createState() => _ReviewModeScreenState();
}

class _ReviewModeScreenState extends State<_ReviewModeScreen> {
  final _apiService = ApiService();
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isSubmitting = false;

  Map<String, dynamic> get _currentCard => widget.cards[_currentIndex];
  bool get _isLast => _currentIndex >= widget.cards.length - 1;

  Future<void> _submitReview(int quality) async {
    setState(() => _isSubmitting = true);
    try {
      await _apiService.client.post(
        '/api/flashcards/${_currentCard['id']}/review',
        data: {'quality': quality},
      );
    } catch (_) {}

    if (_isLast) {
      widget.onComplete();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Review session complete!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } else {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Card ${_currentIndex + 1} / ${widget.cards.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / widget.cards.length,
                backgroundColor: const Color(0xFF1E293B),
                color: const Color(0xFF6366F1),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 32),

            // Card
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showAnswer = true),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey('$_currentIndex-$_showAnswer'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _showAnswer
                            ? const Color(0xFF10B981).withOpacity(0.3)
                            : const Color(0xFF6366F1).withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_showAnswer
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF6366F1))
                              .withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showAnswer ? 'ANSWER' : 'QUESTION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: _showAnswer
                                ? const Color(0xFF10B981)
                                : const Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _showAnswer
                              ? (_currentCard['answer'] ?? '')
                              : (_currentCard['question'] ?? ''),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, height: 1.5),
                        ),
                        if (!_showAnswer) ...[
                          const SizedBox(height: 24),
                          Text('Tap to reveal answer',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Rating buttons (only when answer is shown)
            if (_showAnswer)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _RatingButton(label: 'Again', quality: 1, color: const Color(0xFFEF4444), onTap: _isSubmitting ? null : () => _submitReview(1)),
                  _RatingButton(label: 'Hard', quality: 2, color: const Color(0xFFF59E0B), onTap: _isSubmitting ? null : () => _submitReview(2)),
                  _RatingButton(label: 'Good', quality: 3, color: const Color(0xFF3B82F6), onTap: _isSubmitting ? null : () => _submitReview(3)),
                  _RatingButton(label: 'Easy', quality: 4, color: const Color(0xFF10B981), onTap: _isSubmitting ? null : () => _submitReview(4)),
                  _RatingButton(label: 'Perfect', quality: 5, color: const Color(0xFF8B5CF6), onTap: _isSubmitting ? null : () => _submitReview(5)),
                ],
              )
            else
              const SizedBox(height: 56), // spacer when buttons hidden
          ],
        ),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.quality,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int quality;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                '$quality',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: color),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}
