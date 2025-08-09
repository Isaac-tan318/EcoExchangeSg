import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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
import 'package:flutter_application_1/models/post.dart';
import 'package:flutter_application_1/screens/post_details_screen.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/services/notification_service.dart';
import 'package:flutter_application_1/services/connectivity_service.dart';
import 'package:flutter_application_1/widgets/offline_banner.dart';
import 'package:get_it/get_it.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  GetIt.instance.registerLazySingleton(() => FirebaseService());
  GetIt.instance.registerLazySingleton(() => NotificationService());
  GetIt.instance.registerLazySingleton(() => ConnectivityService());
  // Start mobile local notifications for new events (no-op on web)
  await GetIt.instance<NotificationService>().startListeningForNewEvents();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0x003d8259)),
        fontFamily: 'Outfit',

        textTheme: Theme.of(context).textTheme.copyWith(
          bodyMedium: TextStyle(fontWeight: FontWeight.w400),
          bodyLarge: TextStyle(fontSize: 18),
          labelLarge: TextStyle(fontSize: 18),
        ),
      ),
      builder: (context, child) {
        return Stack(
          children: [if (child != null) child, const OfflineBannerOverlay()],
        );
      },
      home: LoginScreen(),
      routes: {
        LoginScreen.routeName: (_) => LoginScreen(),
        SignupScreen.routeName: (_) => SignupScreen(),
        HomeScreen.routeName: (_) => HomeScreen(),
        CreatePost.routeName: (_) => CreatePost(),
        CreateEventScreen.routeName: (_) => const CreateEventScreen(),
        EditEventScreen.routeName: (_) => const EditEventScreen(),
        ForgotPasswordScreen.routeName: (_) => ForgotPasswordScreen(),
        OrganisationLoginScreen.routeName: (_) => OrganisationLoginScreen(),
        OrganisationSignupScreen.routeName: (_) => OrganisationSignupScreen(),
        AddNumberScreen.routeName: (_) => AddNumberScreen(),
        PhoneNumberLoginScreen.routeName: (_) => PhoneNumberLoginScreen(),
        EditInformationScreen.routeName: (_) => EditInformationScreen(),
      },
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
            builder: (_) => PostDetailsScreen(postId: args['postId'] as String),
          );
        }
        return null;
      },
    );
  }
}
