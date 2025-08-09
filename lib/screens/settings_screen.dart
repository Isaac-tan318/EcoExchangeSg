import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/auth/add_number_screen.dart';
import 'package:flutter_application_1/screens/auth/login_screen.dart';
import 'package:flutter_application_1/screens/edit_information_screen.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/widgets/settings_button.dart';
import 'package:get_it/get_it.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    FirebaseService firebaseService = GetIt.instance<FirebaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: BackButton(),
        backgroundColor: scheme.surface,
        elevation: 0,
      ),
      backgroundColor: scheme.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            SettingsButton(
              icon: Icons.edit,
              label: 'Edit information',
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamed(EditInformationScreen.routeName);
              },
              textTheme: textTheme,
              scheme: scheme,
            ),
            const SizedBox(height: 12),
            SettingsButton(
              icon: Icons.nightlight_round,
              label: 'Change theme',
              onPressed: () {},
              textTheme: textTheme,
              scheme: scheme,
            ),
            const SizedBox(height: 12),
            SettingsButton(
              icon: Icons.phone,
              label: 'Add phone number',
              onPressed: () {
                Navigator.of(context).pushNamed(AddNumberScreen.routeName);
              },
              textTheme: textTheme,
              scheme: scheme,
            ),
            const SizedBox(height: 12),
            SettingsButton(
              icon: Icons.edit,
              label: 'Change password',

              // opens a dialog to the user's change password
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    String newPassword = '';
                    String confirmPassword = '';
                    bool obscure = true;
                    // StatefulBuilder used to make local state inside the dialog
                    return StatefulBuilder(
                      builder:
                          (context, setState) => AlertDialog(
                            title: const Text('Change Password'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  onChanged: (value) {
                                    newPassword = value;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'New Password',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscure
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          obscure = !obscure;
                                        });
                                      },
                                    ),
                                  ),
                                  obscureText: obscure,
                                ),
                                SizedBox(height: 12),
                                TextField(
                                  onChanged: (value) {
                                    confirmPassword = value;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Confirm New Password',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscure
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          obscure = !obscure;
                                        });
                                      },
                                    ),
                                  ),
                                  obscureText: obscure,
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  if (newPassword.isEmpty ||
                                      confirmPassword.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Please fill in both fields.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (newPassword != confirmPassword) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Passwords do not match.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  // call to firebase to change password
                                  try {
                                    await firebaseService.changePassword(
                                      newPassword,
                                    );
                                    Navigator.of(context).pop();
                                  } on Exception catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error changing password: $e',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Password changed successfully.',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Submit'),
                              ),
                            ],
                          ),
                    );
                  },
                );
              },
              textTheme: textTheme,
              scheme: scheme,
            ),
            const SizedBox(height: 12),
            SettingsButton(
              icon: Icons.logout,
              label: 'Logout',
              onPressed: () async {
                showDialog<bool>(
                  context: context,
                  builder:
                      // confirm logout dialog
                      (context) => AlertDialog(
                        title: const Text('Confirm Logout'),
                        content: const Text(
                          'Are you sure you want to log out?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              firebaseService.logOut();
                              Navigator.of(
                                context,
                              ).pushReplacementNamed(LoginScreen.routeName);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Logged out successfully.'),
                                ),
                              );
                            },

                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                );
              },
              textTheme: textTheme,
              scheme: scheme,
            ),
            const SizedBox(height: 12),
            SettingsButton(
              icon: Icons.delete,
              label: 'Delete account',
              onPressed: () async {
                showDialog<bool>(
                  context: context,
                  builder:
                      // confirm deleting account
                      (context) => AlertDialog(
                        title: const Text('Confirm Account Deletion'),
                        content: const Text(
                          'Are you sure you want to delete your account? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              try {
                                await firebaseService.deleteAccount();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Account deleted successfully.',
                                    ),
                                  ),
                                );
                              } on Exception catch (e) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error deleting account: $e'),
                                  ),
                                );
                                return;
                              }
                              Navigator.of(
                                context,
                              ).pushReplacementNamed(LoginScreen.routeName);
                            },
                            child: const Text('Delete Account'),
                          ),
                        ],
                      ),
                );
              },
              textTheme: textTheme,
              scheme: scheme,
            ),
          ],
        ),
      ),
    );
  }
}
