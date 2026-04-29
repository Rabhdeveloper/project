import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';

class IoTControlScreen extends StatefulWidget {
  const IoTControlScreen({super.key});

  @override
  State<IoTControlScreen> createState() => _IoTControlScreenState();
}

class _IoTControlScreenState extends State<IoTControlScreen> {
  bool _focusProtocolActive = false;

  final List<Map<String, dynamic>> _devices = [
    {'name': 'Desk Lamp', 'type': 'light', 'brand': 'Philips Hue', 'icon': Icons.lightbulb, 'online': true, 'color': Color(0xFFF59E0B)},
    {'name': 'Room Thermostat', 'type': 'thermostat', 'brand': 'Nest', 'icon': Icons.thermostat, 'online': true, 'color': Color(0xFF3B82F6)},
    {'name': 'Study Speaker', 'type': 'speaker', 'brand': 'Sonos', 'icon': Icons.speaker, 'online': true, 'color': Color(0xFF10B981)},
    {'name': 'Smart Lock', 'type': 'lock', 'brand': 'August', 'icon': Icons.lock, 'online': false, 'color': Color(0xFF8B5CF6)},
  ];

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
                      gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.home, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Smart Home', style: GoogleFonts.inter(
                        fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary,
                      )),
                      Text('IoT & Focus Protocol', style: GoogleFonts.inter(
                        fontSize: 14, color: AppTheme.textSecondary,
                      )),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // Focus Protocol Banner
              GestureDetector(
                onTap: () => setState(() => _focusProtocolActive = !_focusProtocolActive),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: _focusProtocolActive
                        ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)])
                        : null,
                    color: _focusProtocolActive ? null : AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: _focusProtocolActive ? null : Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: _focusProtocolActive
                        ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 10))]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _focusProtocolActive ? Icons.shield : Icons.shield_outlined,
                        size: 48,
                        color: _focusProtocolActive ? Colors.white : AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _focusProtocolActive ? 'Focus Protocol Active' : 'Focus Protocol',
                        style: GoogleFonts.inter(
                          fontSize: 20, fontWeight: FontWeight.w800,
                          color: _focusProtocolActive ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _focusProtocolActive
                            ? 'Lights dimmed • Temp lowered • Phone locked • Notifications muted'
                            : 'Tap to activate — adjusts lights, temp, and blocks distractions',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _focusProtocolActive ? Colors.white.withOpacity(0.8) : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),

              // Connected Devices
              Text('Connected Devices', style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
              )),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1,
                ),
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  return GlassContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (device['color'] as Color).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(device['icon'], color: device['color'], size: 24),
                            ),
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: device['online'] ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(device['name'], style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                            )),
                            Text(device['brand'], style: GoogleFonts.inter(
                              fontSize: 12, color: AppTheme.textSecondary,
                            )),
                          ],
                        ),
                      ],
                    ),
                  ).animate(delay: (100 * index).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
