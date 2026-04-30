import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'login_view_model.dart';

final loginNotifierProvider = NotifierProvider<LoginNotifier, LoginState>(
  LoginNotifier.new,
);
