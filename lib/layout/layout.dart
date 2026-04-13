import 'package:flutter/material.dart';

import '../theme/theme_controller.dart';
import '../screens/home_screen.dart';
import '../screens/alert_screen.dart';
import '../screens/distress_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';

class AppLayout extends StatefulWidget {
  final ThemeController themeController;

  const AppLayout({super.key, required this.themeController});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  int _index = 0;

  void _goToTab(int index) => setState(() => _index = index);

  late final List<Widget> _pages = <Widget>[
    HomeScreen(onNavigate: _goToTab),
    AlertScreen(),
    const DistressScreen(),
    HistoryScreen(),
    SettingsScreen(themeController: widget.themeController),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titleForIndex(_index))),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _goToTab,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.sos_outlined), label: 'Alert'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on_outlined), label: 'Distress'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Emergency Alert';
      case 2:
        return 'Distress Mode';
      case 3:
        return 'Alert History';
      case 4:
        return 'Privacy & Settings';
      default:
        return 'App';
    }
  }
}