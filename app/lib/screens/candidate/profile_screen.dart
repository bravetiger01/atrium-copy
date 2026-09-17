import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../utils/location_utils.dart';
import '../../widgets/notification_bell.dart';
import '../login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _profile;

  bool _isEditing = false;
  bool _isSaving = false;

  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  List<String> _editSkills = [];
  List<String> _editAvailability = [];
  RangeValues _editPayRange = const RangeValues(8000, 20000);
  bool _editNegotiation = false;
  double _editRadius = 15;
  String? _editCity;
  double? _editLatitude;
  double? _editLongitude;
  String? _localPicPath;
  String? _resumeUrl;
  bool _uploadingResume = false;

  static const List<String> _allSkills = [
    'Cashier', 'Cook', 'Helper', 'Delivery', 'Driver',
    'Security', 'Sales', 'Packing', 'Cleaning', 'Customer Service',
    'Receptionist', 'Electrician', 'Plumber', 'Carpenter', 'Painter',
    'Mechanic', 'Tailor', 'Barber', 'Beautician', 'Nurse',
    'Data Entry', 'Accounting', 'Teacher', 'Tutor', 'Watchman',
  ];

  static const List<String> _availabilityOptions = [
    'Full-time', 'Part-time', 'Gig / Freelance', 'Internship',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final data = await _authService.getUserData(uid);
    if (mounted) {
      setState(() {
        _userData = data;
        _profile = data?['profile'] as Map<String, dynamic>?;
      });
    }
  }

  void _startEdit() {
    _nameCtrl.text = _userData?['name']?.toString() ?? '';
    _bioCtrl.text = _profile?['bio']?.toString() ?? '';
    _editSkills = List<String>.from(_profile?['skills'] ?? []);
    _editAvailability = List<String>.from(_profile?['availability'] ?? []);
    _editPayRange = RangeValues(
      (_profile?['payMin'] as int?)?.toDouble() ?? 8000,
      (_profile?['payMax'] as int?)?.toDouble() ?? 20000,
    );
    _editNegotiation = _profile?['openToNegotiation'] == true;
    _editRadius = (_profile?['locationRadius'] as int?)?.toDouble() ?? 15;
    _editCity = _profile?['city'] as String?;
    _editLatitude = _profile?['latitude'] as double?;
    _editLongitude = _profile?['longitude'] as double?;
    _resumeUrl = _profile?['resumeUrl'] as String?;
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

  Future<void> _pickResume() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _uploadingResume = true);
      try {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final ref = FirebaseStorage.instance.ref().child('resumes/$uid.pdf');
        await ref.putFile(File(result.files.single.path!));
        _resumeUrl = await ref.getDownloadURL();
      } catch (_) {}
      setState(() => _uploadingResume = false);
    }
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
      await _authService.updateCandidateProfile(
        skills: _editSkills,
        availability: _editAvailability,
        payMin: _editNegotiation ? null : _editPayRange.start.toInt(),
        payMax: _editNegotiation ? null : _editPayRange.end.toInt(),
        openToNegotiation: _editNegotiation,
        bio: _bioCtrl.text.trim(),
        locationRadius: _editRadius.toInt(),
        city: _editCity,
        latitude: _editLatitude,
        longitude: _editLongitude,
        resumeUrl: _resumeUrl,
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

  String _formatPay(int v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
    return '₹$v';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final name = _userData?['name']?.toString() ?? user?.displayName ?? '';
    final profilePic = _userData?['profilePic']?.toString() ?? '';
    final skills = List<String>.from(_profile?['skills'] ?? []);
    final availability = List<String>.from(_profile?['availability'] ?? []);
    final payMin = _profile?['payMin'] as int?;
    final payMax = _profile?['payMax'] as int?;
    final openToNegotiation = _profile?['openToNegotiation'] == true;
    final bio = _profile?['bio']?.toString() ?? '';
    final radius = _profile?['locationRadius'] as int?;
    final city = _profile?['city'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          const NotificationBell(),
          IconButton(
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
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          children: [
            // ── Avatar & name ─────────────────────────────────────────────
            GestureDetector(
              onTap: _isEditing ? () async {
                final path = await _pickImage();
                if (path != null) setState(() => _localPicPath = path);
              } : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.accentLight,
                    backgroundImage: _localPicPath != null
                        ? FileImage(File(_localPicPath!))
                        : (profilePic.isNotEmpty
                            ? CachedNetworkImageProvider(profilePic)
                            : null),
                    child: _localPicPath == null && profilePic.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: AppTextStyles.displayMedium.copyWith(
                              color: AppColors.accent,
                            ),
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
            const SizedBox(height: 12),
            Text(
              name.isNotEmpty ? name : 'Your Name',
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: AppRadius.smRadius,
              ),
              child: Text(
                'Candidate',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.accentDark,
                ),
              ),
            ),

            const SizedBox(height: 28),

            if (!_isEditing) ...[
              // ── Display mode ────────────────────────────────────────────
              if (bio.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecorations.card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(bio, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

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
                        Text('Profile Details',
                            style: theme.textTheme.headlineSmall),
                        TextButton.icon(
                          onPressed: _startEdit,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Skills
                    if (skills.isNotEmpty) ...[
                      Text('Skills',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.textHint)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: skills.map((s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: AppRadius.fullRadius,
                          ),
                          child: Text(s,
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: AppColors.accentDark)),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Availability
                    if (availability.isNotEmpty) ...[
                      Text('Availability',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.textHint)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: availability.map((a) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: AppRadius.fullRadius,
                          ),
                          child: Text(a, style: AppTextStyles.bodySmall),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Pay
                    _ProfileDetailRow(
                      icon: Icons.currency_rupee_rounded,
                      label: 'Expected Pay',
                      value: openToNegotiation
                          ? 'Open to negotiation'
                          : '${_formatPay(payMin ?? 0)} – ${_formatPay(payMax ?? 0)} / month',
                    ),
                    const Divider(height: 20),

                    // Location
                    _ProfileDetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'City',
                      value: city ?? '—',
                    ),
                    const Divider(height: 20),
                    _ProfileDetailRow(
                      icon: Icons.gps_fixed_rounded,
                      label: 'GPS Location',
                      value: _profile?['latitude'] != null
                          ? 'Set ✓'
                          : 'Not set — jobs will be limited',
                      valueColor: _profile?['latitude'] != null
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const Divider(height: 20),
                    _ProfileDetailRow(
                      icon: Icons.map_rounded,
                      label: 'Search Radius',
                      value: radius != null ? '$radius km' : '—',
                    ),
                    const Divider(height: 20),
                    _ProfileDetailRow(
                      icon: Icons.description_rounded,
                      label: 'Resume',
                      value: _profile?['resumeUrl'] != null
                          ? 'Uploaded ✓'
                          : 'Not uploaded',
                      valueColor: _profile?['resumeUrl'] != null
                          ? AppColors.success
                          : AppColors.textHint,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // ── Edit mode ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: AppDecorations.card,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Profile',
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 20),

                    // Name
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bio
                    TextFormField(
                      controller: _bioCtrl,
                      maxLines: 3,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Quick intro about yourself',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Skills
                    Text('Skills',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allSkills.map((s) {
                        final sel = _editSkills.contains(s);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (sel) { _editSkills.remove(s); }
                            else { _editSkills.add(s); }
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.accent : AppColors.surface,
                              borderRadius: AppRadius.fullRadius,
                              border: Border.all(
                                color: sel ? AppColors.accent : AppColors.border,
                              ),
                            ),
                            child: Text(s,
                                style: AppTextStyles.chipLabel.copyWith(
                                  color: sel ? AppColors.textOnAccent
                                      : AppColors.textPrimary,
                                )),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Availability
                    Text('Availability',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availabilityOptions.map((a) {
                        final sel = _editAvailability.contains(a);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (sel) { _editAvailability.remove(a); }
                            else { _editAvailability.add(a); }
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.accentLight
                                  : AppColors.surface,
                              borderRadius: AppRadius.lgRadius,
                              border: Border.all(
                                color: sel ? AppColors.accent : AppColors.border,
                              ),
                            ),
                            child: Text(a,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: sel ? AppColors.accentDark
                                      : AppColors.textPrimary,
                                  fontWeight: sel ? FontWeight.w600
                                      : FontWeight.w400,
                                )),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Pay range
                    Text('Expected Pay',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    if (!_editNegotiation) ...[
                      Row(
                        children: [
                          Text('Min: ${_formatPay(_editPayRange.start.toInt())}',
                              style: AppTextStyles.bodyMedium),
                          const Spacer(),
                          Text('Max: ${_formatPay(_editPayRange.end.toInt())}',
                              style: AppTextStyles.bodyMedium),
                        ],
                      ),
                      RangeSlider(
                        values: _editPayRange,
                        min: 4000,
                        max: 100000,
                        divisions: 48,
                        activeColor: AppColors.accent,
                        inactiveColor: AppColors.slate200,
                        onChanged: (v) => setState(() => _editPayRange = v),
                      ),
                    ],
                    Row(
                      children: [
                        const Icon(Icons.handshake_outlined,
                            size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        const Text('Open to Negotiation'),
                        const Spacer(),
                        Switch(
                          value: _editNegotiation,
                          onChanged: (v) => setState(() => _editNegotiation = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // City
                    Text('Your City',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _editCity,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_city_rounded),
                        labelText: 'Select your city',
                      ),
                      items: getCityNames().map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) => setState(() {
                        _editCity = val;
                        _editLatitude = getCityLatitude(val!);
                        _editLongitude = getCityLongitude(val);
                      }),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final pos = await Geolocator.getCurrentPosition();
                            setState(() {
                              _editLatitude = pos.latitude;
                              _editLongitude = pos.longitude;
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Location updated via GPS')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('GPS failed: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.gps_fixed_rounded, size: 18),
                        label: const Text('Update from GPS'),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Radius
                    Text('Search Radius: ${_editRadius.toInt()} km',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Slider(
                      value: _editRadius,
                      min: 5,
                      max: 50,
                      divisions: 9,
                      activeColor: AppColors.accent,
                      inactiveColor: AppColors.slate200,
                      onChanged: (v) => setState(() => _editRadius = v),
                    ),

                    // Resume
                    const SizedBox(height: 20),
                    Text('Resume',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _uploadingResume ? null : _pickResume,
                        icon: _uploadingResume
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file_rounded, size: 18),
                        label: Text(_resumeUrl != null
                            ? 'Resume uploaded ✓'
                            : 'Upload Resume (PDF)'),
                        style: _resumeUrl != null
                            ? OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.success),
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 24),

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
                                    height: 20, width: 20,
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

            const SizedBox(height: 24),

            // Logout
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
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
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
            Text(value, style: AppTextStyles.bodyMedium.copyWith(
              color: valueColor ?? AppColors.textPrimary,
            )),
          ],
        ),
      ],
    );
  }
}
