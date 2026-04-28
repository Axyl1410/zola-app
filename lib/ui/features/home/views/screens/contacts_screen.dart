import 'package:flutter/material.dart';

import 'full_screen_page.dart';
import '../widgets/default_home_app_bar.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildDefaultHomeAppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Danh ba',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FullScreenPage()),
                );
              },
              child: const Text('Open full screen'),
            ),
          ],
        ),
      ),
    );
  }
}
