import 'package:flutter/material.dart';
import 'package:zola/ui/features/home/views/screens/full_screen_page.dart';
import '../widgets/default_home_app_bar.dart';

class BusinessScreen extends StatelessWidget {
  const BusinessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildDefaultHomeAppBar(title: 'Business'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Index: Business',
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
