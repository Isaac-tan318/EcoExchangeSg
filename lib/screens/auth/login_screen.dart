import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/screens/auth/forgot_password_screen.dart';
import 'package:flutter_application_1/screens/auth/organisation_login_screen.dart';
import 'package:flutter_application_1/screens/auth/signup_screen.dart';
import 'package:flutter_application_1/screens/home_page.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
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
      setState(() {
        isLoading = true;
      });

      try {
        await firebaseService.login(email, password, 'user');
        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Login successful!")));
      } catch (error) {
        String errorMessage = "Login failed, invalid email or password.";
        if (error.toString().contains(
          "Make sure you login from the correct portal",
        )) {
          errorMessage = "Make sure you login from the correct portal";
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
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
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 60),
            CircleAvatar(
              radius: 87.5,
              child: Image.asset('assets/images/logo.png'),
            ),
            SizedBox(height: 20),
            Text(
              "Login",
              style: TextStyle(fontSize: texttheme.headlineLarge!.fontSize),
            ),
            SizedBox(height: 20),

            // fields + login button
            Form(
              key: form,
              child: Column(
                children: [
                  Field(
                    color: scheme.surfaceContainer,
                    child: TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration.collapsed(hintText: "Email"),
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
                      onSaved: (value) {
                        email = value!;
                      },
                    ),
                  ),
                  SizedBox(height: 15),
                  Field(
                    padding: EdgeInsets.symmetric(horizontal: 10),
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
                          onPressed: () {
                            setState(() {
                              showPassword = !showPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        password = value!;
                      },
                    ),
                  ),

                  SizedBox(height: 15),

                  ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () {
                              if (form.currentState!.validate()) {
                                login(context);
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.tertiaryContainer,
                      foregroundColor: scheme.onTertiaryContainer,
                      textStyle: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    child:
                        isLoading
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
            ),
            SizedBox(height: 40),

            // Login with google
            ElevatedButton(
              onPressed:
                  isGoogleLoading
                      ? null
                      : () async {
                        setState(() {
                          isGoogleLoading = true;
                        });
                        try {
                          // Adds role if user is signing up with google
                          var result = await firebaseService.signInWithGoogle(
                            'user',
                          );
                          if (result.user != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Google login successful!"),
                              ),
                            );
                            nav.pushReplacementNamed(HomeScreen.routeName);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Google login failed: No user returned.",
                                ),
                              ),
                            );
                          }
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Google login failed: ${error.toString()}",
                              ),
                            ),
                          );
                        } finally {
                          setState(() {
                            isGoogleLoading = false;
                          });
                        }
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.black), // Border color
                ),
                foregroundColor: scheme.onSurface,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isGoogleLoading) ...[
                    Image.asset(
                      'assets/images/google.png',
                      width: 20,
                      height: 20,
                    ),
                    SizedBox(width: 8),
                  ],
                  if (isGoogleLoading)
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          scheme.onSurface,
                        ),
                      ),
                    )
                  else
                    Text("Login with google"),
                ],
              ),
            ),
            SizedBox(height: 25),
            TextButton(
              onPressed: () {
                nav.pushNamed(ForgotPasswordScreen.routeName);
              },
              child: Text(
                "Forgot Password?",
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
            SizedBox(height: 5),

            // Sign up link
            TextButton(
              onPressed: () {
                nav.pushReplacementNamed(SignupScreen.routeName);
              },
              child: Text(
                "First time? Create new account",
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
            SizedBox(height: 25),

            // Organisation login button
            ElevatedButton(
              onPressed: () {
                nav.pushReplacementNamed(OrganisationLoginScreen.routeName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                padding: EdgeInsets.fromLTRB(20, 15, 20, 15),
              ),
              child: Text("Organisation login"),
            ),
          ],
        ),
      ),
    );
  }
}
