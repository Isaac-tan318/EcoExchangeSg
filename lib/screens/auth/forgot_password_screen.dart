import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/auth/login_screen.dart';
import 'package:flutter_application_1/screens/auth/phone_number_login_screen.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/widgets/textfield.dart';
import 'package:get_it/get_it.dart';

class ForgotPasswordScreen extends StatelessWidget {
  static var routeName = "/forgot_password";

  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    var texttheme = Theme.of(context).textTheme;
    var nav = Navigator.of(context);
    var form = GlobalKey<FormState>();
    String email = '';
    FirebaseService firebaseService = GetIt.instance<FirebaseService>();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
          children: [
            SizedBox(height: 60),
            CircleAvatar(
              radius: 87.5,
              child: Image.asset('assets/images/logo.png'),
            ),
            SizedBox(height: 20),

            Text(
              "Forgot password",
              style: TextStyle(fontSize: texttheme.headlineLarge!.fontSize),
            ),

            SizedBox(height: 20),

            Form(
              key: form,
              child: Field(
                child: TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration.collapsed(
                    hintText: "Enter Email",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    final emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+");
                    if (!emailRegex.hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    email = value!;
                  },
                ),
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                try {
                  var isValid = form.currentState!.validate();
                  if (isValid) {
                    form.currentState!.save();
                    debugPrint("email: $email");
                    await firebaseService.forgotPassword(email);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Password reset email sent!")),
                    );
                  }
                } catch (error) {
                  debugPrint(error.toString());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Error resetting password, please try again",
                      ),
                    ),
                  );
                  nav.pushReplacementNamed(LoginScreen.routeName);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.tertiaryContainer,
                foregroundColor: scheme.onTertiaryContainer,
                textStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: texttheme.bodyLarge!.fontSize,
                ),
              ),
              child: Text("Submit"),
            ),

            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                nav.pushReplacementNamed(PhoneNumberLoginScreen.routeName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                padding: EdgeInsets.fromLTRB(20, 15, 20, 15),
              ),
              child: Text(
                "Login with Phone Number",
                style: TextStyle(fontSize: texttheme.bodyLarge!.fontSize),
              ),
            ),
            SizedBox(height: 40),

            TextButton(
              onPressed: () {
                nav.pushReplacementNamed(LoginScreen.routeName);
              },
              child: Text(
                "Return to login",
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
