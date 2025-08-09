import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/widgets/textfield.dart';
import 'package:get_it/get_it.dart';
import 'organisation_login_screen.dart';

class OrganisationSignupScreen extends StatelessWidget {
  static var routeName = "/organisation_signup";

  const OrganisationSignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    var texttheme = Theme.of(context).textTheme;
    var nav = Navigator.of(context);

    var form = GlobalKey<FormState>();
    var passwordController = TextEditingController();
    String email = '';
    String password = '';
    String organisationName = '';
    String phoneNumber = '';

    FirebaseService firebaseService = GetIt.instance<FirebaseService>();

// function called when organisation presses signup button
// validates fields and calls firebase
    void signup(context) async {
      var isValid = form.currentState!.validate();
      if (isValid) {
        form.currentState!.save();
        try {
          await firebaseService.register(
            email,
            password,
            organisationName,
            'organiser',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Organisation signup successful! Please log in!"),
            ),
          );
          nav.pushReplacementNamed(OrganisationLoginScreen.routeName);
        } catch (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Signup failed: " + error.toString())),
          );
        }
      }
    }

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 60),
            CircleAvatar(radius: 87.5, child: Icon(Icons.business, size: 80)),
            SizedBox(height: 20),
            Text(
              "Organisation Sign up",
              style: TextStyle(fontSize: texttheme.headlineLarge!.fontSize),
            ),
            SizedBox(height: 20),
            Form(
              key: form,
              child: Column(
                children: [
                  Field(
                    child: TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration.collapsed(hintText: "Email"),
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
                  SizedBox(height: 15),
                  Field(
                    child: TextFormField(
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration.collapsed(
                        hintText: "Organisation Name",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Organisation name is required';
                        }
                        if (value.length < 3) {
                          return 'Name must be at least 3 characters';
                        }
                        return null;
                      },
                      onSaved: (value) => organisationName = value!,
                    ),
                  ),
                  SizedBox(height: 15),
                  Field(
                    child: TextFormField(
                      controller: passwordController,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      decoration: InputDecoration.collapsed(
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
                  SizedBox(height: 15),
                  Field(
                    child: TextFormField(
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      decoration: InputDecoration.collapsed(
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
                  SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () => signup(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.tertiaryContainer,
                      foregroundColor: scheme.onTertiaryContainer,
                      textStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: texttheme.bodyLarge!.fontSize,
                      ),
                    ),
                    child: Text("Sign up"),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),
            TextButton(
              onPressed: () {
                nav.pushReplacementNamed(OrganisationLoginScreen.routeName);
              },
              child: Text(
                "Return to Login",
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
