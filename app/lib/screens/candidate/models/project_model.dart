import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String userId;
  final String title;
  final String? client;
  final String category;
  final String companyDescription;
  final String projectDescription;
  final List<String> mediaUrls;
  final String? thumbnailUrl;
  final DateTime createdAt;

  const ProjectModel({
    required this.id,
    required this.userId,
    required this.title,
    this.client,
    this.category = 'Design',
    required this.companyDescription,
    required this.projectDescription,
    required this.mediaUrls,
    this.thumbnailUrl,
    required this.createdAt,
  });

  ProjectModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? client,
    String? category,
    String? companyDescription,
    String? projectDescription,
    List<String>? mediaUrls,
    String? thumbnailUrl,
    DateTime? createdAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      client: client ?? this.client,
      category: category ?? this.category,
      companyDescription: companyDescription ?? this.companyDescription,
      projectDescription: projectDescription ?? this.projectDescription,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'client': client,
      'category': category,
      'companyDescription': companyDescription,
      'projectDescription': projectDescription,
      'mediaUrls': mediaUrls,
      'thumbnailUrl': thumbnailUrl ?? (mediaUrls.isNotEmpty ? mediaUrls.first : null),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ProjectModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final mediaList = (data['mediaUrls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    DateTime createdDate;
    if (data['createdAt'] is Timestamp) {
      createdDate = (data['createdAt'] as Timestamp).toDate();
    } else {
      createdDate = DateTime.now();
    }

    return ProjectModel(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      title: data['title']?.toString() ?? 'Untitled Project',
      client: data['client']?.toString(),
      category: data['category']?.toString() ?? 'Design',
      companyDescription: data['companyDescription']?.toString() ?? '',
      projectDescription: data['projectDescription']?.toString() ?? '',
      mediaUrls: mediaList,
      thumbnailUrl: data['thumbnailUrl']?.toString() ??
          (mediaList.isNotEmpty ? mediaList.first : null),
      createdAt: createdDate,
    );
  }
}
