import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import 'data_providers.dart';

class AuthState {
  final String? token;
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({this.token, this.user, this.isLoading = false, this.errorMessage});

  bool get isAuthenticated => token != null && user != null;

  AuthState copyWith({
    String? token,
    User? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      token: token ?? this.token,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  @override
  AuthState build() {
    _loadPersistedAuth();
    return AuthState(isLoading: true);
  }

  Future<void> _loadPersistedAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userStr = prefs.getString(_userKey);

      if (token != null && userStr != null) {
        final userJson = jsonDecode(userStr) as Map<String, dynamic>;
        final user = User.fromJson(userJson);
        state = AuthState(token: token, user: user);
      } else {
        state = AuthState();
      }
    } catch (e) {
      state = AuthState(errorMessage: 'Failed to load authentication: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final baseUrl = ref.read(baseUrlProvider);
      final api = ApiService(baseUrl: baseUrl);
      final result = await api.login(email, password);

      // Defensively support both wrapped {"data": {"token": "...", "user": ...}}
      // and unwrapped {"token": "...", "user": ...} responses.
      final responseData = result.containsKey('data')
          ? (result['data'] as Map<String, dynamic>)
          : result;

      final token = responseData['token'] as String;
      final userData = responseData['user'] as Map<String, dynamic>;
      final user = User.fromJson(userData);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));

      state = AuthState(token: token, user: user);
      return true;
    } catch (e) {
      String msg = 'Login failed';
      if (e is DioException) {
        if (e.response != null && e.response!.data != null) {
          final data = e.response!.data;
          if (data is String) {
            msg = data;
          } else if (data is Map && data.containsKey('message')) {
            msg = data['message'].toString();
          } else if (data is Map && data.containsKey('error')) {
            msg = data['error'].toString();
          } else {
            msg = data.toString();
          }
        } else {
          msg = e.message ?? e.toString();
        }
      } else if (e is Exception) {
        msg = e.toString().replaceAll('Exception: ', '');
      } else {
        msg = e.toString();
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> register(String email, String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final baseUrl = ref.read(baseUrlProvider);
      final api = ApiService(baseUrl: baseUrl);
      final result = await api.register(email, username, password);

      // Defensively support both wrapped {"data": {"token": "...", "user": ...}}
      // and unwrapped {"token": "...", "user": ...} responses.
      final responseData = result.containsKey('data')
          ? (result['data'] as Map<String, dynamic>)
          : result;

      final token = responseData['token'] as String;
      final userData = responseData['user'] as Map<String, dynamic>;
      final user = User.fromJson(userData);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));

      state = AuthState(token: token, user: user);
      return true;
    } catch (e) {
      String msg = 'Registration failed';
      if (e is DioException) {
        if (e.response != null && e.response!.data != null) {
          final data = e.response!.data;
          if (data is String) {
            msg = data;
          } else if (data is Map && data.containsKey('message')) {
            msg = data['message'].toString();
          } else if (data is Map && data.containsKey('error')) {
            msg = data['error'].toString();
          } else {
            msg = data.toString();
          }
        } else {
          msg = e.message ?? e.toString();
        }
      } else if (e is Exception) {
        msg = e.toString().replaceAll('Exception: ', '');
      } else {
        msg = e.toString();
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<void> logout() async {
    state = AuthState(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      state = AuthState();
    } catch (e) {
      state = AuthState(errorMessage: 'Logout failed: $e');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
