import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';

class VREnvironmentScreen extends StatefulWidget {
  const VREnvironmentScreen({super.key});

  @override
  State<VREnvironmentScreen> createState() => _VREnvironmentScreenState();
}

class _VREnvironmentScreenState extends State<VREnvironmentScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _environments = [
    {
      'name': 'Cyberpunk Library',
      'description': 'A neon-lit futuristic library with holographic bookshelves and ambient rain.',
      'icon': Icons.auto_stories,
      'gradient': [const Color(0xFF6366F1), const Color(0xFFEC4899)],
      'audio': 'Rain & Neon Hum',
    },
    {
      'name': 'Zen Garden',
      'description': 'A serene Japanese garden with koi ponds, bamboo, and gentle wind chimes.',
      'icon': Icons.park,
      'gradient': [const Color(0xFF10B981), const Color(0xFF34D399)],
      'audio': 'Wind Chimes & Water',
    },
    {
      'name': 'Deep Space Station',
      'description': 'A quiet orbital station overlooking Earth with the hum of life-support systems.',
      'icon': Icons.rocket_launch,
      'gradient': [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)],
      'audio': 'Binaural Beats',
    },
    {
      'name': 'Underwater Reef',
      'description': 'Study surrounded by bioluminescent coral and gentle ocean currents.',
      'icon': Icons.water,
      'gradient': [const Color(0xFF06B6D4), const Color(0xFF0EA5E9)],
      'audio': 'Ocean Ambient',
    },
    {
      'name': 'Enchanted Forest',
      'description': 'A mystical forest clearing with fireflies, ancient trees, and birdsong.',
      'icon': Icons.forest,
      'gradient': [const Color(0xFF22C55E), const Color(0xFF84CC16)],
      'audio': 'Fireplace & Birds',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
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
                      gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.vrpano, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VR Study Portals', style: GoogleFonts.inter(
                        fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary,
                      )),
                      Text('Immersive focus environments', style: GoogleFonts.inter(
                        fontSize: 14, color: AppTheme.textSecondary,
                      )),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),

              const SizedBox(height: 24),

              // Environment Cards
              Expanded(
                child: ListView.builder(
                  itemCount: _environments.length,
                  itemBuilder: (context, index) {
                    final env = _environments[index];
                    final isSelected = _selectedIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(colors: List<Color>.from(env['gradient']))
                              : null,
                          color: isSelected ? null : AppTheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: isSelected
                              ? null
                              : Border.all(color: Colors.white.withOpacity(0.08)),
                          boxShadow: isSelected
                              ? [BoxShadow(color: (env['gradient'] as List)[0].withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(env['icon'], color: isSelected ? Colors.white : AppTheme.textSecondary, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(env['name'], style: GoogleFonts.inter(
                                    fontSize: 18, fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                                  )),
                                  const SizedBox(height: 4),
                                  Text(env['description'], style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isSelected ? Colors.white.withOpacity(0.8) : AppTheme.textSecondary,
                                  ), maxLines: 2),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.headphones, size: 14,
                                        color: isSelected ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(env['audio'], style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: isSelected ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary,
                                      )),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: Colors.white, size: 24),
                          ],
                        ),
                      ),
                    ).animate(delay: (100 * index).ms).fadeIn(duration: 400.ms).slideX(begin: 0.05);
                  },
                ),
              ),

              // Launch Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Launching ${_environments[_selectedIndex]['name']}...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text('Launch VR Environment', style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
                  )),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }
}
