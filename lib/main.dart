import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/screens/auth/add_number_screen.dart';
import 'package:flutter_application_1/screens/auth/forgot_password_screen.dart';
import 'package:flutter_application_1/screens/auth/login_screen.dart';
import 'package:flutter_application_1/screens/auth/organisation_login_screen.dart';
import 'package:flutter_application_1/screens/auth/organisation_signup_screen.dart';
import 'package:flutter_application_1/screens/auth/phone_number_login_screen.dart';
import 'package:flutter_application_1/screens/auth/signup_screen.dart';
import 'package:flutter_application_1/screens/create_post_screen.dart';
import 'package:flutter_application_1/screens/edit_information_screen.dart';
import 'package:flutter_application_1/screens/edit_post_screen.dart';
import 'package:flutter_application_1/screens/home_page.dart';
import 'package:flutter_application_1/screens/create_event_screen.dart';
import 'package:flutter_application_1/screens/edit_event_screen.dart';
import 'package:flutter_application_1/models/post_model.dart';
import 'package:flutter_application_1/screens/post_details_screen.dart';
import 'package:flutter_application_1/screens/event_details_screen.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/services/notification_service.dart';
import 'package:flutter_application_1/services/connectivity_service.dart';
import 'package:flutter_application_1/widgets/offline_banner_widget.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_application_1/services/theme_service.dart';
import 'package:flutter_application_1/services/tts_service.dart';
import 'package:flutter_application_1/services/nets_service.dart';

void main() async {
  final getIt = GetIt.instance;
  getIt.allowReassignment = true;
  getIt.registerLazySingleton<NETSService>(() => NETSService());
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // keep web users signed in across sessions
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }
  getIt.registerLazySingleton<FirebaseService>(() => FirebaseService());

  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  getIt.registerLazySingleton<TtsService>(() => TtsService());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  // theme service for light/dark and seed color
  getIt.registerSingleton<ThemeService>(ThemeService());
  await getIt<ThemeService>().load();
  final notif = GetIt.instance<NotificationService>();
  // prompt for permission once per install
  await notif.promptForPermissionsIfFirstLogin();
  await notif.startListeningForNewEvents();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // root app widget
  @override
  Widget build(BuildContext context) {
    final themeService = GetIt.instance<ThemeService>();
    return AnimatedBuilder(
      animation: themeService,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'EcoExchangeSg',
          theme: themeService.lightTheme(context),
          darkTheme: themeService.darkTheme(context),
          themeMode: themeService.mode,
          builder: (context, child) {
            // apply global text scale
            final base = MediaQuery.of(context);
            final themedScale = themeService.textScale;
            return MediaQuery(
              data: base.copyWith(textScaler: TextScaler.linear(themedScale)),
              child: Stack(
                children: [
                  if (child != null) child,
                  // put offline banner on top of content
                  const OfflineBannerOverlay(alignment: Alignment.center),
                ],
              ),
            );
          },
          home: const AuthGate(),
          // static routes
          routes: {
            LoginScreen.routeName: (_) => LoginScreen(),
            SignupScreen.routeName: (_) => SignupScreen(),
            HomeScreen.routeName: (_) => HomeScreen(),
            CreatePost.routeName: (_) => CreatePost(),
            CreateEventScreen.routeName: (_) => const CreateEventScreen(),
            EditEventScreen.routeName: (_) => const EditEventScreen(),
            ForgotPasswordScreen.routeName: (_) => ForgotPasswordScreen(),
            OrganisationLoginScreen.routeName: (_) => OrganisationLoginScreen(),
            OrganisationSignupScreen.routeName:
                (_) => OrganisationSignupScreen(),
            AddNumberScreen.routeName: (_) => AddNumberScreen(),
            PhoneNumberLoginScreen.routeName: (_) => PhoneNumberLoginScreen(),
            EditInformationScreen.routeName: (_) => EditInformationScreen(),
          },
          // dynamic routes with arguments
          onGenerateRoute: (settings) {
            if (settings.name == EditPost.routeName) {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder:
                    (_) => EditPost(
                      postId: args['postId'] as String,
                      initial: args['post'] as Post,
                    ),
              );
            }
            if (settings.name == PostDetailsScreen.routeName) {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder:
                    (_) => PostDetailsScreen(postId: args['postId'] as String),
              );
            }
            if (settings.name == EventDetailsScreen.routeName) {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder:
                    (_) =>
                        EventDetailsScreen(eventId: args['eventId'] as String),
              );
            }
            return null;
          },
        );
      },
    );
  }
}

/// authgate decides the first screen based on authentication state
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return HomeScreen();
        }
        return LoginScreen();
      },
    );
  }
}
