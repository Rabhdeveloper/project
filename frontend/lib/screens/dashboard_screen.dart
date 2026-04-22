import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all 3 endpoints in parallel
      final results = await Future.wait([
        _apiService.client.get('/api/auth/me'),
        _apiService.client.get('/api/sessions/weekly'),
        _apiService.client.get('/api/sessions/stats'),
      ]);

      if (mounted) {
        setState(() {
          _username = results[0].data['username'] ?? '';
          _weeklyData = List<Map<String, dynamic>>.from(results[1].data);
          _stats = Map<String, dynamic>.from(results[2].data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
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
          // ── AI Suggestion Banner ─────────────────────────────────────────
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Smart Insight',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  totalSessions > 0
                      ? "You've completed $totalSessions sessions totaling ${totalHours}h. Keep the streak going! 🔥"
                      : "Start your first Pomodoro session and track your progress! 🚀",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
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

          // ── Quick Actions ─────────────────────────────────────────────────
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  title: 'Start Pomodoro',
                  subtitle: 'Focus timer',
                  icon: Icons.timer_rounded,
                  color: const Color(0xFFF59E0B),
                  onTap: () => widget.onNavigate?.call(1), // Navigate to Study tab
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionCard(
                  title: 'Typing Test',
                  subtitle: 'Test your speed',
                  icon: Icons.keyboard_alt_rounded,
                  color: const Color(0xFF3B82F6),
                  onTap: () => widget.onNavigate?.call(2), // Navigate to Typing tab
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
