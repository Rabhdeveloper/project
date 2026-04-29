import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';

class SecurityDashboardScreen extends StatelessWidget {
  const SecurityDashboardScreen({super.key});

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
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF06B6D4)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.security, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Security', style: GoogleFonts.inter(
                        fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary,
                      )),
                      Text('Zero-Trust Architecture', style: GoogleFonts.inter(
                        fontSize: 14, color: AppTheme.textSecondary,
                      )),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // Security Score
              GlassContainer(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 20)],
                          ),
                          child: Center(child: Text('95', style: GoogleFonts.inter(
                            fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white,
                          ))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Trust Score', style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                    )),
                    Text('Excellent — All checks passed', style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFF10B981),
                    )),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: 20),

              // Security Checks
              _buildCheckItem('Device Posture', 'OS up to date, no jailbreak', Icons.phone_android, true),
              const SizedBox(height: 10),
              _buildCheckItem('Continuous Auth', 'Behavioral verification active', Icons.fingerprint, true),
              const SizedBox(height: 10),
              _buildCheckItem('E2EE Sessions', 'End-to-end encrypted', Icons.enhanced_encryption, true),
              const SizedBox(height: 10),
              _buildCheckItem('Post-Quantum Crypto', 'CRYSTALS-Kyber active', Icons.shield, true),
              const SizedBox(height: 10),
              _buildCheckItem('Audit Logging', 'Immutable chain active', Icons.receipt_long, true),

              const SizedBox(height: 24),

              // Recent Audit Log
              Text('Recent Audit Log', style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
              )),
              const SizedBox(height: 12),

              _buildAuditEntry('Login', 'Authentication successful', '2 min ago', Icons.login),
              const SizedBox(height: 8),
              _buildAuditEntry('Timer Start', 'Study session initiated', '5 min ago', Icons.timer),
              const SizedBox(height: 8),
              _buildAuditEntry('Note Created', 'New note saved', '12 min ago', Icons.note_add),
              const SizedBox(height: 8),
              _buildAuditEntry('Flashcard Review', 'Deck completed', '25 min ago', Icons.style),
              const SizedBox(height: 8),
              _buildAuditEntry('Device Verified', 'Posture check passed', '30 min ago', Icons.verified_user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem(String title, String subtitle, IconData icon, bool passed) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (passed ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20,
              color: passed ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                )),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Icon(passed ? Icons.check_circle : Icons.error,
            color: passed ? const Color(0xFF10B981) : const Color(0xFFEF4444), size: 22),
        ],
      ),
    );
  }

  Widget _buildAuditEntry(String action, String detail, String time, IconData icon) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                )),
                Text(detail, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Text(time, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
