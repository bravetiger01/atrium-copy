import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final String name;
  final String lastMessage;
  final DateTime lastTime;
  final bool isOnline;
  final int unreadCount;
  final String otherUserId;
  final String? profilePicURL;

  ChatModel({
    required this.chatId,
    required this.name,
    required this.lastMessage,
    required this.lastTime,
    this.isOnline = false,
    this.unreadCount = 0,
    required this.otherUserId,
    this.profilePicURL,
  });
}

class MessageModel {
  final String message;
  final String time;
  final bool isMe;
  final String? fileUrl;
  final String? fileType;
  final String? fileName;
  final String type; // 'text', 'image', 'audio', 'video', 'interview'
  final InterviewData? interviewData;

  MessageModel({
    required this.message,
    required this.time,
    required this.isMe,
    this.fileUrl,
    this.fileType,
    this.fileName,
    this.type = 'text',
    this.interviewData,
  });
}

enum MessageType { text, image, audio, video }

class InterviewData {
  final DateTime proposedTime;
  final String status; // pending, accepted, declined
  final String? employerNote;

  const InterviewData({
    required this.proposedTime,
    required this.status,
    this.employerNote,
  });

  Map<String, dynamic> toMap() => {
        'proposedTime': Timestamp.fromDate(proposedTime),
        'status': status,
        if (employerNote != null) 'employerNote': employerNote,
      };

  factory InterviewData.fromMap(Map<String, dynamic> map) => InterviewData(
        proposedTime: (map['proposedTime'] as Timestamp).toDate(),
        status: map['status'] as String? ?? 'pending',
        employerNote: map['employerNote'] as String?,
      );
}

class ContactModel {
  final String name;
  final String? email;
  final String? phone;
  final bool isOnline;
  final String? avatar;

  ContactModel({
    required this.name,
    this.email,
    this.phone,
    required this.isOnline,
    this.avatar,
  });
}
