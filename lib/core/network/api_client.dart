import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../auth/app_session.dart';
import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  /// Evita ráfagas de peticiones cuando el backend no responde.
  static DateTime? lastConnectionFailureAt;
  static const connectionCooldown = Duration(seconds: 8);

  static bool get isInConnectionCooldown {
    final last = lastConnectionFailureAt;
    if (last == null) return false;
    return DateTime.now().difference(last) < connectionCooldown;
  }

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    if (isInConnectionCooldown) {
      throw const ApiException(
        'Sin conexión al servidor. Inicia el backend: cd backend && pnpm run dev',
      );
    }
    try {
      final response = await request();
      lastConnectionFailureAt = null;
      return response;
    } on http.ClientException catch (_) {
      _markConnectionFailure();
      rethrow;
    }
  }

  void _markConnectionFailure() {
    lastConnectionFailureAt = DateTime.now();
    if (kDebugMode) {
      debugPrint(
        'API no disponible en ${ApiConfig.baseUrl}. Ejecuta: cd backend && pnpm run dev',
      );
    }
  }

  ApiException _connectionError() => const ApiException(
        'No se pudo conectar al servidor. Inicia el backend: cd backend && pnpm run dev',
      );

  Map<String, String> _headers({bool auth = false}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final sessionToken = AppSession.token;
      if (sessionToken == null || sessionToken.isEmpty) {
        throw const ApiException(
          'Sesión expirada. Inicia sesión de nuevo.',
          statusCode: 401,
        );
      }
      headers['Authorization'] = 'Bearer $sessionToken';
    }
    return headers;
  }

  Future<dynamic> get(String path, {bool auth = true}) async {
    try {
      final response = await _send(
        () => http.get(_uri(path), headers: _headers(auth: auth)),
      );
      return _parseResponse(response);
    } on http.ClientException {
      throw _connectionError();
    }
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    try {
      final response = await _send(
        () => http.post(
          _uri(path),
          headers: _headers(auth: auth),
          body: jsonEncode(body),
        ),
      );
      return _parseResponse(response);
    } on http.ClientException {
      throw _connectionError();
    }
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final response = await _send(
        () => http.put(
          _uri(path),
          headers: _headers(auth: auth),
          body: jsonEncode(body),
        ),
      );
      return _parseResponse(response);
    } on http.ClientException {
      throw _connectionError();
    }
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final response = await _send(
        () => http.patch(
          _uri(path),
          headers: _headers(auth: auth),
          body: jsonEncode(body),
        ),
      );
      return _parseResponse(response) as Map<String, dynamic>;
    } on http.ClientException {
      throw _connectionError();
    }
  }

  Future<void> delete(String path, {bool auth = true}) async {
    try {
      final response = await _send(
        () => http.delete(_uri(path), headers: _headers(auth: auth)),
      );
      _parseResponse(response);
    } on http.ClientException {
      throw _connectionError();
    }
  }

  dynamic _parseResponse(http.Response response) {
    dynamic data;
    if (response.body.isNotEmpty) {
      data = jsonDecode(response.body);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data ?? <String, dynamic>{};
    }

    final errorMap = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final message =
        errorMap['error'] as String? ??
        'Error del servidor (${response.statusCode})';
    throw ApiException(message, statusCode: response.statusCode);
  }
}
