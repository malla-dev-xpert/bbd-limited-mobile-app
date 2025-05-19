import 'package:bbd_limited/screens/gestion/basics/basic_home_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/container_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/devises/devices_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/harbor/harbor_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/packages/package_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/partner_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/warehouse/warehouse_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/expedition/expedition_home_screen.dart';

import 'package:bbd_limited/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';

class Routes {
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String main = '/welcome';
  static const String devises = '/devises';
  static const String warehouse = '/warehouse';
  static const String package = '/package';
  static const String harbor = '/harbor';
  static const String partners = '/partners';
  static const String containers = '/container';
  static const String expedition = '/expedition';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const Login());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPassword());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case main:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case devises:
        return MaterialPageRoute(builder: (_) => const DevicesScreen());
      case warehouse:
        return MaterialPageRoute(builder: (_) => const WarehouseScreen());
      case package:
        return MaterialPageRoute(builder: (_) => PackageScreen());
      case harbor:
        return MaterialPageRoute(builder: (_) => HarborScreen());
      case partners:
        return MaterialPageRoute(builder: (_) => PartnerScreen());
      case containers:
        return MaterialPageRoute(builder: (_) => ContainerScreen());
      case expedition:
        return MaterialPageRoute(builder: (_) => ExpeditionHomeScreen());
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}
