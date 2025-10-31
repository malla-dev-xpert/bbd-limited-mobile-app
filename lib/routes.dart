import 'package:bbd_limited/screens/gestion/basics/basic_home_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/container_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/devises/devices_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/harbor/harbor_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/package_home_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/partner_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/supplier_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/warehouse/warehouse_screen.dart';
import 'package:bbd_limited/screens/gestion/sales/purchase_page.dart';

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
  static const String suppliers = '/suppliers';
  static const String containers = '/container';
  static const String purchase = '/purchase';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
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
        return MaterialPageRoute(builder: (_) => const PackageHomeScreen());
      case harbor:
        return MaterialPageRoute(builder: (_) => HarborScreen());
      case partners:
        return MaterialPageRoute(builder: (_) => const PartnerScreen());
      case suppliers:
        return MaterialPageRoute(builder: (_) => const SupplierScreen());
      case containers:
        return MaterialPageRoute(builder: (_) => const ContainerScreen());
      case purchase:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PurchasePage(
            clientId: args?['clientId'],
            versementId: args?['versementId'],
            invoiceNumber: args?['invoiceNumber'],
            devise: args?['devise'],
            tauxChange: args?['tauxChange'],
            onPurchaseComplete: args?['onPurchaseComplete'],
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
