import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/default_home_app_bar.dart';

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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildDefaultHomeAppBar(),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1774050952646-a850ad28ad6f?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                        ),
                        fit: BoxFit.cover,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Hôm nay của bạn thế nào?',
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final wallItem = _wallItems[index];

                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                      ),
                      child: Row(
                        children: <Widget>[
                          Text(
                            wallItem.name,
                            style: GoogleFonts.beVietnamPro(),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (context, index) {
                    return SizedBox(width: 8);
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
