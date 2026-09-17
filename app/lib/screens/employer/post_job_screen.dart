import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../utils/location_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Post a Job Screen
//  Design rule: max 5 data points — Title, Type, Pay, Location, 3 Requirements
// ─────────────────────────────────────────────────────────────────────────────

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Field controllers ────────────────────────────────────────────────────────
  final _titleCtrl = TextEditingController();
  final _payMinCtrl = TextEditingController();
  final _payMaxCtrl = TextEditingController();
  final _req1Ctrl = TextEditingController();
  final _req2Ctrl = TextEditingController();
  final _req3Ctrl = TextEditingController();

  // ── Location state ───────────────────────────────────────────────────────────
  String? _selectedCity;

  // ── State ────────────────────────────────────────────────────────────────────
  String _selectedJobType = 'Full-time';
  bool _isUrgent = false;
  bool _isLoading = false;

  static const List<String> _jobTypes = [
    'Full-time',
    'Part-time',
    'Gig',
    'Internship',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _payMinCtrl.dispose();
    _payMaxCtrl.dispose();
    _req1Ctrl.dispose();
    _req2Ctrl.dispose();
    _req3Ctrl.dispose();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final payMin = int.tryParse(_payMinCtrl.text.trim()) ?? 0;
      final payMax = int.tryParse(_payMaxCtrl.text.trim()) ?? 0;

      final requirements = [
        _req1Ctrl.text.trim(),
        _req2Ctrl.text.trim(),
        _req3Ctrl.text.trim(),
      ].where((r) => r.isNotEmpty).toList();

      final cityLat = _selectedCity != null ? getCityLatitude(_selectedCity!) : null;
      final cityLng = _selectedCity != null ? getCityLongitude(_selectedCity!) : null;

      // Expiry = 30 days from now
      final expiresAt =
          DateTime.now().add(const Duration(days: 30));

      final employerSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final employerData = employerSnap.data();
      final businessName = employerData?['businessName']?.toString() ?? '';
      final employerName = employerData?['name']?.toString() ?? '';

      await FirebaseFirestore.instance.collection('jobs').add({
        'employerId': user.uid,
        'businessName': businessName,
        'employerName': employerName,
        'title': _titleCtrl.text.trim(),
        'jobType': _selectedJobType,
        'payMin': payMin,
        'payMax': payMax,
        'location': _selectedCity ?? '',
        'latitude': cityLat,
        'longitude': cityLng,
        'requirements': requirements,
        'isUrgent': _isUrgent,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully! 🎉')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post job. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post a Job'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────────
              Text(
                'Create a\nJob Card',
                style: theme.textTheme.displayMedium
                    ?.copyWith(height: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                'Keep it short — candidates see only the key info.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),

              const SizedBox(height: 32),

              // ── Section: Role Details ───────────────────────────────────────
              _SectionLabel(label: '1. Role Details'),
              const SizedBox(height: 14),

              // Job title
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Job Title *',
                  hintText: 'e.g. Cashier, Cook, Delivery Executive',
                  prefixIcon: Icon(Icons.work_outline_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Job title is required';
                  }
                  if (v.trim().length < 3) return 'Enter a valid title';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Job Type chips
              Text(
                'Job Type *',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _jobTypes.map((type) {
                  final isSelected = _selectedJobType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedJobType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.surface,
                        borderRadius: AppRadius.fullRadius,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        type,
                        style: AppTextStyles.chipLabel.copyWith(
                          color: isSelected
                              ? AppColors.textOnAccent
                              : AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              // ── Section: Pay Range ──────────────────────────────────────────
              _SectionLabel(label: '2. Pay Range (₹ / month)'),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _payMinCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Min Pay *',
                        prefixText: '₹ ',
                        hintText: '8000',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('—',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _payMaxCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Max Pay *',
                        prefixText: '₹ ',
                        hintText: '15000',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Required';
                        }
                        final min =
                            int.tryParse(_payMinCtrl.text.trim()) ?? 0;
                        final max = int.tryParse(v.trim()) ?? 0;
                        if (max < min) return '> Min';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Section: Location ───────────────────────────────────────────
              _SectionLabel(label: '3. Location'),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _selectedCity,
                decoration: const InputDecoration(
                  labelText: 'Select City *',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                items: getCityNames().map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCity = val),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please select a city';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 28),

              // ── Section: Requirements ───────────────────────────────────────
              _SectionLabel(label: '4. Key Requirements (up to 3)'),
              const SizedBox(height: 8),
              Text(
                'Keep each point short — one line max.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),

              _RequirementField(
                controller: _req1Ctrl,
                index: 1,
                hint: 'e.g. Minimum 1 year experience',
                isRequired: true,
              ),
              const SizedBox(height: 12),
              _RequirementField(
                controller: _req2Ctrl,
                index: 2,
                hint: 'e.g. Must have own vehicle',
                isRequired: false,
              ),
              const SizedBox(height: 12),
              _RequirementField(
                controller: _req3Ctrl,
                index: 3,
                hint: 'e.g. Basic English communication',
                isRequired: false,
              ),

              const SizedBox(height: 28),

              // ── Urgent toggle ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _isUrgent
                      ? AppColors.warningLight
                      : AppColors.surfaceVariant,
                  borderRadius: AppRadius.lgRadius,
                  border: Border.all(
                    color: _isUrgent
                        ? AppColors.warning.withValues(alpha: 0.5)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _isUrgent ? '🔥' : '⏰',
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mark as Urgent',
                            style:
                                theme.textTheme.titleMedium?.copyWith(
                              color: _isUrgent
                                  ? AppColors.warning
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Shows a 🔥 badge on the job card.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isUrgent,
                      onChanged: (v) => setState(() => _isUrgent = v),
                      activeColor: AppColors.warning,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Expiry notice ───────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.textHint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This job listing will auto-expire in 30 days.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textHint),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Submit button ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Post Job Card'),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: AppRadius.fullRadius,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextStyles.headlineSmall
              .copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _RequirementField extends StatelessWidget {
  final TextEditingController controller;
  final int index;
  final String hint;
  final bool isRequired;

  const _RequirementField({
    required this.controller,
    required this.index,
    required this.hint,
    required this.isRequired,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.accentLight,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$index',
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.accentDark),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: hint,
              labelText: isRequired ? 'Requirement $index *' : 'Requirement $index (optional)',
            ),
            validator: isRequired
                ? (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'At least one requirement is needed';
                    }
                    return null;
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
