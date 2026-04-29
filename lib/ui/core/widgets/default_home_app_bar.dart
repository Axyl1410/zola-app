import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

PreferredSizeWidget buildDefaultHomeAppBar({
  String? title,
  List<Widget>? actions,
}) {
  return AppBar(
    backgroundColor: Colors.lightBlue,
    centerTitle: false,
    title: Text(
      title ?? 'Tìm kiếm',
      style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 16),
    ),
    leading: IconButton(
      onPressed: () {},
      icon: const Icon(Icons.search, color: Colors.white),
    ),
    actions:
        actions ??
        [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.image, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
        ],
  );
}
