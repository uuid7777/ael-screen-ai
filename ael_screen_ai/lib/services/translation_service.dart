import 'package:dio/dio.dart';
import '../models/translation_model.dart';
import 'api_client.dart';

class TranslationService {
  final ApiClient _api = ApiClient();

  Future<TranslationModel?> translateText({
    required String text,
    String sourceLang = 'auto',
    String targetLang = 'zh-CN',
  }) async {
    try {
      final resp = await _api.post('/translate/', data: {
        'text': text,
        'source_lang': sourceLang,
        'target_lang': targetLang,
      });
      final data = resp.data['data'] as Map<String, dynamic>;
      return TranslationModel.fromJson({
        ...data,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      });
    } on DioException {
      return null;
    }
  }

  Future<TranslationModel?> translateScreen({
    required String imageBase64,
    String? text,
  }) async {
    try {
      final resp = await _api.post('/translate/screen', data: {
        'image_base64': imageBase64,
        'text': text,
      });
      final data = resp.data['data'] as Map<String, dynamic>;
      return TranslationModel.fromJson({
        ...data,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'ocr_used': true,
      });
    } on DioException {
      return null;
    }
  }

  Future<List<TranslationModel>> getHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final resp = await _api.get('/history/', queryParameters: {
        'page': page,
        'page_size': pageSize,
      });
      final data = resp.data['data'] as List<dynamic>;
      return data
          .map((e) => TranslationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }

  Future<bool> addFavorite(String translationId, {String? note}) async {
    try {
      await _api.post('/favorites/', data: {
        'translation_id': translationId,
        'note': note,
      });
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> removeFavorite(String favoriteId) async {
    try {
      await _api.delete('/favorites/$favoriteId');
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> deleteHistory(String translationId) async {
    try {
      await _api.delete('/history/$translationId');
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> clearHistory() async {
    try {
      await _api.delete('/history/');
      return true;
    } on DioException {
      return false;
    }
  }
}
