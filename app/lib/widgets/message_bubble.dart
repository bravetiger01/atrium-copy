import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../models/chat_model.dart';
import '../services/file_download.dart';
import '../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isEdited;
  final VoidCallback? onLongPress;
  final VoidCallback? onAcceptInterview;
  final VoidCallback? onDeclineInterview;

  const MessageBubble({
    super.key,
    required this.message,
    this.isEdited = false,
    this.onLongPress,
    this.onAcceptInterview,
    this.onDeclineInterview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            const CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.surfaceVariant,
              child: Icon(Icons.person, size: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: message.isMe ? AppColors.accent : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(message.isMe ? 16 : 4),
                    bottomRight: Radius.circular(message.isMe ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildMessageContent(context),
              ),
            ),
          ),
          if (message.isMe) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.accent,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (message.type == 'interview') {
      return _buildInterviewCard(context);
    }
    if (message.fileType != null) {
      return _buildFileMessage(context);
    }
    return _buildTextMessage(context);
  }

  Widget _buildFileMessage(BuildContext context) {
    if (message.fileType == 'image') {
      return _buildImageMessage(context);
    } else {
      return _buildDocumentMessage(context);
    }
  }

  Widget _buildImageMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          child: Stack(
            children: [
              Image.network(
                message.fileUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 40, color: Colors.red),
                          SizedBox(height: 8),
                          Text('Failed to load image'),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (!message.isMe)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.download, color: Colors.white, size: 20),
                      onPressed: () => FileDownloadService.downloadFile(context, message.fileUrl!, message.fileName ?? _getFileNameFromUrl(message.fileUrl!)),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                    onPressed: () => _showImageFullscreen(context),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (message.message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              message.message,
              style: TextStyle(
                color: message.isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        _buildMessageFooter(context),
      ],
    );
  }

  Widget _buildDocumentMessage(BuildContext context) {
    final fileName = message.fileName ?? _getFileNameFromUrl(message.fileUrl!);
    final fileExtension = path.extension(fileName).toLowerCase();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getFileTypeColor(fileExtension),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileTypeIcon(fileExtension),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        color: message.isMe ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fileExtension.toUpperCase().replaceAll('.', '') + ' Document',
                      style: TextStyle(
                        color: message.isMe ? Colors.white70 : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!message.isMe)
                IconButton(
                  icon: Icon(
                    Icons.download,
                    color: message.isMe ? Colors.white : AppColors.textSecondary,
                  ),
                  onPressed: () => FileDownloadService.downloadFile(context, message.fileUrl!, message.fileName ?? _getFileNameFromUrl(message.fileUrl!)),
                ),
            ],
          ),
          if (message.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message.message,
              style: TextStyle(
                color: message.isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
          _buildMessageFooter(context),
        ],
      ),
    );
  }

  Widget _buildInterviewCard(BuildContext context) {
    final data = message.interviewData;
    if (data == null) return _buildTextMessage(context);

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = data.proposedTime.hour == 0
        ? 12
        : (data.proposedTime.hour > 12
            ? data.proposedTime.hour - 12
            : data.proposedTime.hour);
    final period = data.proposedTime.hour >= 12 ? 'PM' : 'AM';
    final formattedTime =
        '${data.proposedTime.day} ${months[data.proposedTime.month - 1]} ${data.proposedTime.year} · $hour:${data.proposedTime.minute.toString().padLeft(2, '0')} $period';

    return Container(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: message.isMe
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.accentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: message.isMe ? Colors.white : AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Interview Proposal',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: message.isMe ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: message.isMe
                  ? Colors.white.withOpacity(0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 14,
                        color: message.isMe
                            ? Colors.white70
                            : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: message.isMe
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (data.employerNote != null &&
                    data.employerNote!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    data.employerNote!,
                    style: TextStyle(
                      fontSize: 12,
                      color: message.isMe
                          ? Colors.white70
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (data.status == 'pending' && !message.isMe) ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: onAcceptInterview,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Accept',
                          style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: onDeclineInterview,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Decline',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: data.status == 'accepted'
                    ? AppColors.successLight
                    : data.status == 'declined'
                        ? AppColors.errorLight
                        : AppColors.warningLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    data.status == 'accepted'
                        ? Icons.check_circle_rounded
                        : data.status == 'declined'
                            ? Icons.cancel_rounded
                            : Icons.hourglass_empty_rounded,
                    size: 14,
                    color: data.status == 'accepted'
                        ? AppColors.success
                        : data.status == 'declined'
                            ? AppColors.error
                            : AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    data.status == 'accepted'
                        ? 'Accepted'
                        : data.status == 'declined'
                            ? 'Declined'
                            : 'Awaiting response',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: data.status == 'accepted'
                          ? AppColors.success
                          : data.status == 'declined'
                              ? AppColors.error
                              : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
          _buildMessageFooter(context),
        ],
      ),
    );
  }

  Widget _buildTextMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.message.isNotEmpty)
            SelectableText(
              message.message,
              style: TextStyle(
                color: message.isMe ? Colors.white : AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          _buildMessageFooter(context),
        ],
      ),
    );
  }

  Widget _buildMessageFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.time,
            style: TextStyle(
              color: message.isMe ? Colors.white70 : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (isEdited) ...[
            const SizedBox(width: 4),
            Text(
              '(edited)',
              style: TextStyle(
                color: message.isMe ? Colors.yellow.shade300 : Colors.orange,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (message.isMe) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.check,
              size: 16,
              color: Colors.white70,
            ),
          ],
        ],
      ),
    );
  }

  Color _getFileTypeColor(String extension) {
    switch (extension) {
      case '.pdf':
        return Colors.red;
      case '.doc':
      case '.docx':
        return Colors.blue;
      case '.txt':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _getFileTypeIcon(String extension) {
    switch (extension) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final fileName = segments.last;
        final parts = fileName.split('_');
        if (parts.length > 1) {
          return parts.sublist(1).join('_');
        }
        return fileName;
      }
      return 'Unknown File';
    } catch (e) {
      return 'Unknown File';
    }
  }

  void _showImageFullscreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (!message.isMe)
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: () => FileDownloadService.downloadFile(context, message.fileUrl!, message.fileName ?? _getFileNameFromUrl(message.fileUrl!)),
                ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                message.fileUrl!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
