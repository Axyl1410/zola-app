import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_status_view_model.dart';

final authStatusNotifierProvider =
    NotifierProvider<AuthStatusNotifier, AuthStatus>(AuthStatusNotifier.new);
