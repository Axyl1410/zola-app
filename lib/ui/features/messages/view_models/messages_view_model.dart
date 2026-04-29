import 'package:flutter/material.dart';
import 'package:zola/data/repositories/auth_backend_repository.dart';
import 'package:zola/data/repositories/google_auth_repository.dart';
import 'package:zola/domain/models/google_auth_result.dart';

class MessagesViewModel extends ChangeNotifier {
  MessagesViewModel({
    required GoogleAuthRepository googleAuthRepository,
    required AuthBackendRepository authBackendRepository,
  }) : _googleAuthRepository = googleAuthRepository,
       _authBackendRepository = authBackendRepository;

  final GoogleAuthRepository _googleAuthRepository;
  final AuthBackendRepository _authBackendRepository;

  bool _isLoading = false;
  String? _errorMessage;
  GoogleAuthResult? _authResult;
  int? _backendStatusCode;
  String? _backendResponseBody;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  GoogleAuthResult? get authResult => _authResult;
  int? get backendStatusCode => _backendStatusCode;
  String? get backendResponseBody => _backendResponseBody;

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    _backendStatusCode = null;
    _backendResponseBody = null;
    notifyListeners();

    try {
      _authResult = await _googleAuthRepository.signInWithGoogle();
      final backendResult = await _authBackendRepository.signInWithGoogle(
        _authResult!,
      );
      _backendStatusCode = backendResult.statusCode;
      _backendResponseBody = backendResult.body;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearAuthResult() {
    _authResult = null;
    notifyListeners();
  }
}
