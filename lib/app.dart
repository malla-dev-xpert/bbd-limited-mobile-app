import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/localization/language_provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LanguageProvider(),
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: languageProvider.currentLocale,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr', ''),
              Locale('en', ''),
              Locale('zh', ''),
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1A1E49),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.white,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1A1E49),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.grey[900],
            ),
            themeMode: ThemeMode.system,
            home: const _AutoLoginWrapper(),
            onGenerateRoute: Routes.generateRoute,
          );
        },
      ),
    );
  }
}

class _AutoLoginWrapper extends StatefulWidget {
  const _AutoLoginWrapper();

  @override
  State<_AutoLoginWrapper> createState() => _AutoLoginWrapperState();
}

class _AutoLoginWrapperState extends State<_AutoLoginWrapper> {
  final AuthService _authService = AuthService();
  bool _checking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final token = await _authService.getToken();
    setState(() {
      _isLoggedIn = token != null && token.isNotEmpty;
      _checking = false;
    });
    if (_isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/welcome');
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _checking
            ? const CircularProgressIndicator()
            : const SizedBox.shrink(),
      ),
    );
  }
}
