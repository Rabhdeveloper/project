import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import 'leaderboard_screen.dart';
import 'notes_screen.dart';
import 'flashcards_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.onNavigate});

  /// Callback to switch tabs in MainLayout (1=Study, 2=Typing)
  final void Function(int index)? onNavigate;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();

  // Data state
  String _username = '';
  List<Map<String, dynamic>> _weeklyData = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  // Level 4: friend activity + tip
  List<Map<String, dynamic>> _friendActivity = [];
  Map<String, dynamic>? _dailyTip;

  // Goal & Streak state
  int _sessionsDoneToday = 0;
  int _dailyTarget = 4;
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all endpoints in parallel
      final results = await Future.wait([
        _apiService.client.get('/api/auth/me'),
        _apiService.client.get('/api/sessions/weekly'),
        _apiService.client.get('/api/sessions/stats'),
        _apiService.client.get('/api/goals'),
        _apiService.client.get('/api/goals/today'),
      ]);

      // Load Level 4 data in parallel (non-blocking)
      _loadFriendActivity();
      _loadDailyTip();

      if (mounted) {
        final goalData = Map<String, dynamic>.from(results[3].data);
        final todayData = Map<String, dynamic>.from(results[4].data);

        setState(() {
          _username = results[0].data['username'] ?? '';
          _weeklyData = List<Map<String, dynamic>>.from(results[1].data);
          _stats = Map<String, dynamic>.from(results[2].data);
          _currentStreak = goalData['current_streak'] ?? 0;
          _dailyTarget = todayData['daily_target'] ?? 4;
          _sessionsDoneToday = todayData['sessions_done'] ?? 0;
          _isLoading = false;
        });
      }

      // Check achievements in background
      _checkAchievements();
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFriendActivity() async {
    try {
      final response = await _apiService.client.get('/api/activity/friends');
      if (mounted) {
        setState(() {
          _friendActivity = List<Map<String, dynamic>>.from(response.data);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadDailyTip() async {
    try {
      final response = await _apiService.client.get('/api/tips/daily');
      if (mounted) {
        setState(() {
          _dailyTip = Map<String, dynamic>.from(response.data);
        });
      }
    } catch (_) {}
  }

  Future<void> _checkAchievements() async {
    try {
      final response =
          await _apiService.client.post('/api/achievements/check');
      final newlyUnlocked =
          response.data['newly_unlocked'] as List? ?? [];
      if (newlyUnlocked.isNotEmpty && mounted) {
        for (final badge in newlyUnlocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Text(badge['icon'] ?? '🏆',
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Achievement Unlocked!',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(badge['title'] ?? '',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFF59E0B),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (_) {}
  }

  // Build chart spots from weekly data
  List<FlSpot> _buildChartSpots() {
    if (_weeklyData.isEmpty) {
      return List.generate(7, (i) => FlSpot(i.toDouble(), 0));
    }
    return _weeklyData.asMap().entries.map((entry) {
      final minutes = (entry.value['total_minutes'] ?? 0) as int;
      final hours = minutes / 60.0;
      return FlSpot(entry.key.toDouble(), hours);
    }).toList();
  }

  double _getMaxY() {
    if (_weeklyData.isEmpty) return 6;
    double maxMinutes = 0;
    for (final d in _weeklyData) {
      final m = (d['total_minutes'] ?? 0) as int;
      if (m > maxMinutes) maxMinutes = m.toDouble();
    }
    final maxHours = maxMinutes / 60.0;
    return (maxHours < 1) ? 2 : (maxHours * 1.3).ceilToDouble();
  }

  List<String> _getWeekdayLabels() {
    if (_weeklyData.isEmpty) {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    }
    return _weeklyData.map((d) {
      final dateStr = d['date'] as String;
      try {
        final date = DateTime.parse(dateStr);
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[date.weekday - 1];
      } catch (_) {
        return '';
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _username.isNotEmpty ? 'Hey, $_username 👋' : 'Dashboard 👋',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF6366F1),
        onRefresh: _loadData,
        child: _isLoading ? _buildSkeleton() : _buildContent(),
      ),
    );
  }

  // ── Skeleton Loading ────────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner skeleton
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            ),
          ),
          const SizedBox(height: 24),
          // Stat chips skeleton
          Row(
            children: List.generate(3, (i) => Expanded(
              child: Container(
                height: 80,
                margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )),
          ),
          const SizedBox(height: 24),
          // Chart skeleton
          Container(
            width: double.infinity,
            height: 230,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main Content ────────────────────────────────────────────────────────────

  Widget _buildContent() {
    final totalSessions = _stats['total_sessions'] ?? 0;
    final totalHours = _stats['total_hours'] ?? 0.0;
    final bestDayCount = _stats['best_day_count'] ?? 0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Daily Goal + Streak Banner ───────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Circular progress ring
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 6,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: _dailyTarget > 0
                              ? (_sessionsDoneToday / _dailyTarget)
                                  .clamp(0.0, 1.0)
                              : 0,
                          strokeWidth: 6,
                          color: Colors.white,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '$_sessionsDoneToday/$_dailyTarget',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sessionsDoneToday >= _dailyTarget
                            ? '🎉 Daily Goal Complete!'
                            : 'Today\'s Progress',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _sessionsDoneToday >= _dailyTarget
                            ? "You've hit your goal! Keep the streak alive."
                            : '${_dailyTarget - _sessionsDoneToday} more session${(_dailyTarget - _sessionsDoneToday) != 1 ? 's' : ''} to reach your goal',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥',
                                    style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(
                                  '$_currentStreak day${_currentStreak != 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Stat Chips ────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _DashStatChip(
                  label: 'Sessions',
                  value: '$totalSessions',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashStatChip(
                  label: 'Hours',
                  value: '${totalHours}h',
                  icon: Icons.timer_outlined,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashStatChip(
                  label: 'Best Day',
                  value: '$bestDayCount',
                  icon: Icons.emoji_events_outlined,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Weekly Focus Section ─────────────────────────────────────────
          const Text(
            'Weekly Focus',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 230,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.only(
                    right: 18.0, left: 12.0, top: 24, bottom: 12),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white.withOpacity(0.08),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final labels = _getWeekdayLabels();
                            final idx = value.toInt();
                            if (idx < 0 || idx >= labels.length) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                labels[idx],
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value == value.roundToDouble() && value > 0) {
                              return Text(
                                '${value.toInt()}h',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.left,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          reservedSize: 42,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                    maxY: _getMaxY(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _buildChartSpots(),
                        isCurved: true,
                        color: const Color(0xFF10B981),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF10B981).withOpacity(0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── Leaderboard Button ──────────────────────────────────────────
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Text('🏅', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[500]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Quick Actions 2x2 Grid ────────────────────────────────────────
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  title: 'Pomodoro',
                  subtitle: 'Focus timer',
                  icon: Icons.timer_rounded,
                  color: const Color(0xFFF59E0B),
                  onTap: () => widget.onNavigate?.call(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  title: 'Typing',
                  subtitle: 'Test speed',
                  icon: Icons.keyboard_alt_rounded,
                  color: const Color(0xFF3B82F6),
                  onTap: () => widget.onNavigate?.call(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  title: 'Notes',
                  subtitle: '📝 Write',
                  icon: Icons.note_alt_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotesScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  title: 'Flashcards',
                  subtitle: '🃏 Review',
                  icon: Icons.style_rounded,
                  color: const Color(0xFFEC4899),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FlashcardsScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Daily Tip ─────────────────────────────────────────────────────
          if (_dailyTip != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(0.15),
                    const Color(0xFF6366F1).withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Text(_dailyTip!['icon'] ?? '💡', style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Smart Tip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500])),
                        const SizedBox(height: 4),
                        Text(_dailyTip!['tip'] ?? '', style: const TextStyle(fontSize: 14, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Friend Activity ────────────────────────────────────────────────
          if (_friendActivity.isNotEmpty) ...[
            const Text(
              'Friend Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Last 24 hours', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 12),
            ..._friendActivity.take(5).map((a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: Icon(Icons.person, color: Color(0xFF6366F1), size: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${a['username']} completed ${a['sessions_count']} session${(a['sessions_count'] as int) != 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text('${a['total_minutes']}m', style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

// ─── Dashboard Stat Chip ──────────────────────────────────────────────────────

class _DashStatChip extends StatelessWidget {
  const _DashStatChip({
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ─── Action Card Widget ────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
