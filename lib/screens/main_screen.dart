import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/models/user.dart';
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
  final AuthService _authService = AuthService();
  User? _user;
  List<Widget> _screens = [];

  bool get isAdmin {
    final permissions = _user?.role?.permissions ?? [];
    return permissions.contains('IS_ADMIN');
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = await _authService.getUserInfo();
    setState(() {
      _user = user;

      _screens = [
        const HomeScreen(),
        if (isAdmin) const ManageUsersScreen(),
        const ReportHomeScreen(),
        const AccountHomeScreen(),
        const ExportHomeScreen(),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        backgroundColor: Colors.transparent,
        color: const Color(0xFF1A1E49),
        buttonBackgroundColor: const Color(0xFF1A1E49),
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          const Icon(Icons.home_rounded, size: 30, color: Colors.white),
          if (isAdmin)
            const Icon(
              Icons.supervised_user_circle,
              size: 30,
              color: Colors.white,
            ),
          const Icon(Icons.assessment, size: 30, color: Colors.white),
          const Icon(Icons.account_balance, size: 30, color: Colors.white),
          const Icon(Icons.person, size: 30, color: Colors.white),
        ],
      ),
    );
  }
}
