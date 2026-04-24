import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _heatmap = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _trends = [];
  List<Map<String, dynamic>> _focusHours = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final results = await Future.wait([
        _apiService.client.get('/api/analytics/heatmap'),
        _apiService.client.get('/api/analytics/subjects'),
        _apiService.client.get('/api/analytics/trends'),
        _apiService.client.get('/api/analytics/focus-hours'),
      ]);
      if (mounted) {
        setState(() {
          _heatmap = List<Map<String, dynamic>>.from(results[0].data);
          _subjects = List<Map<String, dynamic>>.from(results[1].data);
          _trends = List<Map<String, dynamic>>.from(results[2].data);
          _focusHours = List<Map<String, dynamic>>.from(results[3].data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Analytics load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }

    return RefreshIndicator(
      color: const Color(0xFF6366F1),
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Study Heatmap ──────────────────────────────────────────────
            const Text('Study Heatmap',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Last 90 days', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 12),
            _buildHeatmap(),
            const SizedBox(height: 28),

            // ── Subject Breakdown ─────────────────────────────────────────
            const Text('Subject Breakdown',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildSubjectBreakdown(),
            const SizedBox(height: 28),

            // ── Focus Hours ──────────────────────────────────────────────
            const Text('Best Focus Hours',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('When you study most', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 12),
            _buildFocusHoursChart(),
            const SizedBox(height: 28),

            // ── Weekly Trends ────────────────────────────────────────────
            const Text('Weekly Trends',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Last 8 weeks', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 12),
            _buildTrendsChart(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Heatmap Grid ──────────────────────────────────────────────────────────

  Widget _buildHeatmap() {
    if (_heatmap.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: Text('No data yet', style: TextStyle(color: Colors.grey[500]))),
      );
    }

    // Find max sessions for color scaling
    int maxSessions = 1;
    for (final d in _heatmap) {
      final s = d['sessions_count'] as int? ?? 0;
      if (s > maxSessions) maxSessions = s;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        children: _heatmap.map((day) {
          final sessions = day['sessions_count'] as int? ?? 0;
          final intensity = sessions / maxSessions;
          Color cellColor;
          if (sessions == 0) {
            cellColor = const Color(0xFF0F172A);
          } else if (intensity < 0.25) {
            cellColor = const Color(0xFF10B981).withOpacity(0.25);
          } else if (intensity < 0.5) {
            cellColor = const Color(0xFF10B981).withOpacity(0.5);
          } else if (intensity < 0.75) {
            cellColor = const Color(0xFF10B981).withOpacity(0.75);
          } else {
            cellColor = const Color(0xFF10B981);
          }

          return Tooltip(
            message: '${day['date']}: $sessions session${sessions != 1 ? 's' : ''}',
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: cellColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Subject Breakdown ─────────────────────────────────────────────────────

  Widget _buildSubjectBreakdown() {
    if (_subjects.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: Text('No subject data', style: TextStyle(color: Colors.grey[500]))),
      );
    }

    final totalMinutes = _subjects.fold<int>(
        0, (sum, s) => sum + ((s['total_minutes'] as int?) ?? 0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: _subjects.map((subj) {
          final minutes = (subj['total_minutes'] as int?) ?? 0;
          final fraction = totalMinutes > 0 ? minutes / totalMinutes : 0.0;
          Color barColor = const Color(0xFF64748B);
          try {
            final hex = subj['subject_color'] as String? ?? '#64748B';
            barColor = Color(int.parse(hex.replaceFirst('#', '0xFF')));
          } catch (_) {}

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: barColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(subj['subject_name'] ?? 'Untagged',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          Text('${(minutes / 60).toStringAsFixed(1)}h',
                              style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fraction,
                          backgroundColor: barColor.withOpacity(0.1),
                          color: barColor,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Focus Hours Bar Chart ─────────────────────────────────────────────────

  Widget _buildFocusHoursChart() {
    int maxCount = 1;
    for (final h in _focusHours) {
      final c = h['session_count'] as int? ?? 0;
      if (c > maxCount) maxCount = c;
    }

    return SizedBox(
      height: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.only(right: 16, left: 8, top: 20, bottom: 8),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxCount.toDouble() * 1.2,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final hour = value.toInt();
                      // Show every 3rd hour
                      if (hour % 3 != 0) return const SizedBox.shrink();
                      return Text(
                        '${hour}h',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              barGroups: _focusHours.map((h) {
                final hour = h['hour'] as int? ?? 0;
                final count = (h['session_count'] as int? ?? 0).toDouble();
                return BarChartGroupData(
                  x: hour,
                  barRods: [
                    BarChartRodData(
                      toY: count,
                      color: const Color(0xFF8B5CF6),
                      width: 8,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ── Weekly Trends Line Chart ──────────────────────────────────────────────

  Widget _buildTrendsChart() {
    if (_trends.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: Text('Not enough data', style: TextStyle(color: Colors.grey[500]))),
      );
    }

    final spots = _trends.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['total_sessions'] as int? ?? 0).toDouble());
    }).toList();

    double maxY = 1;
    for (final s in spots) {
      if (s.y > maxY) maxY = s.y;
    }

    return SizedBox(
      height: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.only(right: 16, left: 12, top: 20, bottom: 12),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withOpacity(0.05),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= _trends.length) return const SizedBox.shrink();
                      final label = _trends[idx]['week_label'] ?? '';
                      // Show short week label
                      final parts = label.toString().split('-');
                      return Text(
                        parts.length > 1 ? parts[1] : label.toString(),
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value == value.roundToDouble() && value > 0) {
                        return Text('${value.toInt()}', style: TextStyle(fontSize: 10, color: Colors.grey[500]));
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: maxY * 1.3,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF6366F1),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
