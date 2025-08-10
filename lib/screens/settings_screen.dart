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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final firebaseService = GetIt.instance<FirebaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: const BackButton(),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      backgroundColor: scheme.surface,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Appearance section
              AnimatedBuilder(
                animation: GetIt.instance<ThemeService>(),
                builder: (context, _) {
                  final themeSvc = GetIt.instance<ThemeService>();
                  final seedChoices = <Color>[
                    const Color(0xFF3D8259), // green
                    const Color(0xFF0B57D0), // blue
                    const Color(0xFF9333EA), // purple
                    const Color(0xFFEA580C), // orange
                    const Color(0xFF047857), // teal
                    const Color(0xFFB91C1C), // red
                  ];
                  // Snap to nearest preset so groupValue matches a radio value
                  double groupScale = themeSvc.textScale;
                  const presets = [0.9, 1.0, 1.15, 1.3];
                  double nearest = presets.first;
                  double best = (groupScale - presets.first).abs();
                  for (final p in presets) {
                    final d = (groupScale - p).abs();
                    if (d < best) {
                      best = d;
                      nearest = p;
                    }
                  }
                  groupScale = nearest;

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
                                    FocusScope.of(context).unfocus();
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
                                    FocusScope.of(context).unfocus();
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
                                groupValue: groupScale,
                                onChanged: (v) {
                                  FocusScope.of(context).unfocus();
                                  themeSvc.setTextScale(v ?? 1.0);
                                },
                              ),
                              RadioListTile<double>(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Default', style: textTheme.bodyLarge),
                                value: 1.0,
                                groupValue: groupScale,
                                onChanged: (v) {
                                  FocusScope.of(context).unfocus();
                                  themeSvc.setTextScale(v ?? 1.0);
                                },
                              ),
                              RadioListTile<double>(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Large', style: textTheme.bodyLarge),
                                value: 1.15,
                                groupValue: groupScale,
                                onChanged: (v) {
                                  FocusScope.of(context).unfocus();
                                  themeSvc.setTextScale(v ?? 1.0);
                                },
                              ),
                              RadioListTile<double>(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Extra large', style: textTheme.bodyLarge),
                                value: 1.3,
                                groupValue: groupScale,
                                onChanged: (v) {
                                  FocusScope.of(context).unfocus();
                                  themeSvc.setTextScale(v ?? 1.0);
                                },
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
                                  onTap: () {
                                    FocusScope.of(context).unfocus();
                                    themeSvc.setSeedColor(seedColor);
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: seedColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: themeSvc.seedColor.value == seedColor.value
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
                  Navigator.of(context).pushNamed(EditInformationScreen.routeName);
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
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogCtx) {
                      bool obscure = true;
                      final formKey = GlobalKey<FormState>();
                      final newPassController = TextEditingController();
                      final confirmPassController = TextEditingController();
                      return StatefulBuilder(
                        builder: (context, setState) {
                          final s = Theme.of(context).colorScheme;
                          final t = Theme.of(context).textTheme;
                          return AlertDialog(
                            backgroundColor: s.surfaceContainerHigh,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(
                              'Change Password',
                              style: t.titleLarge?.copyWith(color: s.onSurface),
                            ),
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
                                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                                      onPressed: () => setState(() => obscure = !obscure),
                                    ),
                                  ),
                                  obscureText: obscure,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Password is required';
                                    if (value.length < 8) return 'Password must be at least 8 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: confirmPassController,
                                  keyboardType: TextInputType.visiblePassword,
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm New Password',
                                    suffixIcon: IconButton(
                                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                                      onPressed: () => setState(() => obscure = !obscure),
                                    ),
                                  ),
                                  obscureText: obscure,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Please confirm your password';
                                    if (value != newPassController.text) return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                            actions: [
                              FilledButton(
                                onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                try {
                                  await firebaseService.changePassword(newPassController.text);
                                  if (context.mounted) Navigator.of(context).pop();
                                } on Exception catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error changing password: $e')),
                                  );
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Password changed successfully.')),
                                );
                                },
                                child: const Text('Submit'),
                              ),
                            ],
                          );
                        },
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
                    builder: (ctx) {
                      final s = Theme.of(ctx).colorScheme;
                      final t = Theme.of(ctx).textTheme;
                      return AlertDialog(
                        backgroundColor: s.surfaceContainerHigh,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          'Confirm Logout',
                          style: t.titleLarge?.copyWith(color: s.onSurface),
                        ),
                        content: Text(
                          'Are you sure you want to log out?',
                          style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              final themeSvc = GetIt.instance<ThemeService>();
                              await themeSvc.resetToDefaults();
                              await firebaseService.logOut();
                              if (!ctx.mounted) return;
                              Navigator.of(ctx).pushReplacementNamed(LoginScreen.routeName);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Logged out successfully.')),
                              );
                            },
                            child: const Text('Logout'),
                          ),
                        ],
                      );
                    },
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
                    builder: (ctx) {
                      final s = Theme.of(ctx).colorScheme;
                      final t = Theme.of(ctx).textTheme;
                      return AlertDialog(
                        backgroundColor: s.surfaceContainerHigh,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          'Confirm Account Deletion',
                          style: t.titleLarge?.copyWith(color: s.onSurface),
                        ),
                        content: Text(
                          'Are you sure you want to delete your account? This action cannot be undone.',
                          style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              try {
                                await firebaseService.deleteAccount();
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Account deleted successfully.')),
                                );
                              } on Exception catch (e) {
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('Error deleting account: $e')),
                                );
                                return;
                              }
                              if (!ctx.mounted) return;
                              Navigator.of(ctx).pushReplacementNamed(LoginScreen.routeName);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: s.error,
                              foregroundColor: s.onError,
                            ),
                            child: const Text('Delete Account'),
                          ),
                        ],
                      );
                    },
                  );
                },
                textTheme: textTheme,
                scheme: scheme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
