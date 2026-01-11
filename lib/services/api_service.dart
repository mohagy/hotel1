/// API Service Base Class
/// 
/// Provides HTTP client for PHP API integration with error handling and retry logic

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';

class ApiService {
  late final Dio _dio;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add Firebase ID token if available
          final user = _auth.currentUser;
          if (user != null) {
            try {
              final token = await user.getIdToken();
              options.headers['Authorization'] = 'Bearer $token';
              
              // Also send to Firebase auth verify endpoint to establish PHP session
              // This is optional and can be done once per session
              // await _verifyFirebaseToken(token);
            } catch (e) {
              // Token retrieval failed, continue without auth header
              debugPrint('Error getting Firebase token: $e');
            }
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle errors and retry logic
          if (error.response?.statusCode == 401) {
            // Handle unauthorized - try to refresh token or redirect to login
            final user = _auth.currentUser;
            if (user != null) {
              try {
                // Try to refresh token
                await user.getIdToken(true); // Force refresh
                // Retry the request
                final opts = error.requestOptions;
                final response = await _dio.request(
                  opts.path,
                  options: Options(method: opts.method, headers: opts.headers),
                  data: opts.data,
                  queryParameters: opts.queryParameters,
                );
                return handler.resolve(response);
              } catch (e) {
                // Refresh failed, redirect to login
                debugPrint('Token refresh failed: $e');
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Verify Firebase token with PHP backend to establish session
  Future<void> _verifyFirebaseToken(String idToken) async {
    try {
      await _dio.post(
        ApiConfig.authEndpoint,
        data: {'idToken': idToken},
      );
    } catch (e) {
      debugPrint('Error verifying Firebase token: $e');
    }
  }

  Dio get dio => _dio;

  /// GET request with retry logic
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    int retries = ApiConfig.maxRetries,
  }) async {
    int attempts = 0;
    while (attempts < retries) {
      try {
        return await _dio.get<T>(
          path,
          queryParameters: queryParameters,
          options: options,
        );
      } catch (e) {
        attempts++;
        if (attempts >= retries) rethrow;
        await Future.delayed(ApiConfig.retryDelay);
      }
    }
    throw Exception('Max retries exceeded');
  }

  /// POST request with retry logic
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int retries = ApiConfig.maxRetries,
  }) async {
    int attempts = 0;
    while (attempts < retries) {
      try {
        return await _dio.post<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        );
      } catch (e) {
        attempts++;
        if (attempts >= retries) rethrow;
        await Future.delayed(ApiConfig.retryDelay);
      }
    }
    throw Exception('Max retries exceeded');
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

