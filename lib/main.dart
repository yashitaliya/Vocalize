import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'models/user_model.dart';
import 'services/notification_service.dart';
import 'screens/onboarding/interest_language_screen.dart';

import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hide status bar and system navigation bar globally
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize timezone for scheduled notifications
  try {
    await initializeTimezone();
  } catch (e) {
    debugPrint('Timezone initialization error: $e');
  }

  // Setup background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notification service (wrapped in try-catch for release builds)
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Notification initialization error: $e');
  }

  runApp(const VocalizeApp());
}

class VocalizeApp extends StatelessWidget {
  const VocalizeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocalize',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

/// Wrapper to check authentication state and user preferences
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isOnboardingComplete(UserModel? user) {
    if (user == null) return false;
    final hasInterests = user.interests.isNotEmpty;
    final hasLanguage = (user.selectedLanguage?.trim().isNotEmpty ?? false);
    return hasInterests && hasLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final authUser = snapshot.data!;
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _firestoreService.getUserDocStream(authUser.uid),
            builder: (context, docSnapshot) {
              if (docSnapshot.connectionState == ConnectionState.waiting ||
                  !docSnapshot.hasData) {
                return const Scaffold(
                  backgroundColor: AppColors.background,
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (docSnapshot.hasError) {
                // Keep user in onboarding when profile fetch fails, which is safer
                // than incorrectly routing to the main experience.
                return const InterestLanguageScreen();
              }

              final doc = docSnapshot.data!;
              UserModel? user;
              if (doc.exists && doc.data() != null) {
                final data = Map<String, dynamic>.from(doc.data()!);
                if ((data['uid'] as String?)?.trim().isEmpty ?? true) {
                  data['uid'] = doc.id;
                }
                user = UserModel.fromMap(data);
              }

              if (_isOnboardingComplete(user)) {
                return const MainScreen();
              }

              return const InterestLanguageScreen();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
