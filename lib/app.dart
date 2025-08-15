import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/localization/language_provider.dart';
import 'package:bbd_limited/screens/main_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: languageState.locale,
      localizationsDelegates: [
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
    );
  }
}
