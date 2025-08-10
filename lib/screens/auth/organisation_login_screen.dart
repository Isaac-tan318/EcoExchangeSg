import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/auth/forgot_password_screen.dart';
import 'package:flutter_application_1/screens/auth/login_screen.dart';
import 'package:flutter_application_1/screens/auth/organisation_signup_screen.dart';
import 'package:flutter_application_1/screens/home_page.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/widgets/textfield_widget.dart';
import 'package:get_it/get_it.dart';

class OrganisationLoginScreen extends StatefulWidget {
  static var routeName = "/organisation_login";

  OrganisationLoginScreen({super.key});

  @override
  State<OrganisationLoginScreen> createState() =>
      _OrganisationLoginScreenState();
}

class _OrganisationLoginScreenState extends State<OrganisationLoginScreen> {
  String email = "";
  String password = "";
  var showPassword = false;
  bool _loading = false;

  FirebaseService firebaseService = GetIt.instance<FirebaseService>();

  var form = GlobalKey<FormState>();

  // function called when organisation presses login button
  // validates fields and calls firebase
  void login(context) async {
    var isValid = form.currentState!.validate();

    if (isValid) {
      form.currentState!.save();

      try {
        setState(() => _loading = true);
        await firebaseService.login(email, password, 'organiser');
        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Login successful!")));
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed, invalid email or password.")),
        );
      } finally {
        if (mounted) setState(() => _loading = false);
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
          builder:
              (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Builder(
                      builder: (context) {
                        final isLandscape =
                            MediaQuery.of(context).orientation ==
                            Orientation.landscape;

                        final logo = Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isLandscape) const SizedBox(height: 60),
                            const CircleAvatar(
                              radius: 87.5,
                              child: Icon(Icons.business, size: 80),
                            ),
                            if (!isLandscape) const SizedBox(height: 20),
                          ],
                        );

                        final title = Text(
                          "Organisation Login",
                          style: TextStyle(
                            fontSize: texttheme.headlineLarge!.fontSize,
                          ),
                        );

                        final formSection = Form(
                          key: form,
                          child: Column(
                            children: [
                              Field(
                                color: scheme.surfaceContainer,
                                child: TextFormField(
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration.collapsed(
                                    hintText: "Email",
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email is required';
                                    }
                                    final emailRegex = RegExp(
                                      r"^[^@\s]+@[^@\s]+\.[^@\s]+",
                                    );
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
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
                                      onPressed:
                                          () => setState(() {
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
                                onPressed:
                                    _loading
                                        ? null
                                        : () {
                                          if (form.currentState!.validate()) {
                                            login(context);
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: scheme.tertiaryContainer,
                                  foregroundColor: scheme.onTertiaryContainer,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child:
                                    _loading
                                        ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  scheme.onTertiaryContainer,
                                                ),
                                          ),
                                        )
                                        : Text(
                                          "Login",
                                          style: TextStyle(
                                            fontSize:
                                                texttheme.bodyLarge!.fontSize,
                                          ),
                                        ),
                              ),
                            ],
                          ),
                        );

                        final extras = Column(
                          children: [
                            const SizedBox(height: 40),
                            ElevatedButton(
                              onPressed:
                                  _loading
                                      ? null
                                      : () async {
                                        try {
                                          setState(() => _loading = true);
                                          var result = await firebaseService
                                              .signInWithGoogle('organisation');
                                          if (result.user != null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Google login successful!",
                                                ),
                                              ),
                                            );
                                            nav.pushReplacementNamed(
                                              HomeScreen.routeName,
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Google login failed: No user returned.",
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (error) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Google login failed: ${error.toString()}",
                                              ),
                                            ),
                                          );
                                        } finally {
                                          if (mounted)
                                            setState(() => _loading = false);
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
                                  Image.asset(
                                    'assets/images/google.png',
                                    width: 20,
                                    height: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text("Login with google"),
                                ],
                              ),
                            ),
                            const SizedBox(height: 25),
                            TextButton(
                              onPressed:
                                  () => nav.pushReplacementNamed(
                                    ForgotPasswordScreen.routeName,
                                  ),
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextButton(
                              onPressed:
                                  () => nav.pushReplacementNamed(
                                    OrganisationSignupScreen.routeName,
                                  ),
                              child: const Text(
                                "First time? Create new account",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),
                            ElevatedButton(
                              onPressed:
                                  () => nav.pushReplacementNamed(
                                    LoginScreen.routeName,
                                  ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: scheme.primaryContainer,
                                foregroundColor: scheme.onPrimaryContainer,
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  15,
                                  20,
                                  15,
                                ),
                              ),
                              child: const Text("User login"),
                            ),
                          ],
                        );

                        if (isLandscape) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: CircleAvatar(
                                    radius: 87.5,
                                    child: Icon(Icons.business, size: 80),
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

                        return Column(
                          children: [
                            logo,
                            title,
                            const SizedBox(height: 20),
                            formSection,
                            extras,
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
