import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes.dart';
import 'package:bbd_limited/core/constants/responsive_text_theme.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/localization/language_provider.dart';
import 'package:bbd_limited/screens/main_screen.dart';
import 'package:bbd_limited/widgets/common/keyboard_dismiss_wrapper.dart';

class App extends ConsumerWidget {
  const App({super.key});

  static final ThemeData _lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A1E49),
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
  );

  static final ThemeData _darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A1E49),
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageProvider);

    return KeyboardDismissWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: languageState.locale,
        theme: _lightTheme,
        darkTheme: _darkTheme,
        builder: (context, child) {
          final theme = Theme.of(context);
          final base = theme.brightness == Brightness.dark ? _darkTheme : _lightTheme;
          return Theme(
            data: base.copyWith(
              textTheme: buildResponsiveTextTheme(context, base.colorScheme),
            ),
            child: child!,
          );
        },
        themeMode: ThemeMode.system,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr'),
          Locale('en'),
          Locale('zh'),
        ],
        home: FutureBuilder<bool>(
          future: AppLocalizations(languageState.locale).load(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Erreur de chargement: ${snapshot.error}'),
                ),
              );
            }

            return const MainScreen();
          },
        ),
        onGenerateRoute: Routes.generateRoute,
      ),
    );
  }
}
