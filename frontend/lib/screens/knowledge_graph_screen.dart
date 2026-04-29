import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';

class KnowledgeGraphScreen extends StatefulWidget {
  const KnowledgeGraphScreen({super.key});

  @override
  State<KnowledgeGraphScreen> createState() => _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends State<KnowledgeGraphScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _goalController = TextEditingController();

  final List<Map<String, dynamic>> _topics = [
    {'title': 'Machine Learning', 'category': 'cs', 'connections': 4, 'color': Color(0xFF6366F1)},
    {'title': 'Linear Algebra', 'category': 'math', 'connections': 3, 'color': Color(0xFF3B82F6)},
    {'title': 'Statistics', 'category': 'math', 'connections': 3, 'color': Color(0xFF3B82F6)},
    {'title': 'Neuroscience', 'category': 'biology', 'connections': 3, 'color': Color(0xFF10B981)},
    {'title': 'Quantum Mechanics', 'category': 'physics', 'connections': 2, 'color': Color(0xFFF59E0B)},
    {'title': 'Data Structures', 'category': 'cs', 'connections': 3, 'color': Color(0xFF6366F1)},
  ];

  final List<Map<String, dynamic>> _credentials = [
    {'title': 'Mastered Linear Algebra', 'type': 'skill_mastery', 'hours': 42.5, 'score': 94.0, 'token': 'SBT-A1B2C3D4'},
    {'title': 'Completed Data Structures', 'type': 'course_completion', 'hours': 65.0, 'score': 88.0, 'token': 'SBT-E5F6G7H8'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.hub, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Knowledge Graph', style: GoogleFonts.inter(
                        fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary,
                      )),
                      Text('Global learning network', style: GoogleFonts.inter(
                        fontSize: 14, color: AppTheme.textSecondary,
                      )),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelColor: AppTheme.textSecondary,
                labelColor: Colors.white,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerHeight: 0,
                tabs: const [
                  Tab(text: 'Explore'),
                  Tab(text: 'Courses'),
                  Tab(text: 'Credentials'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExploreTab(),
                  _buildCoursesTab(),
                  _buildCredentialsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _topics.length,
      itemBuilder: (context, index) {
        final topic = _topics[index];
        return GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: (topic['color'] as Color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(
                  topic['title'].toString().substring(0, 2).toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: topic['color']),
                )),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topic['title'], style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                    )),
                    Text('${topic['category']} • ${topic['connections']} connections', style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.textSecondary,
                    )),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
            ],
          ),
        ).animate(delay: (80 * index).ms).fadeIn().slideX(begin: 0.05);
      },
    );
  }

  Widget _buildCoursesTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Generate AI Course', style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                )),
                const SizedBox(height: 12),
                TextField(
                  controller: _goalController,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g., Learn Quantum Computing from scratch',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text('Generate Curriculum', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildCredentialsTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _credentials.length,
      itemBuilder: (context, index) {
        final cred = _credentials[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF6366F1).withOpacity(0.15), const Color(0xFF8B5CF6).withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified, color: Color(0xFF6366F1), size: 24),
                  const SizedBox(width: 10),
                  Expanded(child: Text(cred['title'], style: GoogleFonts.inter(
                    fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                  ))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _credBadge('${cred['hours']}h studied', Icons.access_time),
                  const SizedBox(width: 10),
                  _credBadge('Score: ${cred['score']}%', Icons.grade),
                ],
              ),
              const SizedBox(height: 10),
              Text('Token: ${cred['token']}', style: GoogleFonts.inter(
                fontSize: 11, color: AppTheme.textSecondary, fontFamily: 'monospace',
              )),
            ],
          ),
        ).animate(delay: (120 * index).ms).fadeIn().slideY(begin: 0.1);
      },
    );
  }

  Widget _credBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
