import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;

  // Daily goal
  int _dailyTarget = 4;
  bool _isSavingGoal = false;

  // Timer defaults
  int _focusDuration = 25;
  int _breakDuration = 5;

  // Reminders
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoadingReminders = false;

  static const List<int> _focusOptions = [15, 25, 30, 45, 60];
  static const List<int> _breakOptions = [5, 10, 15];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Load daily goal from backend
      final goalResponse = await _apiService.client.get('/api/goals');
      if (goalResponse.data != null) {
        _dailyTarget = goalResponse.data['daily_target'] ?? 4;
      }

      // Load timer preferences from local storage
      final prefs = await SharedPreferences.getInstance();
      _focusDuration = prefs.getInt('focus_duration') ?? 25;
      _breakDuration = prefs.getInt('break_duration') ?? 5;
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    }

    if (mounted) setState(() => _isLoading = false);

    // Load reminders
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoadingReminders = true);
    try {
      final response = await _apiService.client.get('/api/reminders');
      if (mounted) {
        setState(() {
          _reminders = List<Map<String, dynamic>>.from(response.data);
          _isLoadingReminders = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load reminders: $e');
      if (mounted) setState(() => _isLoadingReminders = false);
    }
  }

  Future<void> _toggleReminder(String id, bool enabled) async {
    try {
      await _apiService.client.put('/api/reminders/$id', data: {'enabled': enabled});
      _loadReminders();
    } catch (_) {}
  }

  Future<void> _deleteReminder(String id) async {
    try {
      await _apiService.client.delete('/api/reminders/$id');
      _loadReminders();
    } catch (_) {}
  }

  void _showAddReminderSheet() {
    final titleController = TextEditingController(text: 'Study Time!');
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    Set<String> selectedDays = {'mon', 'tue', 'wed', 'thu', 'fri'};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Reminder',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setSheetState(() => selectedTime = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF6366F1)),
                      const SizedBox(width: 12),
                      Text(
                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                children: ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'].map((day) {
                  final selected = selectedDays.contains(day);
                  return ChoiceChip(
                    label: Text(day.substring(0, 1).toUpperCase() + day.substring(1)),
                    selected: selected,
                    selectedColor: const Color(0xFF6366F1).withOpacity(0.3),
                    backgroundColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(
                      color: selected ? const Color(0xFF6366F1) : Colors.grey[400],
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setSheetState(() {
                        if (selected) {
                          selectedDays.remove(day);
                        } else {
                          selectedDays.add(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty || selectedDays.isEmpty) return;
                    try {
                      await _apiService.client.post('/api/reminders', data: {
                        'title': titleController.text.trim(),
                        'time': '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        'days': selectedDays.toList(),
                      });
                      Navigator.of(ctx).pop();
                      _loadReminders();
                    } catch (e) {
                      debugPrint('Failed to create reminder: $e');
                    }
                  },
                  child: const Text('Save Reminder',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveDailyGoal(int value) async {
    setState(() {
      _dailyTarget = value;
      _isSavingGoal = true;
    });

    try {
      await _apiService.client.put(
        '/api/goals',
        data: {'daily_target': value},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Daily goal set to $value sessions ✅'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to save goal: $e');
    }

    if (mounted) setState(() => _isSavingGoal = false);
  }

  Future<void> _saveTimerPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('focus_duration', _focusDuration);
    await prefs.setInt('break_duration', _breakDuration);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timer defaults saved ✅'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token'); // preserve login
    await prefs.clear();
    if (token != null) {
      await prefs.setString('jwt_token', token);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared ✅'),
          backgroundColor: Color(0xFF6366F1),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ Settings')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Daily Goal Section ────────────────────────────────
                  _SectionHeader(
                    title: 'Daily Study Goal',
                    icon: Icons.flag_rounded,
                    color: const Color(0xFF6366F1),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Target Sessions',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[300],
                              ),
                            ),
                            if (_isSavingGoal)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF6366F1),
                                ),
                              )
                            else
                              Text(
                                '$_dailyTarget sessions',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF6366F1),
                            inactiveTrackColor:
                                const Color(0xFF6366F1).withOpacity(0.15),
                            thumbColor: const Color(0xFF6366F1),
                            overlayColor:
                                const Color(0xFF6366F1).withOpacity(0.1),
                            trackHeight: 6,
                          ),
                          child: Slider(
                            value: _dailyTarget.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: '$_dailyTarget',
                            onChanged: (val) {
                              setState(() => _dailyTarget = val.toInt());
                            },
                            onChangeEnd: (val) {
                              _saveDailyGoal(val.toInt());
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('1',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12)),
                            Text('10',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Timer Defaults Section ────────────────────────────
                  _SectionHeader(
                    title: 'Timer Defaults',
                    icon: Icons.timer_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Focus Duration',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          children: _focusOptions.map((mins) {
                            final selected = _focusDuration == mins;
                            return ChoiceChip(
                              label: Text('$mins min'),
                              selected: selected,
                              selectedColor:
                                  const Color(0xFF6366F1).withOpacity(0.3),
                              backgroundColor: const Color(0xFF0F172A),
                              labelStyle: TextStyle(
                                color: selected
                                    ? const Color(0xFF6366F1)
                                    : Colors.grey[400],
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: selected
                                    ? const Color(0xFF6366F1)
                                    : Colors.grey.withOpacity(0.2),
                              ),
                              onSelected: (_) {
                                setState(() => _focusDuration = mins);
                                _saveTimerPrefs();
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Break Duration',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          children: _breakOptions.map((mins) {
                            final selected = _breakDuration == mins;
                            return ChoiceChip(
                              label: Text('$mins min'),
                              selected: selected,
                              selectedColor:
                                  const Color(0xFF10B981).withOpacity(0.3),
                              backgroundColor: const Color(0xFF0F172A),
                              labelStyle: TextStyle(
                                color: selected
                                    ? const Color(0xFF10B981)
                                    : Colors.grey[400],
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: selected
                                    ? const Color(0xFF10B981)
                                    : Colors.grey.withOpacity(0.2),
                              ),
                              onSelected: (_) {
                                setState(() => _breakDuration = mins);
                                _saveTimerPrefs();
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Reminders Section ──────────────────────────────────
                  _SectionHeader(
                    title: 'Study Reminders',
                    icon: Icons.alarm_rounded,
                    color: const Color(0xFFEC4899),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFEC4899).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        if (_isLoadingReminders)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFFEC4899)),
                          )
                        else if (_reminders.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text('No reminders set',
                                style: TextStyle(color: Colors.grey[500])),
                          )
                        else
                          ..._reminders.map((r) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(r['title'] ?? '',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${r['time']} • ${(r['days'] as List).join(', ')}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500]),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: r['enabled'] ?? true,
                                      activeColor: const Color(0xFFEC4899),
                                      onChanged: (val) =>
                                          _toggleReminder(r['id'], val),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          color: Colors.grey[600], size: 20),
                                      onPressed: () =>
                                          _deleteReminder(r['id']),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              )),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showAddReminderSheet,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEC4899),
                              side: BorderSide(
                                  color:
                                      const Color(0xFFEC4899).withOpacity(0.3)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Reminder'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── App Info Section ───────────────────────────────────
                  _SectionHeader(
                    title: 'App Info',
                    icon: Icons.info_outline_rounded,
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        // Version
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Version',
                                style: TextStyle(color: Colors.grey[400])),
                            const Text(
                              'v4.0.0 (Level 4)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(
                            height: 28, color: Color(0xFF334155)),
                        // Clear Cache
                        InkWell(
                          onTap: _clearCache,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.cleaning_services_rounded,
                                    color: Colors.grey[400], size: 20),
                                const SizedBox(width: 12),
                                Text('Clear Cache',
                                    style:
                                        TextStyle(color: Colors.grey[300])),
                                const Spacer(),
                                Icon(Icons.chevron_right,
                                    color: Colors.grey[600]),
                              ],
                            ),
                          ),
                        ),
                        const Divider(
                            height: 28, color: Color(0xFF334155)),
                        // Logout
                        InkWell(
                          onTap: _logout,
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded,
                                    color: Color(0xFFEF4444), size: 20),
                                SizedBox(width: 12),
                                Text('Log Out',
                                    style:
                                        TextStyle(color: Color(0xFFEF4444))),
                                Spacer(),
                                Icon(Icons.chevron_right,
                                    color: Color(0xFFEF4444)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
