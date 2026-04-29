import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';

class BiometricsScreen extends StatefulWidget {
  const BiometricsScreen({super.key});

  @override
  State<BiometricsScreen> createState() => _BiometricsScreenState();
}

class _BiometricsScreenState extends State<BiometricsScreen> {
  bool _zenMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFEC4899)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.monitor_heart, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Biometrics', style: GoogleFonts.inter(
                          fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary,
                        )),
                        Text('Cognitive state tracking', style: GoogleFonts.inter(
                          fontSize: 14, color: AppTheme.textSecondary,
                        )),
                      ],
                    ),
                  ),
                  // Zen Mode Toggle
                  GestureDetector(
                    onTap: () => setState(() => _zenMode = !_zenMode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: _zenMode
                            ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
                            : null,
                        color: _zenMode ? null : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: _zenMode ? null : Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.spa, size: 16, color: _zenMode ? Colors.white : AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text('Zen', style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: _zenMode ? Colors.white : AppTheme.textSecondary,
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // Live Metrics Row
              Row(
                children: [
                  _buildMetricCard('Heart Rate', '72', 'bpm', Icons.favorite, const Color(0xFFEF4444)),
                  const SizedBox(width: 12),
                  _buildMetricCard('HRV', '48', 'ms', Icons.timeline, const Color(0xFF8B5CF6)),
                  const SizedBox(width: 12),
                  _buildMetricCard('Stress', '0.35', '', Icons.psychology, const Color(0xFF10B981)),
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

              const SizedBox(height: 20),

              // Cognitive Load Card
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cognitive Load', style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                        )),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('OPTIMAL', style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF10B981),
                          )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress Bars
                    _buildProgressBar('Focus Depth', 0.72, const Color(0xFF6366F1)),
                    const SizedBox(height: 12),
                    _buildProgressBar('Stress Level', 0.35, const Color(0xFFEF4444)),
                    const SizedBox(height: 12),
                    _buildProgressBar('Overall Load', 0.48, const Color(0xFFF59E0B)),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 20),

              // Burnout Risk Card
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.shield, color: Color(0xFF10B981), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Burnout Risk', style: GoogleFonts.inter(
                                fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                              )),
                              Text('Low — You\'re doing great!', style: GoogleFonts.inter(
                                fontSize: 13, color: const Color(0xFF10B981),
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '✅ Keep up the balanced study rhythm. Your biometric readings look healthy.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

              const SizedBox(height: 20),

              // Connected Devices
              Text('Connected Devices', style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
              )),
              const SizedBox(height: 12),
              _buildDeviceTile('Apple Watch', 'Heart Rate + HRV', Icons.watch, true),
              const SizedBox(height: 8),
              _buildDeviceTile('Muse Headband', 'EEG + Brainwaves', Icons.headset, false),
              const SizedBox(height: 8),
              _buildDeviceTile('Oura Ring', 'HRV + Sleep', Icons.circle_outlined, true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String unit, IconData icon, Color color) {
    return Expanded(
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(
              fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary,
            )),
            Text(unit, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
            Text('${(value * 100).toInt()}%', style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
            )),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value, minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceTile(String name, String info, IconData icon, bool connected) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: connected ? AppTheme.secondary : AppTheme.textSecondary, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                )),
                Text(info, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (connected ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(connected ? 'Connected' : 'Disconnected', style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: connected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            )),
          ),
        ],
      ),
    );
  }
}
