import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'school_view_model.dart';

final schoolNotifierProvider = NotifierProvider<SchoolNotifier, SchoolState>(
  SchoolNotifier.new,
);
