import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/overlay_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _overlayActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authStateProvider.notifier).checkAuth();
    });
  }

  void _toggleOverlay() async {
    if (_overlayActive) {
      await OverlayService.stopOverlay();
      setState(() => _overlayActive = false);
    } else {
      final hasPermission = await OverlayService.hasOverlayPermission();
      if (!hasPermission) {
        final granted = await OverlayService.requestOverlayPermission();
        if (!granted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Need overlay permission for floating bubble')),
          );
          return;
        }
      }
      final started = await OverlayService.startOverlay();
      setState(() => _overlayActive = started);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(theme, authState),
          _buildHistoryTab(),
          _buildProfileTab(theme, authState),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.translate_outlined), selectedIcon: Icon(Icons.translate), label: 'Translate'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeTab(ThemeData theme, AuthState authState) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AEL Screen AI'),
        actions: [
          IconButton(
            icon: Icon(_overlayActive ? Icons.blur_on : Icons.blur_circular_outlined),
            tooltip: 'Floating bubble',
            onPressed: _toggleOverlay,
            color: _overlayActive ? theme.colorScheme.primary : null,
          ),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.pushNamed(context, '/settings')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!authState.isLoggedIn)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Icon(Icons.person_outline, size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  const Text('Sign in to save translation history', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    icon: const Icon(Icons.login), label: const Text('Sign In / Register'),
                  ),
                ]),
              ),
            ),
          const SizedBox(height: 24),
          Text('Translate', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _ActionCard(
              icon: Icons.camera_alt_outlined, label: 'Camera', subtitle: 'Take a photo',
              color: theme.colorScheme.primary,
              onTap: () => Navigator.pushNamed(context, '/camera'),
            )),
            const SizedBox(width: 12),
            Expanded(child: _ActionCard(
              icon: Icons.image_outlined, label: 'Gallery', subtitle: 'Pick an image',
              color: theme.colorScheme.secondary,
              onTap: () => Navigator.pushNamed(context, '/camera', arguments: {'source': 'gallery'}),
            )),
          ]),
          const SizedBox(height: 24),
          Text('Quick Actions', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _QuickActionTile(
            icon: Icons.blur_on, title: 'Floating Bubble',
            subtitle: _overlayActive ? 'Tap to translate any screen' : 'Enable one-tap translation from any app',
            trailing: Switch(value: _overlayActive, onChanged: (_) => _toggleOverlay()),
          ),
          _QuickActionTile(icon: Icons.history, title: 'History', subtitle: 'View recent translations',
            onTap: () => Navigator.pushNamed(context, '/history')),
          _QuickActionTile(icon: Icons.favorite_outline, title: 'Favorites', subtitle: 'Saved translations',
            onTap: () => Navigator.pushNamed(context, '/favorites')),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Scaffold(
      appBar: AppBar(title: const Text('Translation History')),
      body: const Center(child: Text('History will appear here')),
    );
  }

  Widget _buildProfileTab(ThemeData theme, AuthState authState) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (authState.isLoggedIn && authState.user != null) ...[
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                (authState.user!.displayName ?? authState.user!.email ?? 'U')[0].toUpperCase(),
                style: TextStyle(fontSize: 32, color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: 12),
            Text(authState.user!.displayName ?? 'User', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            if (authState.user!.email != null)
              Text(authState.user!.email!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            if (authState.user!.isPremium)
              Chip(
                avatar: Icon(Icons.star, size: 18, color: Colors.amber.shade700),
                label: const Text('Premium'),
                backgroundColor: Colors.amber.withValues(alpha: 0.15),
              ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.pushNamed(context, '/subscription'),
              icon: const Icon(Icons.subscriptions_outlined), label: const Text('Manage Subscription'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => ref.read(authStateProvider.notifier).logout(),
              icon: const Icon(Icons.logout), label: const Text('Sign Out'),
            ),
          ] else ...[
            const Icon(Icons.person_outline, size: 64),
            const SizedBox(height: 16),
            const Text('Sign in to access your profile'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: const Icon(Icons.login), label: const Text('Sign In / Register'),
            ),
          ],
          const SizedBox(height: 32),
          ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.pushNamed(context, '/settings')),
          ListTile(leading: const Icon(Icons.info_outline), title: const Text('About'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showAboutDialog(context: context, applicationName: 'AEL Screen AI', applicationVersion: '1.0.0')),
        ],
      ),
    );
  }
}
