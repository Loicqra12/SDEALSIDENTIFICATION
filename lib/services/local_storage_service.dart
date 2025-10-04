import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recensement_model.dart';
import '../models/recenseur_model.dart';

class LocalStorageService {
  static const String _recensementsKey = 'recensements';
  static const String _recenseurKey = 'recenseur';
  static const String _pendingSyncKey = 'pending_sync';
  static const String _settingsKey = 'settings';

  // Initialiser le service
  static Future<void> init() async {
    // Pas d'initialisation nécessaire pour SharedPreferences
  }

  // Fermer le service
  static Future<void> dispose() async {
    // Pas de fermeture nécessaire pour SharedPreferences
  }

  // ===== RECENSEMENTS =====

  // Sauvegarder un recensement localement
  static Future<void> saveRecensement(RecensementModel recensement) async {
    final prefs = await SharedPreferences.getInstance();
    final recensements = await getAllRecensements();

    // Mettre à jour ou ajouter le recensement
    final existingIndex = recensements.indexWhere(
      (r) => r.id == recensement.id,
    );
    if (existingIndex >= 0) {
      recensements[existingIndex] = recensement;
    } else {
      recensements.add(recensement);
    }

    // Sauvegarder la liste mise à jour
    final jsonList = recensements.map((r) => r.toJson()).toList();
    await prefs.setString(_recensementsKey, jsonEncode(jsonList));

    // Ajouter à la liste de synchronisation si nécessaire
    if (recensement.status != 'synced') {
      await _addToPendingSync(recensement);
    }
  }

  // Récupérer tous les recensements
  static Future<List<RecensementModel>> getAllRecensements() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_recensementsKey);

    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => RecensementModel.fromJson(json)).toList();
    } catch (e) {
      print('Erreur lors du chargement des recensements: $e');
      return [];
    }
  }

  // Récupérer un recensement par ID
  static Future<RecensementModel?> getRecensementById(String id) async {
    final recensements = await getAllRecensements();
    try {
      return recensements.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  // Supprimer un recensement
  static Future<void> deleteRecensement(String id) async {
    final recensements = await getAllRecensements();
    recensements.removeWhere((r) => r.id == id);

    final prefs = await SharedPreferences.getInstance();
    final jsonList = recensements.map((r) => r.toJson()).toList();
    await prefs.setString(_recensementsKey, jsonEncode(jsonList));

    // Supprimer de la liste de synchronisation
    await _removeFromPendingSync(id);
  }

  // Marquer un recensement comme synchronisé
  static Future<void> markAsSynced(String id) async {
    final recensement = await getRecensementById(id);
    if (recensement != null) {
      final updatedRecensement = recensement.copyWith(
        status: 'synced',
        synced: true,
      );
      await saveRecensement(updatedRecensement);
    }
  }

  // ===== RECENSEUR =====

  // Sauvegarder les informations du recenseur
  static Future<void> saveRecenseur(RecenseurModel recenseur) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recenseurKey, jsonEncode(recenseur.toJson()));
  }

  // Récupérer les informations du recenseur
  static Future<RecenseurModel?> getRecenseur() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_recenseurKey);

    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString);
      return RecenseurModel.fromJson(json);
    } catch (e) {
      print('Erreur lors du chargement du recenseur: $e');
      return null;
    }
  }

  // Mettre à jour les points du recenseur
  static Future<void> updateRecenseurPoints(int points) async {
    final recenseur = await getRecenseur();
    if (recenseur != null) {
      recenseur.addPoints(points);
      await saveRecenseur(recenseur);
    }
  }

  // ===== SYNCHRONISATION =====

  // Récupérer tous les recensements en attente de synchronisation
  static Future<List<Map<String, dynamic>>> getPendingRecensements() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_pendingSyncKey);

    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Erreur lors du chargement des données en attente: $e');
      return [];
    }
  }

  // Vérifier s'il y a des données en attente
  static Future<bool> hasPendingData() async {
    final pending = await getPendingRecensements();
    return pending.isNotEmpty;
  }

  // Nettoyer les données synchronisées
  static Future<void> clearSyncedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingSyncKey);
  }

  // ===== PARAMÈTRES =====

  // Sauvegarder un paramètre
  static Future<void> saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value is String) {
      await prefs.setString('${_settingsKey}_$key', value);
    } else if (value is int) {
      await prefs.setInt('${_settingsKey}_$key', value);
    } else if (value is bool) {
      await prefs.setBool('${_settingsKey}_$key', value);
    } else if (value is double) {
      await prefs.setDouble('${_settingsKey}_$key', value);
    } else {
      await prefs.setString('${_settingsKey}_$key', jsonEncode(value));
    }
  }

  // Récupérer un paramètre
  static Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    final prefs = await SharedPreferences.getInstance();

    if (T == String) {
      return prefs.getString('${_settingsKey}_$key') as T? ?? defaultValue;
    } else if (T == int) {
      return prefs.getInt('${_settingsKey}_$key') as T? ?? defaultValue;
    } else if (T == bool) {
      return prefs.getBool('${_settingsKey}_$key') as T? ?? defaultValue;
    } else if (T == double) {
      return prefs.getDouble('${_settingsKey}_$key') as T? ?? defaultValue;
    } else {
      final jsonString = prefs.getString('${_settingsKey}_$key');
      if (jsonString == null) return defaultValue;
      try {
        return jsonDecode(jsonString) as T? ?? defaultValue;
      } catch (e) {
        return defaultValue;
      }
    }
  }

  // ===== STATISTIQUES =====

  // Obtenir les statistiques locales
  static Future<Map<String, dynamic>> getLocalStats() async {
    final allRecensements = await getAllRecensements();
    final pendingCount = await getPendingRecensements().then(
      (list) => list.length,
    );

    return {
      'totalRecensements': allRecensements.length,
      'pendingSync': pendingCount,
      'synced': allRecensements.where((r) => r.status == 'synced').length,
      'draft': allRecensements.where((r) => r.status == 'draft').length,
    };
  }

  // ===== UTILITAIRES =====

  // Vider toutes les données (pour les tests ou reset)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recensementsKey);
    await prefs.remove(_recenseurKey);
    await prefs.remove(_pendingSyncKey);

    // Supprimer tous les paramètres
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_settingsKey)) {
        await prefs.remove(key);
      }
    }
  }

  // Obtenir la taille des données stockées
  static Future<int> getStorageSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().length;
  }

  // ===== MÉTHODES PRIVÉES =====

  // Ajouter à la liste de synchronisation
  static Future<void> _addToPendingSync(RecensementModel recensement) async {
    final pending = await getPendingRecensements();
    pending.add(recensement.toJson());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingSyncKey, jsonEncode(pending));
  }

  // Supprimer de la liste de synchronisation
  static Future<void> _removeFromPendingSync(String id) async {
    final pending = await getPendingRecensements();
    pending.removeWhere((item) => item['id'] == id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingSyncKey, jsonEncode(pending));
  }
}
