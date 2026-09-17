import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';

import '../../theme/app_theme.dart';
import 'pdf_viewer_screen.dart';

class CandidateDetailsScreen extends StatefulWidget {
  final String candidateId;
  const CandidateDetailsScreen({super.key, required this.candidateId});

  @override
  State<CandidateDetailsScreen> createState() => _CandidateDetailsScreenState();
}

class _CandidateDetailsScreenState extends State<CandidateDetailsScreen> {
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.candidateId)
          .get();
      final d = doc.data() ?? {};
      if (mounted) setState(() {
        _data = d;
        _profile = d['profile'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Opens the resume in a native in-app PDF viewer.
  void _viewResume(String url, String candidateName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          url: url,
          title: '$candidateName\'s Resume',
        ),
      ),
    );
  }

  /// Downloads the PDF to local storage then opens it with the device viewer
  Future<void> _downloadResume(String url) async {
    setState(() => _downloading = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/resume_${widget.candidateId}.pdf';

      await Dio().download(
        url,
        path,
        options: Options(
          headers: {'Accept': 'application/pdf'},
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Downloaded! Opening…'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFilex.open(path),
            ),
          ),
        );
        await OpenFilex.open(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _showResumeOptions(String url) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Resume', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.visibility_rounded,
                      color: AppColors.accent),
                ),
                title: const Text('View Resume'),
                subtitle: const Text('Open in browser or PDF viewer'),
                onTap: () {
                  Navigator.pop(ctx);
                  _viewResume(url, widget.candidateId);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.download_rounded,
                      color: AppColors.success),
                ),
                title: const Text('Download Resume'),
                subtitle: const Text('Save PDF to device'),
                onTap: () {
                  Navigator.pop(ctx);
                  _downloadResume(url);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _data?['name']?.toString() ??
        _data?['displayName']?.toString() ?? '';
    final email = _data?['email']?.toString() ?? '';
    final profilePic = _data?['profilePic']?.toString() ?? '';
    final skills = List<String>.from(_profile?['skills'] ?? []);
    final availability = List<String>.from(_profile?['availability'] ?? []);
    final payMin = _profile?['payMin'] as int?;
    final payMax = _profile?['payMax'] as int?;
    final openToNegotiation = _profile?['openToNegotiation'] == true;
    final bio = _profile?['bio']?.toString() ?? '';
    final resumeUrl = _profile?['resumeUrl'] as String?;

    String formatPay(int v) {
      if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
      if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
      return '₹$v';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(name.isNotEmpty ? name : 'Candidate')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.pagePadding,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.accentLight,
                    backgroundImage: profilePic.isNotEmpty
                        ? CachedNetworkImageProvider(profilePic)
                        : null,
                    child: profilePic.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: AppTextStyles.displayLarge
                                .copyWith(color: AppColors.accent))
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(name, style: AppTextStyles.headlineLarge),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(email,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 24),

                  if (bio.isNotEmpty)
                    _section('About', Text(bio, style: AppTextStyles.bodyMedium)),
                  const SizedBox(height: 12),

                  _section('Skills', Wrap(
                    spacing: 6, runSpacing: 6,
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
                  )),
                  const SizedBox(height: 12),

                  _section('Availability', Wrap(
                    spacing: 6, runSpacing: 6,
                    children: availability.map((a) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: AppRadius.fullRadius,
                      ),
                      child: Text(a, style: AppTextStyles.bodySmall),
                    )).toList(),
                  )),
                  const SizedBox(height: 12),

                  _section('Expected Pay', Text(
                    openToNegotiation
                        ? 'Open to negotiation'
                        : '${formatPay(payMin ?? 0)} – ${formatPay(payMax ?? 0)} / month',
                    style: AppTextStyles.bodyMedium,
                  )),
                  const SizedBox(height: 12),

                  // ── Resume section ────────────────────────────────────────
                  _section(
                    'Resume',
                    resumeUrl != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.picture_as_pdf_rounded,
                                      size: 20, color: AppColors.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Resume uploaded',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // View button
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _viewResume(resumeUrl, name),
                                      icon: const Icon(
                                          Icons.visibility_rounded,
                                          size: 16),
                                      label: const Text('View'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Download button
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _downloading
                                          ? null
                                          : () => _downloadResume(resumeUrl),
                                      icon: _downloading
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white))
                                          : const Icon(
                                              Icons.download_rounded,
                                              size: 16),
                                      label: Text(_downloading
                                          ? 'Saving…'
                                          : 'Download'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Text('Not uploaded',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textHint)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _section(String title, Widget child) {
    return Container(
      width: double.infinity,
      decoration: AppDecorations.card,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headlineSmall),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
