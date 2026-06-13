import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/translation_model.dart';
import '../services/translation_service.dart';
import '../services/ocr_service.dart';

final translationServiceProvider =
    Provider<TranslationService>((ref) => TranslationService());

final ocrServiceProvider = Provider<OcrService>((ref) {
  final ocr = OcrService();
  ref.onDispose(() => ocr.dispose());
  return ocr;
});

final translationProvider =
    StateNotifierProvider<TranslationNotifier, TranslationState>(
  (ref) => TranslationNotifier(
    ref.read(translationServiceProvider),
    ref.read(ocrServiceProvider),
  ),
);

class TranslationState {
  final TranslationModel? currentTranslation;
  final List<TranslationModel> history;
  final bool isTranslating;
  final bool isOcrReady;
  final String? error;
  final OcrResult? lastOcrResult;

  const TranslationState({
    this.currentTranslation,
    this.history = const [],
    this.isTranslating = false,
    this.isOcrReady = false,
    this.error,
    this.lastOcrResult,
  });

  TranslationState copyWith({
    TranslationModel? currentTranslation,
    List<TranslationModel>? history,
    bool? isTranslating,
    bool? isOcrReady,
    String? error,
    OcrResult? lastOcrResult,
    bool clearCurrent = false,
    bool clearError = false,
  }) {
    return TranslationState(
      currentTranslation: clearCurrent ? null : (currentTranslation ?? this.currentTranslation),
      history: history ?? this.history,
      isTranslating: isTranslating ?? this.isTranslating,
      isOcrReady: isOcrReady ?? this.isOcrReady,
      error: clearError ? null : (error ?? this.error),
      lastOcrResult: lastOcrResult ?? this.lastOcrResult,
    );
  }
}

class TranslationNotifier extends StateNotifier<TranslationState> {
  final TranslationService _translationService;
  final OcrService _ocrService;

  TranslationNotifier(this._translationService, this._ocrService)
      : super(const TranslationState());

  Future<TranslationModel?> translateText({
    required String text,
    String sourceLang = 'auto',
    String targetLang = 'zh-CN',
  }) async {
    state = state.copyWith(isTranslating: true, clearError: true);
    final result = await _translationService.translateText(
      text: text,
      sourceLang: sourceLang,
      targetLang: targetLang,
    );
    state = state.copyWith(
      currentTranslation: result,
      isTranslating: false,
      error: result == null ? 'Translation failed' : null,
    );
    return result;
  }

  Future<OcrResult?> pickAndOcr({bool fromCamera = false}) async {
    state = state.copyWith(isTranslating: true);
    final result = await _ocrService.pickAndRecognize(fromCamera: fromCamera);
    state = state.copyWith(
      isOcrReady: result != null && result.text.isNotEmpty,
      lastOcrResult: result,
      isTranslating: false,
    );
    return result;
  }

  Future<void> loadHistory() async {
    final history = await _translationService.getHistory();
    state = state.copyWith(history: history);
  }

  Future<void> translateOcrResult() async {
    if (state.lastOcrResult == null || state.lastOcrResult!.isEmpty) return;
    await translateText(text: state.lastOcrResult!.text);
  }

  void clearTranslation() {
    state = state.copyWith(clearCurrent: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
