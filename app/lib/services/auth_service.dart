import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'asia-south1');

  static Future<void>? _googleSignInInit;

  // ── Create account (auth only — profile written during onboarding) ──────────
  Future<User?> createAccount(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  // ── Sign up new user with a role ──────────────────────────────────────────
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String role, // 'candidate' | 'employer'
    String? businessName,
    String? phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.updateDisplayName(name);
    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'email': email,
      'name': name,
      'role': role,
      'businessName': businessName ?? '',
      'phone': phone ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred.user;
  }

  // ── Sign in existing user ─────────────────────────────────────────────────
  Future<User?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  // ── Sign in with Google ──────────────────────────────────────────────────
  /// Returns null when the user cancels the Google account picker.
  /// Creates the `users/{uid}` doc without a role so the user can pick one.
  Future<User?> signInWithGoogle() async {
    await _ensureGoogleSignIn();

    final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
        case GoogleSignInExceptionCode.uiUnavailable:
          return null;
        default:
          rethrow;
      }
    }

    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'No ID token was returned from Google.',
      );
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);

    final cred = await _auth.signInWithCredential(credential);
    final user = cred.user;
    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? googleUser.email,
        'name': user.displayName ?? googleUser.displayName ?? '',
        'profilePic': user.photoURL ?? googleUser.photoUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    return user;
  }

  /// Calls `initialize()` on the Google Sign-In singleton exactly once, as
  /// required before any other method on [GoogleSignIn] is used.
  Future<void> _ensureGoogleSignIn() =>
      _googleSignInInit ??= _googleSignIn.initialize();

  // ── OTP: generate, store in Firestore, return the code ───────────────────
  /// Generates a 4-digit OTP, stores it in `otp_codes/{uid}` with a
  /// 15-minute expiry, and returns the plain code.
  /// Caller is responsible for emailing it (e.g. via a Cloud Function).
  Future<String> generateAndStoreOtp(String uid, String email) async {
    final code = (1000 + Random.secure().nextInt(9000)).toString();
    await _db.collection('otp_codes').doc(uid).set({
      'code': code,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 15)),
      ),
    });
    return code;
  }

  // ── OTP: verify code against Firestore ───────────────────────────────────
  /// Returns true if the code matches and has not expired.
  /// Deletes the OTP document on success to prevent reuse.
  Future<bool> verifyOtp(String uid, String enteredCode) async {
    final doc = await _db.collection('otp_codes').doc(uid).get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    final stored = data['code'] as String? ?? '';
    final expiry = (data['expiresAt'] as Timestamp).toDate();

    if (DateTime.now().isAfter(expiry)) {
      await doc.reference.delete();
      return false;
    }
    if (stored != enteredCode) return false;

    await doc.reference.delete();
    return true;
  }

  // ── OTP: email the stored code via Cloud Function ────────────────────────
  /// Calls the `sendOtpEmail` Cloud Function, which reads the code from
  /// `otp_codes/{uid}` (from the signed-in user's token) and emails it to the
  /// given address.
  /// Throws a [FirebaseFunctionsException] if the email can't be sent.
  Future<void> sendOtpEmail(String email) async {
    await _functions.httpsCallable('sendOtpEmail').call({'email': email});
  }

  // ── Fetch user role from Firestore ────────────────────────────────────────
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return doc.data()?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Write role ────────────────────────────────────────────────────────────
  Future<void> setUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).set(
      {'role': role},
      SetOptions(merge: true),
    );
  }

  // ── Update employer profile ───────────────────────────────────────────────
  Future<void> updateEmployerProfile({
    String? businessName,
    String? phone,
    String? location,
    String? description,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      if (businessName != null) 'businessName': businessName,
      if (phone != null) 'phone': phone,
      if (location != null) 'location': location,
      if (description != null) 'description': description,
    });
  }

  // ── Update candidate profile ──────────────────────────────────────────────
  Future<void> updateCandidateProfile({
    List<String>? skills,
    List<String>? availability,
    int? payMin,
    int? payMax,
    bool? openToNegotiation,
    String? bio,
    int? locationRadius,
    double? latitude,
    double? longitude,
    String? city,
    String? resumeUrl,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    final profileData = <String, dynamic>{};
    if (skills != null) profileData['skills'] = skills;
    if (availability != null) profileData['availability'] = availability;
    if (payMin != null) profileData['payMin'] = payMin;
    if (payMax != null) profileData['payMax'] = payMax;
    if (openToNegotiation != null) profileData['openToNegotiation'] = openToNegotiation;
    if (bio != null) profileData['bio'] = bio;
    if (locationRadius != null) profileData['locationRadius'] = locationRadius;
    if (latitude != null) profileData['latitude'] = latitude;
    if (longitude != null) profileData['longitude'] = longitude;
    if (city != null) profileData['city'] = city;
    if (resumeUrl != null) profileData['resumeUrl'] = resumeUrl;
    await _db.collection('users').doc(uid).update({'profile': profileData});
  }

  // ── Update name & profile pic ─────────────────────────────────────────────
  Future<void> updateProfile({String? name, String? profilePic}) async {
    final user = _auth.currentUser;
    final uid = user?.uid;
    if (uid == null) return;
    if (name != null) await user!.updateDisplayName(name);
    await _db.collection('users').doc(uid).update({
      if (name != null) 'name': name,
      if (profilePic != null) 'profilePic': profilePic,
    });
  }

  // ── Fetch user data ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async => _auth.signOut();

  // ── Current user ─────────────────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;
}
