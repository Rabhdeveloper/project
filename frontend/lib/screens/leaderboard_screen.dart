import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  late TabController _tabController;
  List<Map<String, dynamic>> _studyLeaderboard = [];
  List<Map<String, dynamic>> _typingLeaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaderboards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboards() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.client.get('/api/leaderboard/weekly'),
        _apiService.client.get('/api/leaderboard/typing'),
      ]);

      if (mounted) {
        setState(() {
          _studyLeaderboard =
              List<Map<String, dynamic>>.from(results[0].data);
          _typingLeaderboard =
              List<Map<String, dynamic>>.from(results[1].data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Leaderboard load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏅 Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: Colors.grey[500],
          tabs: const [
            Tab(text: '📚 Study'),
            Tab(text: '⌨️ Typing'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStudyTab(),
                _buildTypingTab(),
              ],
            ),
    );
  }

  // ── Study Leaderboard Tab ───────────────────────────────────────────────

  Widget _buildStudyTab() {
    if (_studyLeaderboard.isEmpty) {
      return _buildEmptyState('No study data this week yet.\nBe the first! 🚀');
    }

    return RefreshIndicator(
      color: const Color(0xFF6366F1),
      onRefresh: _loadLeaderboards,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _studyLeaderboard.length,
        itemBuilder: (context, index) {
          final entry = _studyLeaderboard[index];
          final rank = entry['rank'] ?? index + 1;
          final isCurrentUser = entry['is_current_user'] == true;

          return _LeaderboardRow(
            rank: rank,
            username: entry['username'] ?? 'Unknown',
            stat: '${entry['sessions_count'] ?? 0} sessions',
            subStat: '${entry['total_minutes'] ?? 0} min',
            isCurrentUser: isCurrentUser,
          );
        },
      ),
    );
  }

  // ── Typing Leaderboard Tab ──────────────────────────────────────────────

  Widget _buildTypingTab() {
    if (_typingLeaderboard.isEmpty) {
      return _buildEmptyState('No typing data yet.\nTake a test to compete! ⌨️');
    }

    return RefreshIndicator(
      color: const Color(0xFF6366F1),
      onRefresh: _loadLeaderboards,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _typingLeaderboard.length,
        itemBuilder: (context, index) {
          final entry = _typingLeaderboard[index];
          final rank = entry['rank'] ?? index + 1;
          final isCurrentUser = entry['is_current_user'] == true;

          return _LeaderboardRow(
            rank: rank,
            username: entry['username'] ?? 'Unknown',
            stat: '${entry['best_wpm'] ?? 0} WPM',
            subStat: 'Best Score',
            isCurrentUser: isCurrentUser,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ─── Leaderboard Row Widget ─────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.username,
    required this.stat,
    required this.subStat,
    required this.isCurrentUser,
  });

  final int rank;
  final String username;
  final String stat;
  final String subStat;
  final bool isCurrentUser;

  Color get _rankColor {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData get _rankIcon {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.emoji_events;
      case 3:
        return Icons.emoji_events;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? const Color(0xFF6366F1).withOpacity(0.12)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFF6366F1).withOpacity(0.4)
              : rank <= 3
                  ? _rankColor.withOpacity(0.25)
                  : Colors.transparent,
          width: isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _rankColor.withOpacity(rank <= 3 ? 0.15 : 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(_rankIcon, color: _rankColor, size: 22)
                  : Text(
                      '#$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _rankColor,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color:
                            isCurrentUser ? const Color(0xFF6366F1) : Colors.white,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subStat,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          // Stat
          Text(
            stat,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: rank <= 3 ? _rankColor : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
