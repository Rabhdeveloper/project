import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import 'analytics_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _apiService = ApiService();

  // Study data
  List<Map<String, dynamic>> _weeklyData = [];
  Map<String, dynamic> _sessionStats = {};
  List<Map<String, dynamic>> _recentSessions = [];

  // Typing data
  List<Map<String, dynamic>> _typingResults = [];
  Map<String, dynamic> _typingBest = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.client.get('/api/sessions/weekly'),
        _apiService.client.get('/api/sessions/stats'),
        _apiService.client.get('/api/sessions'),
        _apiService.client.get('/api/typing'),
        _apiService.client.get('/api/typing/best'),
      ]);

      if (mounted) {
        setState(() {
          _weeklyData = List<Map<String, dynamic>>.from(results[0].data);
          _sessionStats = Map<String, dynamic>.from(results[1].data);
          _recentSessions = List<Map<String, dynamic>>.from(results[2].data)
              .take(10)
              .toList();
          _typingResults = List<Map<String, dynamic>>.from(results[3].data)
              .take(10)
              .toList();
          _typingBest = Map<String, dynamic>.from(results[4].data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Stats load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats 📊'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: Colors.grey[500],
          tabs: const [
            Tab(icon: Icon(Icons.timer_rounded, size: 20), text: 'Study'),
            Tab(icon: Icon(Icons.keyboard_rounded, size: 20), text: 'Typing'),
            Tab(icon: Icon(Icons.analytics_rounded, size: 20), text: 'Analytics'),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF6366F1),
        onRefresh: _loadAllData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildStudyTab(),
                  _buildTypingTab(),
                  const AnalyticsScreen(),
                ],
              ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  STUDY TAB
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildStudyTab() {
    final totalSessions = _sessionStats['total_sessions'] ?? 0;
    final totalHours = _sessionStats['total_hours'] ?? 0.0;
    final bestDayCount = _sessionStats['best_day_count'] ?? 0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stat Chips ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Sessions',
                  value: '$totalSessions',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Total Hours',
                  value: '${totalHours}h',
                  icon: Icons.timer_outlined,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Best Day',
                  value: '$bestDayCount',
                  icon: Icons.emoji_events_outlined,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Bar Chart ───────────────────────────────────────────────────
          const Text(
            'Sessions per Day',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 24, bottom: 12),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getBarMaxY(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toInt()} sessions',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value == value.roundToDouble() && value > 0) {
                              return Text(
                                '${value.toInt()}',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            final labels = _getBarLabels();
                            if (idx < 0 || idx >= labels.length) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                labels[idx],
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white.withOpacity(0.06),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _buildBarGroups(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Recent Sessions History ──────────────────────────────────────
          const Text(
            'Recent Sessions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_recentSessions.isEmpty)
            _buildEmptyState('No study sessions yet. Start a Pomodoro! 🍅')
          else
            ..._recentSessions.map((s) => _buildSessionTile(s)),
        ],
      ),
    );
  }

  double _getBarMaxY() {
    if (_weeklyData.isEmpty) return 5;
    double maxCount = 0;
    for (final d in _weeklyData) {
      final c = (d['count'] ?? 0) as int;
      if (c > maxCount) maxCount = c.toDouble();
    }
    return maxCount < 3 ? 5 : (maxCount * 1.3).ceilToDouble();
  }

  List<String> _getBarLabels() {
    if (_weeklyData.isEmpty) return [];
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

  List<BarChartGroupData> _buildBarGroups() {
    if (_weeklyData.isEmpty) {
      return List.generate(7, (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: 0,
            color: const Color(0xFF6366F1),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      ));
    }

    return _weeklyData.asMap().entries.map((entry) {
      final count = (entry.value['count'] ?? 0) as int;
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getBarMaxY(),
              color: Colors.white.withOpacity(0.04),
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildSessionTile(Map<String, dynamic> session) {
    final duration = session['duration_minutes'] ?? 25;
    final type = session['session_type'] ?? 'focus';
    final createdAt = session['created_at'] ?? '';
    String timeStr = '';
    try {
      final dt = DateTime.parse(createdAt);
      final local = dt.toLocal();
      timeStr =
          '${local.day}/${local.month} at ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      timeStr = createdAt;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: type == 'focus'
                  ? const Color(0xFF6366F1).withOpacity(0.15)
                  : const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              type == 'focus' ? Icons.psychology_rounded : Icons.coffee_rounded,
              color: type == 'focus'
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF10B981),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type == 'focus' ? 'Focus Session' : 'Break',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${duration}m',
              style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  TYPING TAB
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildTypingTab() {
    final bestWpm = _typingBest['best_wpm'] ?? 0;
    final avgWpm = _typingBest['average_wpm'] ?? 0.0;
    final avgAccuracy = _typingBest['average_accuracy'] ?? 0.0;
    final totalTests = _typingBest['total_tests'] ?? 0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stat Chips ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Best WPM',
                  value: '$bestWpm',
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Avg WPM',
                  value: '${avgWpm is double ? avgWpm.toStringAsFixed(0) : avgWpm}',
                  icon: Icons.speed_rounded,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Avg Accuracy',
                  value: '${avgAccuracy is double ? avgAccuracy.toStringAsFixed(1) : avgAccuracy}%',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Total Tests',
                  value: '$totalTests',
                  icon: Icons.keyboard_rounded,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Line Chart: WPM over time ────────────────────────────────────
          const Text(
            'WPM Progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 24, bottom: 12),
                child: _typingResults.isEmpty
                    ? const Center(
                        child: Text(
                          'Complete typing tests to see progress',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 10,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.white.withOpacity(0.06),
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
                                  final idx = value.toInt();
                                  if (idx == 0 ||
                                      idx == _typingResults.length - 1) {
                                    return SideTitleWidget(
                                      meta: meta,
                                      child: Text(
                                        '#${idx + 1}',
                                        style: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 11,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 42,
                                interval: 10,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toInt()}',
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: (_typingResults.length - 1).toDouble().clamp(1, 100),
                          minY: _getTypingMinY(),
                          maxY: _getTypingMaxY(),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _buildTypingSpots(),
                              isCurved: true,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF6366F1).withOpacity(0.15),
                                    const Color(0xFF8B5CF6).withOpacity(0.02),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Recent Typing Results ────────────────────────────────────────
          const Text(
            'Recent Tests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_typingResults.isEmpty)
            _buildEmptyState('No typing tests yet. Take a test! ⌨️')
          else
            ..._typingResults.map((r) => _buildTypingTile(r)),
        ],
      ),
    );
  }

  List<FlSpot> _buildTypingSpots() {
    // Reversed so oldest = left, newest = right
    final reversed = _typingResults.reversed.toList();
    return reversed.asMap().entries.map((entry) {
      final wpm = (entry.value['wpm'] ?? 0) as int;
      return FlSpot(entry.key.toDouble(), wpm.toDouble());
    }).toList();
  }

  double _getTypingMinY() {
    if (_typingResults.isEmpty) return 0;
    double minWpm = double.infinity;
    for (final r in _typingResults) {
      final w = (r['wpm'] ?? 0) as int;
      if (w < minWpm) minWpm = w.toDouble();
    }
    return (minWpm - 10).clamp(0, double.infinity);
  }

  double _getTypingMaxY() {
    if (_typingResults.isEmpty) return 100;
    double maxWpm = 0;
    for (final r in _typingResults) {
      final w = (r['wpm'] ?? 0) as int;
      if (w > maxWpm) maxWpm = w.toDouble();
    }
    return maxWpm + 10;
  }

  Widget _buildTypingTile(Map<String, dynamic> result) {
    final wpm = result['wpm'] ?? 0;
    final accuracy = result['accuracy'] ?? 0.0;
    final duration = result['duration_seconds'] ?? 0;
    final createdAt = result['created_at'] ?? '';
    String timeStr = '';
    try {
      final dt = DateTime.parse(createdAt);
      final local = dt.toLocal();
      timeStr =
          '${local.day}/${local.month} at ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      timeStr = createdAt;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.keyboard_rounded,
              color: Color(0xFF6366F1),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$wpm WPM • ${accuracy is double ? accuracy.toStringAsFixed(1) : accuracy}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${duration}s',
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared Widgets ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.hourglass_empty_rounded,
              color: Colors.grey[600], size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card Widget ─────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
