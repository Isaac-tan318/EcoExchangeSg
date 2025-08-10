import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/auth/add_number_screen.dart';
import 'package:flutter_application_1/screens/auth/login_screen.dart';
import 'package:flutter_application_1/screens/edit_information_screen.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/widgets/settings_button.dart';
import 'package:flutter_application_1/services/theme_service.dart';
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
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      backgroundColor: scheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            // Appearance section
            Builder(
              builder: (context) {
                final themeSvc = GetIt.instance<ThemeService>();
                final seedChoices = <Color>[
                  const Color(0xFF3D8259), // green
                  const Color(0xFF0B57D0), // blue
                  const Color(0xFF9333EA), // purple
                  const Color(0xFFEA580C), // orange
                  const Color(0xFF047857), // teal
                  const Color(0xFFB91C1C), // red
                ];
                return Card(
                  color: scheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appearance',
                          style: textTheme.titleMedium?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Flexible(
                              child: RadioListTile<ThemeMode>(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Light',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: scheme.onSurface,
                                  ),
                                ),
                                value: ThemeMode.light,
                                groupValue: themeSvc.mode,
                                onChanged: (value) {
                                  if (value != null) themeSvc.setThemeMode(value);
                                },
                              ),
                            ),
                            Flexible(
                              child: RadioListTile<ThemeMode>(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Dark',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: scheme.onSurface,
                                  ),
                                ),
                                value: ThemeMode.dark,
                                groupValue: themeSvc.mode,
                                onChanged: (value) {
                                  if (value != null) themeSvc.setThemeMode(value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Text size',
                          style: textTheme.titleSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Column(
                          children: [
                            RadioListTile<double>(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Small', style: textTheme.bodyLarge),
                              value: 0.9,
                              groupValue: themeSvc.textScale,
                              onChanged: (v) => themeSvc.setTextScale(v ?? 1.0),
                            ),
                            RadioListTile<double>(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Default', style: textTheme.bodyLarge),
                              value: 1.0,
                              groupValue: themeSvc.textScale,
                              onChanged: (v) => themeSvc.setTextScale(v ?? 1.0),
                            ),
                            RadioListTile<double>(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Large', style: textTheme.bodyLarge),
                              value: 1.15,
                              groupValue: themeSvc.textScale,
                              onChanged: (v) => themeSvc.setTextScale(v ?? 1.0),
                            ),
                            RadioListTile<double>(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Extra large', style: textTheme.bodyLarge),
                              value: 1.3,
                              groupValue: themeSvc.textScale,
                              onChanged: (v) => themeSvc.setTextScale(v ?? 1.0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Accent color',
                          style: textTheme.titleSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
              for (final seedColor in seedChoices)
                              GestureDetector(
                onTap: () => themeSvc.setSeedColor(seedColor),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                  color: seedColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                      themeSvc.seedColor.value == seedColor.value
                                              ? scheme.onSurface
                                              : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
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
                    bool obscure = true;
                    final formKey = GlobalKey<FormState>();
                    final newPassController = TextEditingController();
                    final confirmPassController = TextEditingController();
                    // StatefulBuilder used to make local state inside the dialog
                    return StatefulBuilder(
                      builder:
                          (context, setState) => AlertDialog(
                            title: const Text('Change Password'),
                            content: Form(
                              key: formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFormField(
                                    controller: newPassController,
                                    keyboardType: TextInputType.visiblePassword,
                                    textInputAction: TextInputAction.next,
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
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password is required';
                                      }
                                      if (value.length < 8) {
                                        return 'Password must be at least 8 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 12),
                                  TextFormField(
                                    controller: confirmPassController,
                                    keyboardType: TextInputType.visiblePassword,
                                    textInputAction: TextInputAction.done,
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
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please confirm your password';
                                      }
                                      if (value != newPassController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) return;

                                  // call to firebase to change password
                                  try {
                                    await firebaseService.changePassword(
                                      newPassController.text,
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
                            onPressed: () async {
                              // Reset theme to defaults on logout
                              final themeSvc = GetIt.instance<ThemeService>();
                              await themeSvc.resetToDefaults();
                              await firebaseService.logOut();
                              if (!context.mounted) return;
                              Navigator.of(
                                context,
                              ).pushReplacementNamed(LoginScreen.routeName);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
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
