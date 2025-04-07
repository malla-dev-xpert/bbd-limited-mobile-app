import 'package:bbd_limited/screens/gestion/accounts/account_home_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/basic_home_screen.dart';
import 'package:bbd_limited/screens/gestion/exportation/export_home_screen.dart';
import 'package:bbd_limited/screens/gestion/report/report_home_screen.dart';
import 'package:bbd_limited/screens/gestion/users/users_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Liste des écrans accessibles via la bottom navigation
  final List<Widget> _screens = [
    const HomeScreen(),
    const ManageUsersScreen(),
    const ReportHomeScreen(),
    const AccountHomeScreen(),
    const ExportHomeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        backgroundColor: Colors.transparent,
        color: Colors.blueAccent,
        buttonBackgroundColor: Colors.white,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.search, size: 30, color: Colors.white),
          Icon(Icons.add, size: 30, color: Colors.white),
          Icon(Icons.notifications, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
      ),
    );
  }
}
