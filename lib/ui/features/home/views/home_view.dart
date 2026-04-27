import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'screens/business_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/school_screen.dart';
import 'screens/settings_screen.dart';

class HomeView extends HookWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = useState(0);
    final selectedIndex = useState(0);

    final pages = <Widget>[
      HomeScreen(counter: counter.value, onIncrement: () => counter.value++),
      const BusinessScreen(),
      const SchoolScreen(),
      const SettingsScreen(),
      const ProfileScreen(),
    ];

    final safeIndex = selectedIndex.value.clamp(0, pages.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        selectedItemColor: Colors.lightBlue,
        unselectedItemColor: Colors.grey,
        currentIndex: safeIndex,
        onTap: (index) => selectedIndex.value = index,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Business',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'School'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
