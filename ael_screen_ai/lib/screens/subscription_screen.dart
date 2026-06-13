import 'package:flutter/material.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 20),
          Icon(Icons.star, size: 64, color: Colors.amber.shade600),
          const SizedBox(height: 16),
          Text('Unlock Premium', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Get the most out of AEL Screen AI', style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 32),

          _FeatureRow(icon: Icons.auto_awesome, text: 'Unlimited translations'),
          _FeatureRow(icon: Icons.history, text: 'Full translation history'),
          _FeatureRow(icon: Icons.favorite, text: 'Save unlimited favorites'),
          _FeatureRow(icon: Icons.blur_on, text: 'Floating bubble translation'),
          _FeatureRow(icon: Icons.cloud_done, text: 'Cloud sync across devices'),
          _FeatureRow(icon: Icons.ads_click, text: 'No ads'),

          const SizedBox(height: 32),

          // Monthly
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Monthly', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('\$4.99 / month', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Cancel anytime'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {},
                    child: const Text('Subscribe Monthly'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Yearly
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Yearly', style: theme.textTheme.titleMedium),
                      const SizedBox(width: 8),
                      Chip(
                        label: const Text('Save 50%', style: TextStyle(fontSize: 11)),
                        backgroundColor: Colors.green.withValues(alpha: 0.1),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('\$29.99 / year', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('\$2.50/month equivalent'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {},
                    child: const Text('Subscribe Yearly'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 22),
          const SizedBox(width: 16),
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
