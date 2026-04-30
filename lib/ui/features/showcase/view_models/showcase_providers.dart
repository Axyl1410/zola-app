import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'showcase_view_model.dart';

final showcaseNotifierProvider =
    NotifierProvider<ShowcaseNotifier, ShowcaseState>(ShowcaseNotifier.new);
