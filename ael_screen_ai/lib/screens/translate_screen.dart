import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/translation_provider.dart';
import '../models/translation_model.dart';
import '../services/translation_service.dart';

class TranslateScreen extends ConsumerStatefulWidget {
  final dynamic args;
  const TranslateScreen({super.key, this.args});

  @override
  ConsumerState<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends ConsumerState<TranslateScreen> {
  final _textCtrl = TextEditingController();
  String _sourceLang = 'auto';
  String _targetLang = 'zh-CN';
  bool _translated = false;

  @override
  void initState() {
    super.initState();
    if (widget.args is Map) {
      final args = widget.args as Map<String, dynamic>;
      if (args.containsKey('ocr_text')) {
        _textCtrl.text = args['ocr_text'] as String;
        _autoTranslate();
      }
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _autoTranslate() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _translated = true);
    await ref.read(translationProvider.notifier).translateText(
      text: text, sourceLang: _sourceLang, targetLang: _targetLang,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(translationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Translate'),
        actions: [
          if (state.currentTranslation != null)
            IconButton(
              icon: const Icon(Icons.favorite_outline),
              tooltip: 'Add to favorites',
              onPressed: () async {
                final service = TranslationService();
                await service.addFavorite(state.currentTranslation!.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to favorites')),
                  );
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Input area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sourceLang,
                      items: const [
                        DropdownMenuItem(value: 'auto', child: Text('Auto Detect')),
                        DropdownMenuItem(value: 'zh-CN', child: Text('Chinese')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'ja', child: Text('Japanese')),
                        DropdownMenuItem(value: 'ko', child: Text('Korean')),
                      ],
                      onChanged: (v) => setState(() => _sourceLang = v ?? 'auto'),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () => setState(() {
                      final tmp = _sourceLang;
                      _sourceLang = _targetLang;
                      _targetLang = tmp;
                    }),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _targetLang,
                      items: const [
                        DropdownMenuItem(value: 'zh-CN', child: Text('Chinese')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'ja', child: Text('Japanese')),
                        DropdownMenuItem(value: 'ko', child: Text('Korean')),
                        DropdownMenuItem(value: 'fr', child: Text('French')),
                        DropdownMenuItem(value: 'de', child: Text('German')),
                        DropdownMenuItem(value: 'es', child: Text('Spanish')),
                        DropdownMenuItem(value: 'th', child: Text('Thai')),
                        DropdownMenuItem(value: 'vi', child: Text('Vietnamese')),
                      ],
                      onChanged: (v) => setState(() => _targetLang = v ?? 'zh-CN'),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: _textCtrl,
                  maxLines: 5,
                  minLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter text or use camera to scan...',
                    alignLabelWithHint: true,
                  ),
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: state.isTranslating ? null : _autoTranslate,
                  icon: state.isTranslating
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.translate),
                  label: Text(state.isTranslating ? 'Translating...' : 'Translate'),
                ),
              ],
            ),
          ),

          // Result area
          if (state.currentTranslation != null)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: Border(top: BorderSide(color: theme.dividerColor)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('Translation',
                          style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          tooltip: 'Copy result',
                          onPressed: () {
                            // Clipboard copy
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied to clipboard')),
                            );
                          },
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                        state.currentTranslation!.translatedText,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.currentTranslation!.sourceLang != 'auto'
                            ? 'Detected: ${state.currentTranslation!.sourceLang}'
                            : '',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      if (state.currentTranslation!.processingTimeMs > 0)
                        Text(
                          '${state.currentTranslation!.processingTimeMs}ms',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
