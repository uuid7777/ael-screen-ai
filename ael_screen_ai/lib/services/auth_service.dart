import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final resp = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = resp.data['data'] as Map<String, dynamic>;
    await _api.setToken(data['access_token'] as String);
    return data;
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String? displayName) async {
    final resp = await _api.post('/auth/register', data: {
      'email': email,
      'password': password,
      'display_name': displayName ?? email.split('@')[0],
    });
    final data = resp.data['data'] as Map<String, dynamic>;
    await _api.setToken(data['access_token'] as String);
    return data;
  }

  Future<Map<String, dynamic>> signInWithApple({
    required String identityToken,
    required String authorizationCode,
    required String userId,
    String? email,
    String? displayName,
  }) async {
    final resp = await _api.post('/auth/apple', data: {
      'identity_token': identityToken,
      'authorization_code': authorizationCode,
      'user_id': userId,
      'email': email,
      'display_name': displayName,
    });
    final data = resp.data['data'] as Map<String, dynamic>;
    await _api.setToken(data['access_token'] as String);
    return data;
  }

  Future<UserModel?> getProfile() async {
    try {
      final resp = await _api.get('/auth/me');
      final data = resp.data['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on DioException {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _api.clearToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    return token != null && token.isNotEmpty;
  }
}
