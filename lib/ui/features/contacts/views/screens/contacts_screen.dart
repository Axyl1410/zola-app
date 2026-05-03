import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zola/ui/core/widgets/default_home_app_bar.dart';
import 'package:zola/ui/routing/app_routes.dart';

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
              'Danh bạ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                context.go(AppRoute.homeContactsFull);
              },
              child: const Text('Mở toàn màn hình'),
            ),
          ],
        ),
      ),
    );
  }
}
