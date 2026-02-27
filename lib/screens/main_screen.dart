import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/access_control_service.dart';
import 'package:bbd_limited/models/user.dart';
import 'package:bbd_limited/screens/gestion/accounts/account_home_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/basic_home_screen.dart';
import 'package:bbd_limited/screens/gestion/profil/profil_screen.dart';
import 'package:bbd_limited/screens/gestion/sales/sales_home_screen.dart';
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
  final AccessControlService _accessService = AccessControlService();
  User? _user;
  List<Widget> _screens = [];
  List<Widget> _navItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = await _authService.getUserInfo();

    // Si l'utilisateur est null (token invalide/expiré), rediriger vers login
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    if (mounted) {
      setState(() {
        _user = user;
        _buildNavigation(user);
      });
    }
  }

  void _buildNavigation(User user) {
    _screens = [];
    _navItems = [];

    _screens.add(const HomeScreen());
    _navItems
        .add(const Icon(Icons.home_rounded, size: 30, color: Colors.white));

    if (_accessService.canShowAdminTab(user)) {
      _screens.add(ManageUsersScreen());
      _navItems.add(const Icon(
        Icons.supervised_user_circle,
        size: 30,
        color: Colors.white,
      ));
    }

    if (_accessService.canShowSalesTab(user)) {
      _screens.add(const SalesHomeScreen());
      _navItems
          .add(const Icon(Icons.assessment, size: 30, color: Colors.white));
    }

    if (_accessService.canShowAccountsTab(user)) {
      _screens.add(AccountHomeScreen());
      _navItems.add(
          const Icon(Icons.account_balance, size: 30, color: Colors.white));
    }

    _screens.add(ProfilePage(user: user));
    _navItems.add(const Icon(Icons.person, size: 30, color: Colors.white));
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
        backgroundColor: Colors.white,
        color: const Color(0xFF1A1E49),
        buttonBackgroundColor: const Color(0xFF1A1E49),
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: _navItems,
      ),
    );
  }
}
