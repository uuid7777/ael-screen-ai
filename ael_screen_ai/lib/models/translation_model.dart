class TranslationModel {
  final String id;
  final String userId;
  final String originalText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final bool ocrUsed;
  final String? screenshotUrl;
  final bool isFavorite;
  final int processingTimeMs;
  final DateTime createdAt;

  TranslationModel({
    required this.id,
    this.userId = '',
    required this.originalText,
    required this.translatedText,
    this.sourceLang = 'auto',
    this.targetLang = 'zh-CN',
    this.ocrUsed = false,
    this.screenshotUrl,
    this.isFavorite = false,
    this.processingTimeMs = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory TranslationModel.fromJson(Map<String, dynamic> json) {
    return TranslationModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      originalText: json['original_text'] as String? ?? '',
      translatedText: json['translated_text'] as String? ?? '',
      sourceLang: json['source_lang'] as String? ?? 'auto',
      targetLang: json['target_lang'] as String? ?? 'zh-CN',
      ocrUsed: json['ocr_used'] as bool? ?? false,
      screenshotUrl: json['screenshot_url'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      processingTimeMs: json['processing_time_ms'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'original_text': originalText,
        'translated_text': translatedText,
        'source_lang': sourceLang,
        'target_lang': targetLang,
        'ocr_used': ocrUsed,
        'screenshot_url': screenshotUrl,
        'is_favorite': isFavorite,
        'processing_time_ms': processingTimeMs,
        'created_at': createdAt.toIso8601String(),
      };
}
