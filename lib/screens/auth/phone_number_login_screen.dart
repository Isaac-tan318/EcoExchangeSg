import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/screens/home_page.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/widgets/textfield.dart';
import 'package:get_it/get_it.dart';

class PhoneNumberLoginScreen extends StatelessWidget {
  static var routeName = "/phone_number_login";

  PhoneNumberLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    var texttheme = Theme.of(context).textTheme;
    var nav = Navigator.of(context);
    var form = GlobalKey<FormState>();
    String phoneNumber = '';
    FirebaseService firebaseService = GetIt.instance<FirebaseService>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            nav.pop();
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Login with Phone Number",
                style: TextStyle(fontSize: texttheme.headlineMedium?.fontSize),
              ),
              SizedBox(height: 30),

              // User enters phone number and OTP is sent to them
              // User enters OTP into dialog to login
              Form(
                key: form,
                child: Field(
                  child: TextFormField(
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration.collapsed(
                      hintText: "Phone Number",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Phone number is required';
                      }
                      final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
                      if (!phoneRegex.hasMatch(value)) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                    onSaved: (value) => phoneNumber = value ?? '',
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (form.currentState!.validate()) {
                    form.currentState!.save();

                    // Function to Prompt user for OTP

                    Future<String> getOtpFromUser(BuildContext context) async {
                      String otp = '';
                      await showDialog(
                        context: context,
                        builder: (context) {
                          final formKey = GlobalKey<FormState>();
                          final otpController = TextEditingController();
                          return AlertDialog(
                            title: Text('Enter OTP'),
                            content: Form(
                              key: formKey,
                              child: TextFormField(
                                controller: otpController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'OTP',
                                  counterText: '',
                                ),
                                maxLength: 6,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'OTP is required';
                                  }
                                  // Accept 4-8 numeric digits
                                  if (!RegExp(r'^\\d{4,8}$').hasMatch(value)) {
                                    return 'Enter a valid numeric OTP';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    otp = otpController.text;
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text('Submit'),
                              ),
                            ],
                          );
                        },
                      );
                      return otp;
                    }

                    // sending function to firebase service
                    try {
                      await firebaseService.loginWithPhoneNumber(
                        phoneNumber,
                        getOtpFromUser,
                        context,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Login successful!")),
                      );
                      nav.pushReplacementNamed(HomeScreen.routeName);
                    } on Exception catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error logging in: ${e.toString()}"),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
                child: Text("Login"),
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
