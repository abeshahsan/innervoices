import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:innervoices/bloc/applock/applock_bloc.dart';
import 'package:innervoices/ui/widgets/appbar.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _isDarkTheme = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppbar(title: 'Settings'),
      body: ListView(
        children: [
          _buildSectionHeader('Appearance'),
          ListTile(
            leading: Icon(_isDarkTheme ? Icons.dark_mode : Icons.light_mode),
            title: const Text('Dark Theme'),
            subtitle: const Text('Toggle between light and dark theme'),
            trailing: Switch(
              value: _isDarkTheme,
              onChanged: (value) {
                setState(() {
                  _isDarkTheme = value;
                });
                // TODO: Implement theme switching functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Theme switching coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          _buildSectionHeader('Security'),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change PIN'),
            subtitle: const Text('Update your security PIN'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Use BLoC to handle PIN change with verification
              context.read<ApplockBloc>().add(
                ApplockVerifyForChangeEvent(context),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
