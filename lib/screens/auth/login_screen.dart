import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/auth/forgot_password_screen.dart';
import 'package:flutter_application_1/screens/auth/organisation_login_screen.dart';
import 'package:flutter_application_1/screens/auth/signup_screen.dart';
import 'package:flutter_application_1/screens/home_page.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/services/notification_service.dart';
import 'package:flutter_application_1/widgets/textfield.dart';
import 'package:get_it/get_it.dart';

class LoginScreen extends StatefulWidget {
  static var routeName = "/login";

  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String email = "";
  String password = "";
  var showPassword = false;
  bool isLoading = false;
  bool isGoogleLoading = false;

  FirebaseService firebaseService = GetIt.instance<FirebaseService>();

  var form = GlobalKey<FormState>();

  // function called when user presses login button
  // validates fields and calls firebase
  void login(context) async {
    var isValid = form.currentState!.validate();

    if (isValid) {
      form.currentState!.save();
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      try {
        await firebaseService.login(email, password, 'user');
        await GetIt.instance<NotificationService>()
            .promptForPermissionsIfFirstLogin();
        if (!mounted) return;
        // Show feedback before navigating away to avoid using a disposed context
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Login successful!")));
        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
      } catch (error) {
        String errorMessage = "Login failed, invalid email or password.";
        if (error.toString().contains(
          "Make sure you login from the correct portal",
        )) {
          errorMessage = "Make sure you login from the correct portal";
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    var texttheme = Theme.of(context).textTheme;
    var nav = Navigator.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Builder(builder: (context) {
                  final isLandscape =
                      MediaQuery.of(context).orientation == Orientation.landscape;

                  // Shared widgets
                  final logo = Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isLandscape) const SizedBox(height: 60),
                      CircleAvatar(
                        radius: 87.5,
                        child: Image.asset('assets/images/logo.png'),
                      ),
                      if (!isLandscape) const SizedBox(height: 20),
                    ],
                  );

                  final title = Text(
                    "Login",
                    style: TextStyle(fontSize: texttheme.headlineLarge!.fontSize),
                  );

                  final formSection = Form(
                    key: form,
                    child: Column(
                      children: [
                        Field(
                          color: scheme.surfaceContainer,
                          child: TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            decoration:
                                const InputDecoration.collapsed(hintText: "Email"),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email is required';
                              }
                              // Email pattern check
                              final emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+");
                              if (!emailRegex.hasMatch(value)) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                            onSaved: (value) => email = value!,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Field(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          color: scheme.surfaceContainer,
                          child: TextFormField(
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: !showPassword,
                            decoration: InputDecoration(
                              hintText: "Password",
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(() {
                                  showPassword = !showPassword;
                                }),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              return null;
                            },
                            onSaved: (value) => password = value!,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  if (form.currentState!.validate()) {
                                    login(context);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.tertiaryContainer,
                            foregroundColor: scheme.onTertiaryContainer,
                            textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      scheme.onTertiaryContainer,
                                    ),
                                  ),
                                )
                              : Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: texttheme.bodyLarge!.fontSize,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );

                  final extras = Column(
                    children: [
                      const SizedBox(height: 40),
                      // Login with google
                      ElevatedButton(
                        onPressed: isGoogleLoading
                            ? null
                            : () async {
                                if (mounted) setState(() => isGoogleLoading = true);
                                try {
                                  var result = await firebaseService.signInWithGoogle('user');
                                  if (result.user != null) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Google login successful!"),
                                        ),
                                      );
                                    }
                                    await GetIt.instance<NotificationService>()
                                        .promptForPermissionsIfFirstLogin();
                                    if (mounted) {
                                      nav.pushReplacementNamed(HomeScreen.routeName);
                                    }
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Google login failed: No user returned.",
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                } catch (error) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Google login failed: ${error.toString()}",
                                        ),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => isGoogleLoading = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: scheme.outline),
                          ),
                          foregroundColor: scheme.onSurface,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isGoogleLoading) ...[
                              Image.asset('assets/images/google.png', width: 20, height: 20),
                              const SizedBox(width: 8),
                            ],
                            if (isGoogleLoading)
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(scheme.onSurface),
                                ),
                              )
                            else
                              const Text("Login with google"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      TextButton(
                        onPressed: () => nav.pushNamed(ForgotPasswordScreen.routeName),
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(decoration: TextDecoration.underline),
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextButton(
                        onPressed: () => nav.pushReplacementNamed(SignupScreen.routeName),
                        child: const Text(
                          "First time? Create new account",
                          style: TextStyle(decoration: TextDecoration.underline),
                        ),
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        onPressed: () => nav.pushReplacementNamed(OrganisationLoginScreen.routeName),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primaryContainer,
                          foregroundColor: scheme.onPrimaryContainer,
                          padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
                        ),
                        child: const Text("Organisation login"),
                      ),
                    ],
                  );

                  if (isLandscape) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 87.5,
                                  child: Image.asset('assets/images/logo.png'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              title,
                              const SizedBox(height: 20),
                              formSection,
                              extras,
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  // Portrait (default) layout
                  return Column(
                    children: [
                      logo,
                      title,
                      const SizedBox(height: 20),
                      formSection,
                      extras,
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
