import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';
import '../candidate/company_profile_screen.dart';

class EmployerProfileScreen extends StatefulWidget {
  const EmployerProfileScreen({super.key});

  @override
  State<EmployerProfileScreen> createState() => _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends State<EmployerProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  final _authService = AuthService();
  final _nameCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  Map<String, dynamic>? _userData;
  String? _localPicPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _businessNameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final data = await _authService.getUserData(uid);
    if (mounted) setState(() => _userData = data);
  }

  void _startEdit() {
    _nameCtrl.text = _userData?['name']?.toString() ?? '';
    _businessNameCtrl.text = _userData?['businessName']?.toString() ?? '';
    _phoneCtrl.text = _userData?['phone']?.toString() ?? '';
    _locationCtrl.text = _userData?['location']?.toString() ?? '';
    _descriptionCtrl.text = _userData?['description']?.toString() ?? '';
    _localPicPath = null;
    setState(() => _isEditing = true);
  }

  Future<String?> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    return picked.path;
  }

  Future<String> _uploadPic(String localPath) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_pics/$uid');
    await ref.putFile(File(localPath));
    return await ref.getDownloadURL();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      String? picUrl;
      if (_localPicPath != null) {
        picUrl = await _uploadPic(_localPicPath!);
      }
      await _authService.updateProfile(
        name: _nameCtrl.text.trim(),
        profilePic: picUrl,
      );
      await _authService.updateEmployerProfile(
        businessName: _businessNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
    setState(() => _isEditing = false);
  }

  void _cancel() {
    setState(() => _isEditing = false);
  }

  int _completionPercent() {
    int filled = 0;
    if ((_userData?['name']?.toString() ?? '').isNotEmpty) filled++;
    if ((_userData?['businessName']?.toString() ?? '').isNotEmpty) filled++;
    if ((_userData?['phone']?.toString() ?? '').isNotEmpty) filled++;
    if ((_userData?['location']?.toString() ?? '').isNotEmpty) filled++;
    if ((_userData?['description']?.toString() ?? '').isNotEmpty) filled++;
    if ((_userData?['profilePic']?.toString() ?? '').isNotEmpty) filled++;
    return (filled * 100) ~/ 6;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final name = _userData?['name']?.toString() ?? user?.displayName ?? '';
    final profilePic = _userData?['profilePic']?.toString() ?? '';
    final businessName = _userData?['businessName']?.toString() ?? '';
    final phone = _userData?['phone']?.toString() ?? '';
    final location = _userData?['location']?.toString() ?? '';
    final description = _userData?['description']?.toString() ?? '';
    final uid = user?.uid ?? '';
    final completion = _completionPercent();

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isEditing ? () async {
              final path = await _pickImage();
              if (path != null) setState(() => _localPicPath = path);
            } : null,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.accentLight,
                  backgroundImage: _localPicPath != null
                      ? FileImage(File(_localPicPath!))
                      : (profilePic.isNotEmpty
                          ? CachedNetworkImageProvider(profilePic)
                          : null),
                  child: _localPicPath == null && profilePic.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'E',
                          style: AppTextStyles.displayMedium
                              .copyWith(color: AppColors.accent),
                        )
                      : null,
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name.isNotEmpty ? name : 'Your Company',
            style: theme.textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: AppRadius.fullRadius,
            ),
            child: const Text(
              '✓ Employer Account',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accentDark,
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (!_isEditing) ...[
            // Profile completion bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40, height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: completion / 100,
                          strokeWidth: 3,
                          backgroundColor: AppColors.slate200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            completion == 100
                                ? AppColors.success
                                : AppColors.accent,
                          ),
                        ),
                        Text('$completion%',
                            style: AppTextStyles.labelSmall
                                .copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      completion == 100
                          ? 'Profile complete'
                          : 'Fill in all fields to complete your profile',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: completion == 100
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Business Details',
                          style: theme.textTheme.headlineSmall),
                      TextButton.icon(
                        onPressed: _startEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (description.isNotEmpty) ...[
                    Text(description,
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.start),
                    const SizedBox(height: 16),
                    const Divider(height: 8),
                  ],
                  _DetailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Contact Person',
                    value: name.isNotEmpty ? name : '—',
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    icon: Icons.business_outlined,
                    label: 'Business Name',
                    value: businessName.isNotEmpty ? businessName : '—',
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: phone.isNotEmpty ? phone : '—',
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: location.isNotEmpty ? location : '—',
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user?.email ?? '—',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: uid.isNotEmpty
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CompanyProfileScreen(employerId: uid),
                          ),
                        )
                    : null,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Preview as Candidate'),
              ),
            ),
          ] else ...[
            // Edit mode
            Container(
              width: double.infinity,
              decoration: AppDecorations.card,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit Profile',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 24),

                  _EditSectionLabel(label: 'Personal Info'),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      hintText: '+91 98765 43210',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),

                  const SizedBox(height: 28),
                  _EditSectionLabel(label: 'Business Info'),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _businessNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Business Name *',
                      hintText: 'e.g. Anand Mart, Vadodara Services',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _locationCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'e.g. Vasad, Anand, Gujarat',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),

                  const SizedBox(height: 28),
                  _EditSectionLabel(label: 'About'),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionCtrl,
                    maxLines: 4,
                    maxLength: 300,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Company Description',
                      hintText: 'Tell candidates about your company — what you do, your values, work culture…',
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancel,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          if (!_isEditing)
            Text(
              businessName.isEmpty
                  ? 'Complete your business profile to appear verified.'
                  : 'Your business profile is visible to candidates.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textHint)),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.bodyMedium),
          ],
        ),
      ],
    );
  }
}

class _EditSectionLabel extends StatelessWidget {
  final String label;
  const _EditSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3, height: 16,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.headlineSmall),
      ],
    );
  }
}
