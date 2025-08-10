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
                          "Organisation Sign up",
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
                                onPressed: () => signup(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: scheme.tertiaryContainer,
                                  foregroundColor: scheme.onTertiaryContainer,
                                  textStyle: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: texttheme.bodyLarge!.fontSize,
                                  ),
                                ),
                                child: const Text("Sign up"),
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
                                    OrganisationLoginScreen.routeName,
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
