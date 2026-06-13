import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../services/overlay_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _overlayOnStart = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Floating Bubble', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Start overlay on app launch'),
            subtitle: const Text('Floating bubble appears after app starts'),
            value: _overlayOnStart,
            onChanged: (v) => setState(() => _overlayOnStart = v),
          ),
          ListTile(
            title: const Text('Start Overlay Now'),
            subtitle: const Text('Enable one-tap translation from any screen'),
            leading: const Icon(Icons.blur_on),
            onTap: () async {
              final hasPerm = await OverlayService.hasOverlayPermission();
              if (!hasPerm) {
                final granted = await OverlayService.requestOverlayPermission();
                if (!granted && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Overlay permission denied')),
                  );
                  return;
                }
              }
              await OverlayService.startOverlay();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Floating bubble activated')),
                );
              }
            },
          ),
          const Divider(height: 32),
          Text('Translation', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Default target language'),
            subtitle: const Text('Chinese (Simplified)'),
            leading: const Icon(Icons.language),
          ),
          SwitchListTile(
            title: const Text('Auto-translate'),
            subtitle: const Text('Automatically translate after OCR'),
            value: true,
            onChanged: (_) {},
          ),
          const Divider(height: 32),
          Text('About', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            trailing: Text(AppConfig.appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('API Server'),
            subtitle: Text(AppConfig.baseUrl),
          ),
        ],
      ),
    );
  }
}
