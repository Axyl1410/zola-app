import 'package:flutter/material.dart';

/// App-wide session bootstrap ([AuthStatus.checking]): use a **linear** bar at the
/// top edge so it reads as system-level progress, not a focal “spinner” in the middle.
///
/// For feature screens and **section** loads (tabs, cards, async blocks), prefer
/// [CircularProgressIndicator] centered or inline — see Material guidelines for
/// indeterminate progress in content areas.
class LinearLoadingScaffoldBody extends StatelessWidget {
  const LinearLoadingScaffoldBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(),
        Expanded(child: SizedBox()),
      ],
    );
  }
}
