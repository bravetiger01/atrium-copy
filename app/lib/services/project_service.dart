import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../screens/candidate/models/project_model.dart';

class ProjectService {
  static final ProjectService _instance = ProjectService._internal();
  factory ProjectService() => _instance;
  ProjectService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Stream of projects for the current or given candidate UID.
  Stream<List<ProjectModel>> streamCandidateProjects([String? uid]) {
    final targetUid = uid ?? currentUserId;
    if (targetUid == null || targetUid.isEmpty) {
      return Stream.value([]);
    }

    return _db
        .collection('users')
        .doc(targetUid)
        .collection('projects')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ProjectModel.fromDoc(doc)).toList());
  }

  /// Uploads media files to Firebase Storage bucket under
  /// `users/{uid}/projects/{projectId}/{timestamp}_{filename}`
  /// and returns a list of public download URLs.
  Future<List<String>> uploadProjectMedia({
    required String uid,
    required String projectId,
    required List<File> files,
    void Function(double progress)? onProgress,
  }) async {
    final List<String> downloadUrls = [];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName = file.path.split(Platform.pathSeparator).last;
      final timeStamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = '${timeStamp}_$fileName';

      final ref = _storage
          .ref()
          .child('users')
          .child(uid)
          .child('projects')
          .child(projectId)
          .child(safeName);

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);

      if (onProgress != null) {
        onProgress((i + 1) / files.length);
      }
    }

    return downloadUrls;
  }

  /// Saves project document to Firestore at `users/{uid}/projects/{projectId}`
  Future<void> saveProject({
    required String uid,
    required String title,
    String? client,
    String category = 'Design',
    required String companyDescription,
    required String projectDescription,
    required List<String> mediaUrls,
  }) async {
    final docRef = _db
        .collection('users')
        .doc(uid)
        .collection('projects')
        .doc();

    final project = ProjectModel(
      id: docRef.id,
      userId: uid,
      title: title,
      client: client,
      category: category,
      companyDescription: companyDescription,
      projectDescription: projectDescription,
      mediaUrls: mediaUrls,
      thumbnailUrl: mediaUrls.isNotEmpty ? mediaUrls.first : null,
      createdAt: DateTime.now(),
    );

    await docRef.set(project.toMap());

    // Also update parent user document counter & last project summary
    await _db.collection('users').doc(uid).set({
      'projectsCount': FieldValue.increment(1),
      'lastProjectTitle': title,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Deletes a project document from Firestore
  Future<void> deleteProject({
    required String uid,
    required String projectId,
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('projects')
        .doc(projectId)
        .delete();

    await _db.collection('users').doc(uid).set({
      'projectsCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Updates an existing project document in Firestore at `users/{uid}/projects/{projectId}`
  Future<void> updateProject({
    required String uid,
    required String projectId,
    required String title,
    String? client,
    String category = 'Design',
    required String companyDescription,
    required String projectDescription,
    required List<String> mediaUrls,
    DateTime? createdAt,
  }) async {
    final docRef = _db
        .collection('users')
        .doc(uid)
        .collection('projects')
        .doc(projectId);

    final project = ProjectModel(
      id: projectId,
      userId: uid,
      title: title,
      client: client,
      category: category,
      companyDescription: companyDescription,
      projectDescription: projectDescription,
      mediaUrls: mediaUrls,
      thumbnailUrl: mediaUrls.isNotEmpty ? mediaUrls.first : null,
      createdAt: createdAt ?? DateTime.now(),
    );

    await docRef.set(project.toMap(), SetOptions(merge: true));

    // Also update parent user document last project summary
    await _db.collection('users').doc(uid).set({
      'lastProjectTitle': title,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
