import 'package:flutter/material.dart';
import 'package:zola/data/repositories/google_auth_repository.dart';
import 'package:zola/domain/models/google_auth_result.dart';

class MessagesViewModel extends ChangeNotifier {
  MessagesViewModel({required GoogleAuthRepository googleAuthRepository})
    : _googleAuthRepository = googleAuthRepository;

  final GoogleAuthRepository _googleAuthRepository;

  bool _isLoading = false;
  String? _errorMessage;
  GoogleAuthResult? _authResult;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  GoogleAuthResult? get authResult => _authResult;

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _authResult = await _googleAuthRepository.signInWithGoogle();
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
