import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../theme/app_theme.dart';

class CompanyProfileScreen extends StatefulWidget {
  final String employerId;
  const CompanyProfileScreen({super.key, required this.employerId});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.employerId)
          .get();
      if (mounted) setState(() { _data = doc.data(); _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessName = _data?['businessName']?.toString() ?? '';
    final name = _data?['name']?.toString() ?? '';
    final profilePic = _data?['profilePic']?.toString() ?? '';
    final description = _data?['description']?.toString() ?? '';
    final location = _data?['location']?.toString() ?? '';
    final phone = _data?['phone']?.toString() ?? '';
    final email = _data?['email']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: AppSpacing.pagePadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: AppColors.slate300),
                        const SizedBox(height: 16),
                        const Text('Could not load company profile'),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        height: 180,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -50),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: AppColors.accentLight,
                            backgroundImage: profilePic.isNotEmpty
                                ? CachedNetworkImageProvider(profilePic)
                                : null,
                            child: profilePic.isEmpty
                                ? Text(
                                    businessName.isNotEmpty
                                        ? businessName[0].toUpperCase()
                                        : 'C',
                                    style: AppTextStyles.displayLarge
                                        .copyWith(color: AppColors.accent),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Text(businessName,
                                style: AppTextStyles.headlineLarge,
                                textAlign: TextAlign.center),
                            if (name.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(name,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary)),
                            ],
                            const SizedBox(height: 24),
                            if (description.isNotEmpty)
                              _SectionCard(
                                title: 'About',
                                child: Text(description,
                                    style: AppTextStyles.bodyMedium),
                              ),
                            const SizedBox(height: 12),
                            _SectionCard(
                              title: 'Contact',
                              child: Column(
                                children: [
                                  if (location.isNotEmpty)
                                    _ContactTile(
                                        icon: Icons.location_on_outlined,
                                        label: 'Location', text: location),
                                  if (phone.isNotEmpty)
                                    _ContactTile(
                                        icon: Icons.phone_outlined,
                                        label: 'Phone', text: phone),
                                  if (email.isNotEmpty)
                                    _ContactTile(
                                        icon: Icons.email_outlined,
                                        label: 'Email', text: email),
                                  if (location.isEmpty &&
                                      phone.isEmpty &&
                                      email.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Text('No contact info available',
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(color: AppColors.textHint)),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppDecorations.card,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3, height: 16,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTextStyles.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  const _ContactTile({required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.accentDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textHint)),
                const SizedBox(height: 2),
                Text(text, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
