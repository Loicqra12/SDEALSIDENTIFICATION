import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'api_service.dart';
import 'local_storage_service.dart';

class SyncService {
  static Timer? _syncTimer;
  static StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;
  static bool _isOnline = false;

  // Initialiser le service de synchronisation
  static Future<void> init() async {
    // Vérifier la connectivité initiale
    await _checkConnectivity();

    // Écouter les changements de connectivité
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      _isOnline =
          results.isNotEmpty && results.first != ConnectivityResult.none;
      if (_isOnline) {
        _syncPendingData();
      }
    });

    // Synchronisation périodique (toutes les 5 minutes)
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isOnline) {
        _syncPendingData();
      }
    });
  }

  // Arrêter le service
  static void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  // Vérifier la connectivité
  static Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _isOnline = results.isNotEmpty && results.first != ConnectivityResult.none;
  }

  // Synchroniser les données en attente
  static Future<void> _syncPendingData() async {
    if (!_isOnline) return;

    try {
      // Vérifier la connectivité au serveur
      final isServerReachable = await ApiService.checkConnectivity();
      if (!isServerReachable) return;

      // Récupérer les recensements en attente
      final pendingRecensements =
          await LocalStorageService.getPendingRecensements();
      if (pendingRecensements.isEmpty) return;

      print('Synchronisation de ${pendingRecensements.length} recensements...');

      // Synchroniser les recensements
      final result = await ApiService.syncPendingRecensements(
        pendingRecensements,
      );

      if (result['success']) {
        final successCount = result['successCount'] as int;
        final errorCount = result['errorCount'] as int;

        print(
          'Synchronisation terminée: $successCount succès, $errorCount erreurs',
        );

        // Marquer les recensements synchronisés
        final results = result['results'] as List<Map<String, dynamic>>;
        for (int i = 0; i < results.length; i++) {
          if (results[i]['success']) {
            final recensement = pendingRecensements[i];
            final backendId = results[i]['data']['id']?.toString();
            if (backendId != null) {
              await LocalStorageService.markAsSynced(recensement['id']);
            }
          }
        }
      }
    } catch (e) {
      print('Erreur de synchronisation: $e');
    }
  }

  // Synchronisation manuelle
  static Future<Map<String, dynamic>> manualSync() async {
    try {
      // Vérifier la connectivité
      if (!_isOnline) {
        return {'success': false, 'message': 'Aucune connexion internet'};
      }

      final isServerReachable = await ApiService.checkConnectivity();
      if (!isServerReachable) {
        return {'success': false, 'message': 'Serveur inaccessible'};
      }

      // Récupérer les recensements en attente
      final pendingRecensements =
          await LocalStorageService.getPendingRecensements();
      if (pendingRecensements.isEmpty) {
        return {
          'success': true,
          'message': 'Aucune donnée à synchroniser',
          'count': 0,
        };
      }

      // Synchroniser
      final result = await ApiService.syncPendingRecensements(
        pendingRecensements,
      );

      if (result['success']) {
        final successCount = result['successCount'] as int;
        final errorCount = result['errorCount'] as int;

        // Marquer les recensements synchronisés
        final results = result['results'] as List<Map<String, dynamic>>;
        for (int i = 0; i < results.length; i++) {
          if (results[i]['success']) {
            final recensement = pendingRecensements[i];
            final backendId = results[i]['data']['id']?.toString();
            if (backendId != null) {
              await LocalStorageService.markAsSynced(recensement['id']);
            }
          }
        }

        return {
          'success': true,
          'message': 'Synchronisation terminée',
          'successCount': successCount,
          'errorCount': errorCount,
          'total': pendingRecensements.length,
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur de synchronisation: ${result['error']}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Obtenir le statut de synchronisation
  static Future<Map<String, dynamic>> getSyncStatus() async {
    final pendingRecensements =
        await LocalStorageService.getPendingRecensements();
    final stats = await LocalStorageService.getLocalStats();

    return {
      'isOnline': _isOnline,
      'pendingCount': pendingRecensements.length,
      'totalRecensements': stats['totalRecensements'],
      'syncedRecensements': stats['syncedRecensements'],
      'lastSync': await LocalStorageService.getSetting<String>('lastSync'),
    };
  }

  // Forcer la synchronisation
  static Future<void> forceSync() async {
    await _syncPendingData();
    await LocalStorageService.saveSetting(
      'lastSync',
      DateTime.now().toIso8601String(),
    );
  }
}
