import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pocket.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/notification.dart';
import '../models/api_response.dart';

class ApiService {
  static const String defaultBaseUrl = 'http://192.168.1.222:5008/api/v1';
  static const String _prefsKey = 'api_base_url';

  late final Dio _dio;

  ApiService({String? baseUrl, String? token}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? defaultBaseUrl,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );

    // Add logging interceptor
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => print('🌐 API: $object'),
      ),
    );
  }

  /// Create an ApiService with the base URL from SharedPreferences.
  static Future<ApiService> create() async {
    final baseUrl = await getSavedBaseUrl();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return ApiService(baseUrl: baseUrl, token: token);
  }

  /// Get the saved base URL, or default if not set.
  static Future<String> getSavedBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey) ?? defaultBaseUrl;
  }

  /// Save a new base URL to SharedPreferences.
  static Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, url);
  }

  /// Update the Dio base URL at runtime.
  void updateBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  String get baseUrl => _dio.options.baseUrl;

  // Pockets
  Future<PaginationResponse<Pocket>> getPockets({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      '/pockets',
      queryParameters: {'page': page, 'limit': limit},
    );
    return PaginationResponse.fromJson(
      response.data,
      (json) => Pocket.fromJson(json),
    );
  }

  Future<Pocket> createPocket(Map<String, dynamic> data) async {
    final response = await _dio.post('/pockets', data: data);
    return Pocket.fromJson(response.data['data']);
  }

  Future<Pocket> getPocket(String id) async {
    final response = await _dio.get('/pockets/$id');
    return Pocket.fromJson(response.data['data']);
  }

  Future<Pocket> updatePocket(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/pockets/$id', data: data);
    return Pocket.fromJson(response.data['data']);
  }

  Future<void> deletePocket(String id) async {
    await _dio.delete('/pockets/$id');
  }

  // Transactions
  Future<PaginationResponse<Transaction>> getTransactions({
    int page = 1,
    int limit = 10,
    String? pocketId,
    String? search,
    String? sort,
    String? sortOrder,
  }) async {
    final response = await _dio.get(
      '/transactions',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (pocketId != null) 'pocket_id': pocketId,
        if (search != null) 'search': search,
        if (sort != null) 'sort': sort,
        if (sortOrder != null) 'sort_order': sortOrder,
      },
    );
    return PaginationResponse.fromJson(
      response.data,
      (json) => Transaction.fromJson(json),
    );
  }

  Future<Transaction> createTransaction(Map<String, dynamic> data) async {
    final response = await _dio.post('/transactions', data: data);
    return Transaction.fromJson(response.data['data']);
  }

  Future<Transaction> getTransaction(String id) async {
    final response = await _dio.get('/transactions/$id');
    return Transaction.fromJson(response.data['data']);
  }

  Future<Transaction> updateTransaction(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put('/transactions/$id', data: data);
    return Transaction.fromJson(response.data['data']);
  }

  Future<void> deleteTransaction(String id) async {
    await _dio.delete('/transactions/$id');
  }

  // Categories
  Future<PaginationResponse<Category>> getCategories() async {
    final response = await _dio.get('/categories');
    return PaginationResponse.fromJson(
      response.data,
      (json) => Category.fromJson(json),
    );
  }

  Future<Category> createCategory(Map<String, dynamic> data) async {
    final response = await _dio.post('/categories', data: data);
    return Category.fromJson(response.data['data']);
  }

  Future<Category> updateCategory(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/categories/$id', data: data);
    return Category.fromJson(response.data['data']);
  }

  Future<void> deleteCategory(String id) async {
    await _dio.delete('/categories/$id');
  }

  // Inbox
  Future<void> syncNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    await _dio.post('/inbox/sync', data: notifications);
  }

  Future<PaginationResponse<AppNotification>>
  getUnresolvedNotifications() async {
    final response = await _dio.get('/inbox');
    return PaginationResponse.fromJson(
      response.data,
      (json) => AppNotification.fromJson(json),
    );
  }

  Future<void> resolveNotification(String id, Map<String, dynamic> data) async {
    // data matches ResolveTransactionRequest from swagger.json:
    // pocket_id, category_id, destination_pocket_id, amount, type, title, description
    await _dio.post('/transactions/$id/resolve', data: data);
  }

  Future<void> ignoreNotification(String id) async {
    await _dio.post('/transactions/$id/reject');
  }

  // Auth Methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    if (response.data is String) {
      return jsonDecode(response.data as String) as Map<String, dynamic>;
    }
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(
    String email,
    String username,
    String password,
  ) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'email': email,
        'username': username,
        'password': password,
      },
    );
    if (response.data is String) {
      return jsonDecode(response.data as String) as Map<String, dynamic>;
    }
    return response.data as Map<String, dynamic>;
  }

  // AI Analyze
  Future<String> aiAnalyze({String? query}) async {
    final response = await _dio.post(
      '/transactions/ai-analyze',
      data: {
        if (query != null) 'query': query,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['analysis'] as String;
    }
    return data.toString();
  }
}
