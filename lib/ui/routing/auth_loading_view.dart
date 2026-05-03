import 'package:flutter/material.dart';
import 'package:zola/ui/core/widgets/linear_loading_placeholder.dart';

/// Shown while [AuthStatus.checking] resolves on cold start.
class AuthLoadingView extends StatelessWidget {
  const AuthLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: LinearLoadingScaffoldBody());
  }
}
