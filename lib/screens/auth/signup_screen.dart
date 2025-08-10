import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/auth/login_screen.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/widgets/textfield_widget.dart';
import 'package:get_it/get_it.dart';

class SignupScreen extends StatefulWidget {
  static var routeName = "/signup";

  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final form = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  String email = '';
  String password = '';
  String username = '';
  bool isLoading = false;

  FirebaseService firebaseService = GetIt.instance<FirebaseService>();

  // function is called when user clicks signup, validates fields
  // sends signup to firebase if valid
  void signup(context) async {
    var isValid = form.currentState!.validate();
    if (isValid) {
      form.currentState!.save();
      setState(() {
        isLoading = true;
      });
      try {
        await firebaseService.register(email, password, username, 'user');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signup successful! Please log in!")),
        );
        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signup failed: " + error.toString())),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
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
                            CircleAvatar(
                              radius: 87.5,
                              child: Image.asset('assets/images/logo.png'),
                            ),
                            if (!isLandscape) const SizedBox(height: 20),
                          ],
                        );

                        final title = Text(
                          "Sign up",
                          style: TextStyle(
                            fontSize: texttheme.headlineLarge!.fontSize,
                          ),
                        );

                        final formSection = Form(
                          key: form,
                          child: Column(
                            children: [
                              Field(
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
                                      r"^[^@\s]+@[^@\s]+\.[^@\s]+$",
                                    );
                                    if (!emailRegex.hasMatch(value)) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) => email = value!,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Field(
                                child: TextFormField(
                                  keyboardType: TextInputType.text,
                                  decoration: const InputDecoration.collapsed(
                                    hintText: "Username",
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Username is required';
                                    }
                                    if (value.length < 3) {
                                      return 'Username must be at least 3 characters';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) => username = value!,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Field(
                                child: TextFormField(
                                  controller: passwordController,
                                  keyboardType: TextInputType.visiblePassword,
                                  obscureText: true,
                                  decoration: const InputDecoration.collapsed(
                                    hintText: "Password",
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 8 characters';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) => password = value!,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Field(
                                child: TextFormField(
                                  keyboardType: TextInputType.visiblePassword,
                                  obscureText: true,
                                  decoration: const InputDecoration.collapsed(
                                    hintText: "Confirm Password",
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    if (value != passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 15),
                              ElevatedButton(
                                onPressed:
                                    isLoading ? null : () => signup(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: scheme.tertiaryContainer,
                                  foregroundColor: scheme.onTertiaryContainer,
                                  textStyle: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: texttheme.bodyLarge!.fontSize,
                                  ),
                                ),
                                child:
                                    isLoading
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
                                        : const Text("Sign up"),
                              ),
                            ],
                          ),
                        );

                        final extras = Column(
                          children: [
                            const SizedBox(height: 40),
                            TextButton(
                              onPressed:
                                  () => nav.pushReplacementNamed(
                                    LoginScreen.routeName,
                                  ),
                              child: const Text(
                                "Return to Login",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                ),
                              ),
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
                                        child: Image.asset(
                                          'assets/images/logo.png',
                                        ),
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

                        // Portrait layout
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
