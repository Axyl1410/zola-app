import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zola/ui/core/widgets/default_home_app_bar.dart';
import 'package:zola/ui/features/auth/view_models/current_user_provider.dart';

class WallScreen extends StatefulWidget {
  const WallScreen({super.key});

  @override
  State<WallScreen> createState() => _WallScreenState();
}

class _WallScreenState extends State<WallScreen> {
  final List<WallItem> _wallItems = [
    WallItem(name: 'Ảnh'),
    WallItem(name: 'Video'),
    WallItem(name: 'Album'),
    WallItem(name: 'Nền chữ'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildDefaultHomeAppBar(),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Consumer(
                    builder: (context, ref, child) {
                      final user = ref
                          .watch(currentUserProvider)
                          .maybeWhen(
                            data: (value) => value,
                            orElse: () => null,
                          );
                      final imageUrl = user?.image?.trim();
                      final hasImage = imageUrl != null && imageUrl.isNotEmpty;
                      return Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          image: hasImage
                              ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          shape: BoxShape.circle,
                        ),
                        child: hasImage
                            ? null
                            : const Icon(Icons.person, color: Colors.grey),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Hôm nay của bạn thế nào?',
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 35,
                child: ListView.separated(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final wallItem = _wallItems[index];

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.all(
                          Radius.circular(32),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Text(
                            wallItem.name,
                            style: GoogleFonts.beVietnamPro(fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (context, index) {
                    return const SizedBox(width: 8);
                  },
                  itemCount: _wallItems.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WallItem {
  const WallItem({required this.name, this.icon, this.color});

  final String name;
  final String? icon;
  final String? color;
}
