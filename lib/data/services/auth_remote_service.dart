import 'package:http/http.dart' as http;
import 'package:zola/data/config/api_endpoints.dart';
import 'package:zola/data/services/api_client.dart';

class AuthRemoteService {
  AuthRemoteService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<http.Response> signInWithGoogle({
    required String idToken,
    required String accessToken,
  }) {
    return _apiClient.post(
      ApiEndpoints.authSignInSocial(),
      body: <String, dynamic>{
        'provider': 'google',
        'idToken': <String, dynamic>{
          'token': idToken,
          'accessToken': accessToken,
        },
      },
    );
  }

  Future<http.Response> signOut({required String bearerToken}) {
    return _apiClient.post(
      ApiEndpoints.authSignOut(),
      headers: <String, String>{'Authorization': 'Bearer $bearerToken'},
      body: <String, dynamic>{},
    );
  }

  Future<http.Response> getSession({required String bearerToken}) {
    return _apiClient.get(
      ApiEndpoints.authGetSession(),
      headers: <String, String>{'Authorization': 'Bearer $bearerToken'},
    );
  }
}
