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
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
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
        color: const Color(0xFF13084F),
        buttonBackgroundColor: const Color(0xFF13084F),
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          Icon(Icons.home_rounded, size: 30, color: Colors.white),
          Icon(Icons.supervised_user_circle, size: 30, color: Colors.white),
          Icon(Icons.assessment, size: 30, color: Colors.white),
          Icon(Icons.account_balance, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
      ),
    );
  }
}
