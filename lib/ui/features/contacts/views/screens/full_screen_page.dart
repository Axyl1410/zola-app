import 'package:flutter/material.dart';

class FullScreenPage extends StatelessWidget {
  const FullScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toàn màn hình')),
      body: const Center(child: Text('Màn hình mới hoàn toàn')),
    );
  }
}
