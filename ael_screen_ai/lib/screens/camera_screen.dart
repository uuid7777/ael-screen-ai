import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/translation_provider.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? args;
  const CameraScreen({super.key, this.args});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickImage();
    });
  }

  Future<void> _pickImage() async {
    final fromCamera = widget.args?['source'] != 'gallery';
    final result = await ref.read(translationProvider.notifier).pickAndOcr(fromCamera: fromCamera);
    if (result != null && result.text.isNotEmpty && mounted) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/translate', arguments: {
          'ocr_text': result.text,
          'ocr_lang': result.detectedLanguage,
        });
      }
    } else if (result != null && result.text.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text detected in image. Try a clearer image.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(translationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Text')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.isTranslating) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Processing image...', style: Theme.of(context).textTheme.bodyLarge),
            ] else ...[
              Icon(Icons.text_snippet_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              const Text('Select or capture an image with text'),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref.read(translationProvider.notifier).pickAndOcr(fromCamera: true),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.read(translationProvider.notifier).pickAndOcr(fromCamera: false),
                icon: const Icon(Icons.photo_library),
                label: const Text('Pick from Gallery'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
