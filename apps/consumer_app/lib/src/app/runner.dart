import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:consumer_app/i18n/translations.g.dart';
import 'package:consumer_app/main.dart';

Future<void> runFlutterApp() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize slang — device locale detection
      await LocaleSettings.useDeviceLocale();

      try {
        await Firebase.initializeApp();
      } catch (e) {
        debugPrint('Firebase initialization failed: $e');
      }

      runApp(
        ProviderScope(
          child: TranslationProvider(
            child: const MyApp(),
          ),
        ),
      );
    },
    (error, stackTrace) {
      // Handle uncaught errors
      debugPrint('Uncaught error: $error');
    },
  );
}
