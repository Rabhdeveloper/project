import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';

class ARFlashcardsScreen extends StatefulWidget {
  const ARFlashcardsScreen({super.key});

  @override
  State<ARFlashcardsScreen> createState() => _ARFlashcardsScreenState();
}

class _ARFlashcardsScreenState extends State<ARFlashcardsScreen> {
  final List<Map<String, dynamic>> _arCards = [
    {'title': 'Human Heart', 'subject': 'Biology', 'type': 'anatomy', 'icon': Icons.favorite, 'color': Color(0xFFEF4444)},
    {'title': 'Benzene Ring', 'subject': 'Chemistry', 'type': 'molecule', 'icon': Icons.science, 'color': Color(0xFF8B5CF6)},
    {'title': 'Pythagorean Theorem', 'subject': 'Math', 'type': 'math_graph', 'icon': Icons.functions, 'color': Color(0xFF3B82F6)},
    {'title': 'DNA Double Helix', 'subject': 'Biology', 'type': 'molecule', 'icon': Icons.biotech, 'color': Color(0xFF10B981)},
    {'title': 'Gothic Cathedral', 'subject': 'Architecture', 'type': 'architecture', 'icon': Icons.castle, 'color': Color(0xFFF59E0B)},
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
                      gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF59E0B)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.view_in_ar, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AR Flashcards', style: GoogleFonts.inter(
                        fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary,
                      )),
                      Text('3D interactive learning', style: GoogleFonts.inter(
                        fontSize: 14, color: AppTheme.textSecondary,
                      )),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // AR Cards Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85,
                  ),
                  itemCount: _arCards.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _arCards.length) {
                      // Add new card button
                      return GestureDetector(
                        onTap: () {},
                        child: GlassContainer(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline, size: 40, color: AppTheme.primary),
                                const SizedBox(height: 8),
                                Text('Create New', style: GoogleFonts.inter(
                                  color: AppTheme.primary, fontWeight: FontWeight.w600,
                                )),
                              ],
                            ),
                          ),
                        ),
                      ).animate(delay: (100 * index).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
                    }

                    final card = _arCards[index];
                    return GlassContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (card['color'] as Color).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(card['icon'], color: card['color'], size: 32),
                          ),
                          const SizedBox(height: 12),
                          Text(card['title'], style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                          )),
                          const SizedBox(height: 4),
                          Text(card['subject'], style: GoogleFonts.inter(
                            fontSize: 12, color: AppTheme.textSecondary,
                          )),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (card['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(card['type'].toString().toUpperCase(), style: GoogleFonts.inter(
                              fontSize: 10, fontWeight: FontWeight.w600, color: card['color'],
                            )),
                          ),
                        ],
                      ),
                    ).animate(delay: (100 * index).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
