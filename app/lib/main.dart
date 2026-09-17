import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/role_selection_screen.dart';

import 'screens/candidate/candidate_shell.dart';
import 'screens/candidate/chat_screen.dart';
import 'screens/candidate/candidate_profile_setup_screen.dart';

import 'screens/employer/employer_home_screen.dart';
import 'screens/employer/employer_profile_setup_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ── Background FCM handler (must be top-level) ────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.showNotification(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Background handler must be registered before runApp
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialise local notification channels
  await NotificationService.initialize();

  // Request FCM permission (Android 13+ and iOS)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // ── Save FCM token whenever user signs in ─────────────────────────────────
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user == null) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  });

  // ── Refresh token listener ────────────────────────────────────────────────
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'fcmTokens': FieldValue.arrayUnion([newToken]),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  });

  // ── Foreground message handler ────────────────────────────────────────────
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Don't notify for your own messages
    if (message.data['otherUserId'] ==
        FirebaseAuth.instance.currentUser?.uid) return;
    NotificationService.showNotification(message);
  });

  // ── Tap on notification while app is in background ────────────────────────
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationTap(message.data);
  });

  // ── Tap on notification when app was terminated ───────────────────────────
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationTap(initialMessage.data);
    });
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const SwipeHire());
}

/// Routes the user to the correct screen when a notification is tapped.
void _handleNotificationTap(Map<String, dynamic> data) {
  final type = data['type'] as String? ?? '';
  if (type == 'chat') {
    final chatId = data['chatId'] as String?;
    final otherUserId = data['otherUserId'] as String?;
    final otherUserName = data['otherUserName'] as String? ?? 'User';
    if (chatId != null && otherUserId != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => const ChatScreen(),
          settings: RouteSettings(arguments: {
            'chatId': chatId,
            'otherUserId': otherUserId,
            'otherUserName': otherUserName,
          }),
        ),
      );
    }
  }
  // type == 'match' → candidate lands on their matches tab
  // (the tab shell is already visible; no extra navigation needed)
}


class SwipeHire extends StatelessWidget {
  const SwipeHire({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SwipeHire',
      navigatorKey: navigatorKey,
      theme: AppTheme.light,
      // Always start from splash; AuthGate picks up from there
      home: const SplashScreen(),
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/sign-up': (_) => const SignUpScreen(),
        '/role-selection': (_) => RoleSelectionScreen(
              uid: FirebaseAuth.instance.currentUser?.uid ?? '',
            ),
        '/candidate-onboarding': (_) => CandidateProfileSetupScreen(
              uid: FirebaseAuth.instance.currentUser?.uid ?? '',
            ),
        '/candidate-home': (_) => const CandidateShell(),
        '/employer-home': (_) => const EmployerHomeScreen(),
        '/chat': (_) => const ChatScreen(),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AuthGate — used when navigating from splash to the correct screen
// ─────────────────────────────────────────────────────────────────────────────
//
//  Logic:
//    No user            → LoginScreen
//    User, no role      → RoleSelectionScreen
//    User, 'candidate'  → CandidateShell
//    User, 'employer'   → EmployerHomeScreen

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Waiting for Firebase to resolve auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // No user → go to login
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // User is signed in → check their role + onboarding status in Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = userSnap.data?.data() as Map<String, dynamic>?;
            final role = data?['role'] as String?;
            final onboardingDone = data?['onboardingDone'] == true;

            if (role == 'employer') {
              return onboardingDone
                  ? const EmployerHomeScreen()
                  : EmployerProfileSetupScreen(uid: snapshot.data!.uid);
            }

            if (role == 'candidate') {
              return onboardingDone
                  ? const CandidateShell()
                  : CandidateProfileSetupScreen(uid: snapshot.data!.uid);
            }

            // No role set yet (e.g. Google sign-in path)
            return RoleSelectionScreen(uid: snapshot.data!.uid);
          },
        );
      },
    );
  }
}
