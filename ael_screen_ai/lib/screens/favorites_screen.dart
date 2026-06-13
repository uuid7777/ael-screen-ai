import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/translation_service.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final _service = TranslationService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _service.getFavorites();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_outline, size: 64, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      const Text('No favorites yet'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/'),
                        child: const Text('Start translating'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    return ListTile(
                      title: Text(item['original_text'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(item['translated_text'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                        onPressed: () async {
                          await _service.removeFavorite(item['id'] as String);
                          _load();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
