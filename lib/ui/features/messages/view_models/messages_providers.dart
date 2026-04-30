import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'messages_view_model.dart';

final messagesNotifierProvider =
    NotifierProvider<MessagesNotifier, MessagesState>(MessagesNotifier.new);
