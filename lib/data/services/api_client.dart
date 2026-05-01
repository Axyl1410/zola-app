import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:zola/data/services/auth_token_provider.dart';

class ApiClient {
  ApiClient({
    required AuthTokenProvider authTokenProvider,
    http.Client? httpClient,
  }) : _authTokenProvider = authTokenProvider,
       _httpClient = httpClient ?? http.Client();

  final AuthTokenProvider _authTokenProvider;
  final http.Client _httpClient;

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    final mergedHeaders = await _buildHeaders(headers);
    return _httpClient.get(uri, headers: mergedHeaders);
  }

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final mergedHeaders = await _buildHeaders(
      headers,
      includeJsonContentType: body != null,
    );
    final encodedBody = _encodeJsonBody(body);
    return _httpClient.post(uri, headers: mergedHeaders, body: encodedBody);
  }

  Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final mergedHeaders = await _buildHeaders(
      headers,
      includeJsonContentType: body != null,
    );
    final encodedBody = _encodeJsonBody(body);
    return _httpClient.put(uri, headers: mergedHeaders, body: encodedBody);
  }

  Future<http.Response> delete(Uri uri, {Map<String, String>? headers}) async {
    final mergedHeaders = await _buildHeaders(headers);
    return _httpClient.delete(uri, headers: mergedHeaders);
  }

  Future<Map<String, String>> _buildHeaders(
    Map<String, String>? headers, {
    bool includeJsonContentType = false,
  }) async {
    final mergedHeaders = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
      ...?headers,
    };

    if (includeJsonContentType &&
        !mergedHeaders.containsKey(HttpHeaders.contentTypeHeader)) {
      mergedHeaders[HttpHeaders.contentTypeHeader] = 'application/json';
    }

    final token = await _authTokenProvider.getValidToken();
    if (token != null && token.isNotEmpty) {
      mergedHeaders[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }

    return mergedHeaders;
  }

  String? _encodeJsonBody(Object? body) {
    if (body == null) {
      return null;
    }
    if (body is String) {
      return body;
    }
    return jsonEncode(body);
  }
}
