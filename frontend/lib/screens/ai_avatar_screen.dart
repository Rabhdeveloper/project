import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';

class AIAvatarScreen extends StatefulWidget {
  const AIAvatarScreen({super.key});

  @override
  State<AIAvatarScreen> createState() => _AIAvatarScreenState();
}

class _AIAvatarScreenState extends State<AIAvatarScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'role': 'assistant', 'content': 'Hello! I\'m your AI study tutor. I\'m available across all your devices. How can I help you today?'},
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': _messageController.text.trim()});
      _messages.add({'role': 'assistant', 'content': 'Great question! Based on your recent study patterns, I\'d suggest focusing on the fundamentals first. Let me generate some practice questions for you.'});
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Tutor', style: GoogleFonts.inter(
                          fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary,
                        )),
                        Text('Omnipresent study assistant', style: GoogleFonts.inter(
                          fontSize: 14, color: AppTheme.textSecondary,
                        )),
                      ],
                    ),
                  ),
                  // Device handoff indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sync, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text('Synced', style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF10B981),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            // Messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        gradient: isUser
                            ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
                            : null,
                        color: isUser ? null : AppTheme.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 20),
                        ),
                        border: isUser ? null : Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Text(msg['content']!, style: GoogleFonts.inter(
                        fontSize: 14, color: isUser ? Colors.white : AppTheme.textPrimary, height: 1.5,
                      )),
                    ),
                  ).animate(delay: (80 * index).ms).fadeIn().slideY(begin: 0.1);
                },
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic, color: AppTheme.textSecondary),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.inter(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ask your AI tutor...',
                        hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary.withOpacity(0.5)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
