// lib/screens/employer/pdf_viewer_screen.dart
//
// Downloads a PDF from a URL to a temp file then renders it
// natively using flutter_pdfview (Android PdfRenderer / iOS PDFKit).
// No browser, no WebView, no SSL issues.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

import '../../theme/app_theme.dart';

class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.url,
    this.title = 'Resume',
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  String? _error;
  double _progress = 0;

  // PDF controller state
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfController;

  @override
  void initState() {
    super.initState();
    _downloadAndLoad();
  }

  Future<void> _downloadAndLoad() async {
    try {
      final dir = await getTemporaryDirectory();
      // Use a hash of the URL as filename to cache per URL
      final filename = 'resume_${widget.url.hashCode.abs()}.pdf';
      final file = File('${dir.path}/$filename');

      // Use cached file if it exists already
      if (!await file.exists()) {
        await Dio().download(
          widget.url,
          file.path,
          onReceiveProgress: (received, total) {
            if (total > 0 && mounted) {
              setState(() => _progress = received / total);
            }
          },
          options: Options(
            receiveTimeout: const Duration(seconds: 30),
          ),
        );
      }

      if (mounted) setState(() => _localPath = file.path);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_totalPages > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Error state
    if (_error != null) {
      return Center(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Could not load PDF', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 8),
              Text(_error!, style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _progress = 0;
                    _localPath = null;
                  });
                  _downloadAndLoad();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Loading / downloading state
    if (_localPath == null) {
      return Center(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf_rounded,
                  size: 56, color: AppColors.accent),
              const SizedBox(height: 24),
              Text(
                _progress > 0
                    ? 'Loading PDF… ${(_progress * 100).toStringAsFixed(0)}%'
                    : 'Preparing PDF…',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: AppColors.border,
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // PDF rendered natively
    return PDFView(
      filePath: _localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      defaultPage: 0,
      fitPolicy: FitPolicy.BOTH,
      onRender: (pages) {
        if (mounted) setState(() => _totalPages = pages ?? 0);
      },
      onPageChanged: (page, _) {
        if (mounted) setState(() => _currentPage = page ?? 0);
      },
      onError: (error) {
        if (mounted) setState(() => _error = error.toString());
      },
      onPageError: (page, error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Page ${(page ?? 0) + 1} error: $error')),
          );
        }
      },
    );
  }
}
