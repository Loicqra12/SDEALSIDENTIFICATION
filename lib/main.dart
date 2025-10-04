import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/type_selection_screen.dart';
import 'screens/recensement_form_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'services/local_storage_service.dart';
import 'services/sync_service.dart';
import 'blocs/classification_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Hive pour le stockage local
  await Hive.initFlutter();
  await LocalStorageService.init();

  // Charger les variables d'environnement (optionnel)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Fichier .env non trouvé ou erreur de chargement: $e");
    // Continuer sans le fichier .env
  }

  // Configuration de l'orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialiser le service de synchronisation
  await SyncService.init();

  runApp(const SoutraliRecensementApp());
}

class SoutraliRecensementApp extends StatelessWidget {
  const SoutraliRecensementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ClassificationBloc>(
          create: (context) => ClassificationBloc(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Soutrali Recensement',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          primaryColor: const Color(0xFF1CBF3F),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1CBF3F),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1CBF3F),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1CBF3F),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1CBF3F), width: 2),
            ),
          ),
        ),
        routerConfig: _router,
      ),
    );
  }
}

// Configuration des routes
final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/type-selection',
      builder: (context, state) => const TypeSelectionScreen(),
    ),
    GoRoute(
      path: '/recensement-form',
      builder: (context, state) {
        final type = state.uri.queryParameters['type'] ?? 'prestataire';
        return RecensementFormScreen(type: type);
      },
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
