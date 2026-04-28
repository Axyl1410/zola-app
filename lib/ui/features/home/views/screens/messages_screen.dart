import 'package:flutter/material.dart';

import '../widgets/default_home_app_bar.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({
    super.key,
    required this.counter,
    required this.onIncrement,
  });

  final int counter;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildDefaultHomeAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text('Tin nhan'),
            Text('$counter'),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: onIncrement,
              child: const Text('Click me'),
            ),
          ],
        ),
      ),
    );
  }
}
