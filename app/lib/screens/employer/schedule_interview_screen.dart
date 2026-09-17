import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ScheduleInterviewScreen extends StatefulWidget {
  final String chatId;
  final String candidateId;

  const ScheduleInterviewScreen({
    super.key,
    required this.chatId,
    required this.candidateId,
  });

  @override
  State<ScheduleInterviewScreen> createState() =>
      _ScheduleInterviewScreenState();
}

class _ScheduleInterviewScreenState extends State<ScheduleInterviewScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  final _noteCtrl = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _send() async {
    setState(() => _isSending = true);
    try {
      final proposedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'text': 'Interview proposed',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'interview',
        'interviewData': {
          'proposedTime': Timestamp.fromDate(proposedDateTime),
          'status': 'pending',
          if (_noteCtrl.text.trim().isNotEmpty)
            'employerNote': _noteCtrl.text.trim(),
        },
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': '📅 Interview proposed',
        'lastTime': FieldValue.serverTimestamp(),
        'unreadCount_${widget.candidateId}': FieldValue.increment(1),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatDateTime() {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    final hour = _selectedTime.hourOfPeriod == 0
        ? 12
        : _selectedTime.hourOfPeriod;
    final min = _selectedTime.minute.toString().padLeft(2, '0');
    return '${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year} · $hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Schedule Interview')),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Propose a time slot',
                style: theme.textTheme.displayMedium),
            const SizedBox(height: 8),
            Text(
              'The candidate can accept or decline your proposal.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            Container(
              width: double.infinity,
              decoration: AppDecorations.card,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _PickerRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    onTap: _pickDate,
                  ),
                  const Divider(height: 24),
                  _PickerRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: _selectedTime.format(context),
                    onTap: _pickTime,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              decoration: AppDecorations.card,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preview',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: AppRadius.lgRadius,
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 14, color: AppColors.accent),
                            const SizedBox(width: 6),
                            Text(
                              _formatDateTime(),
                              style: AppTextStyles.titleMedium
                                  .copyWith(color: AppColors.accentDark),
                            ),
                          ],
                        ),
                        if (_noteCtrl.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(_noteCtrl.text.trim(),
                              style: AppTextStyles.bodySmall),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: AppRadius.fullRadius,
                          ),
                          child: const Text('Awaiting confirmation',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _noteCtrl,
              maxLines: 2,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Add a note (optional)',
                hintText: 'e.g. Bring your ID proofs',
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _send,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                    _isSending ? 'Sending...' : 'Send Interview Proposal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textHint)),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.titleMedium),
            ],
          ),
          const Spacer(),
          const Icon(Icons.edit_rounded,
              size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
