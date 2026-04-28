import 'package:flutter/material.dart';

import '../../../../di/injector.dart';
import '../view_models/messages_view_model.dart';
import 'screens/contacts_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/personal_screen.dart';
import 'screens/wall_screen.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _counter = 0;
  int _selectedIndex = 0;
  late final MessagesViewModel _messagesViewModel;

  @override
  void initState() {
    super.initState();
    _messagesViewModel = sl<MessagesViewModel>();
  }

  @override
  void dispose() {
    _messagesViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      MessagesScreen(
        counter: _counter,
        onIncrement: () => setState(() => _counter++),
        viewModel: _messagesViewModel,
      ),
      const ContactsScreen(),
      const DiscoverScreen(),
      const WallScreen(),
      const PersonalScreen(),
    ];

    final safeIndex = _selectedIndex.clamp(0, pages.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        selectedItemColor: Colors.lightBlue,
        unselectedItemColor: Colors.grey,
        currentIndex: safeIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            backgroundColor: Colors.white,
            icon: Icon(Icons.chat_outlined),
            label: 'Tin nhắn',
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.white,
            icon: Icon(Icons.perm_contact_calendar_outlined),
            label: 'Danh bạ',
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.white,
            icon: Icon(Icons.grid_view_rounded),
            label: 'Khám phá',
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.white,
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Tường nhà',
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.white,
            icon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
