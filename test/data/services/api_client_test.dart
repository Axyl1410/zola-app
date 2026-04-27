import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zola/data/repositories/auth_session_repository.dart';
import 'package:zola/data/services/api_client.dart';
import 'package:zola/data/services/secure_storage_service.dart';

void main() {
  group('ApiClient', () {
    test('get attaches bearer token when available', () async {
      late http.Request capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response('{}', 200);
      });
      final authRepository = _FakeAuthSessionRepository(
        tokenToReturn: 'abc-token',
      );
      final apiClient = ApiClient(
        authSessionRepository: authRepository,
        httpClient: mockClient,
      );

      await apiClient.get(Uri.parse('https://example.com/profile'));

      expect(
        capturedRequest.headers[HttpHeaders.authorizationHeader],
        'Bearer abc-token',
      );
      expect(capturedRequest.headers[HttpHeaders.acceptHeader], 'application/json');
    });

    test('get does not attach authorization header when token is null', () async {
      late http.Request capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response('{}', 200);
      });
      final authRepository = _FakeAuthSessionRepository(tokenToReturn: null);
      final apiClient = ApiClient(
        authSessionRepository: authRepository,
        httpClient: mockClient,
      );

      await apiClient.get(Uri.parse('https://example.com/public'));

      expect(
        capturedRequest.headers.containsKey(HttpHeaders.authorizationHeader),
        isFalse,
      );
      expect(capturedRequest.headers[HttpHeaders.acceptHeader], 'application/json');
    });

    test('post encodes map body and sets json content-type', () async {
      late http.Request capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response('{}', 201);
      });
      final authRepository = _FakeAuthSessionRepository(
        tokenToReturn: 'post-token',
      );
      final apiClient = ApiClient(
        authSessionRepository: authRepository,
        httpClient: mockClient,
      );

      await apiClient.post(
        Uri.parse('https://example.com/messages'),
        body: {'title': 'hello'},
      );

      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.body, jsonEncode({'title': 'hello'}));
      expect(
        capturedRequest.headers[HttpHeaders.contentTypeHeader],
        'application/json',
      );
      expect(
        capturedRequest.headers[HttpHeaders.authorizationHeader],
        'Bearer post-token',
      );
    });

    test('custom headers are preserved while defaults are applied', () async {
      late http.Request capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response('{}', 200);
      });
      final authRepository = _FakeAuthSessionRepository(tokenToReturn: null);
      final apiClient = ApiClient(
        authSessionRepository: authRepository,
        httpClient: mockClient,
      );

      await apiClient.put(
        Uri.parse('https://example.com/items/1'),
        headers: const {'x-request-id': 'req-1'},
        body: {'name': 'item'},
      );

      expect(capturedRequest.method, 'PUT');
      expect(capturedRequest.headers['x-request-id'], 'req-1');
      expect(capturedRequest.headers[HttpHeaders.acceptHeader], 'application/json');
      expect(
        capturedRequest.headers[HttpHeaders.contentTypeHeader],
        'application/json',
      );
    });
  });
}

class _FakeAuthSessionRepository extends AuthSessionRepository {
  _FakeAuthSessionRepository({required this.tokenToReturn})
    : super(secureStorageService: _FakeSecureStorageService());

  final String? tokenToReturn;

  @override
  Future<String?> getValidToken() async {
    return tokenToReturn;
  }
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService() : super(storage: const FlutterSecureStorage());
}
