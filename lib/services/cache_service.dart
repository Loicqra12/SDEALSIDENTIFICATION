import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service de cache pour les données API
class CacheService {
  static const String _cachePrefix = 'cache_';
  static const String _timestampSuffix = '_timestamp';
  static const Duration _defaultCacheDuration = Duration(hours: 24);

  /// Sauvegarder des données en cache
  static Future<void> saveCache(
    String key,
    dynamic data, {
    Duration? duration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$cacheKey$_timestampSuffix';

      // Sauvegarder les données
      await prefs.setString(cacheKey, jsonEncode(data));

      // Sauvegarder le timestamp d'expiration
      final expirationTime =
          DateTime.now().add(duration ?? _defaultCacheDuration);
      await prefs.setString(timestampKey, expirationTime.toIso8601String());

      print(
          '✅ Cache sauvegardé: $key (expire dans ${duration ?? _defaultCacheDuration})');
    } catch (e) {
      print('❌ Erreur sauvegarde cache: $e');
    }
  }

  /// Récupérer des données du cache
  static Future<dynamic> getCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$cacheKey$_timestampSuffix';

      // Vérifier si le cache existe
      final cachedData = prefs.getString(cacheKey);
      final timestampString = prefs.getString(timestampKey);

      if (cachedData == null || timestampString == null) {
        print('ℹ️  Cache manquant: $key');
        return null;
      }

      // Vérifier si le cache est expiré
      final expirationTime = DateTime.parse(timestampString);
      if (DateTime.now().isAfter(expirationTime)) {
        print('⚠️  Cache expiré: $key');
        await clearCache(key);
        return null;
      }

      print('✅ Cache valide récupéré: $key');
      return jsonDecode(cachedData);
    } catch (e) {
      print('❌ Erreur récupération cache: $e');
      return null;
    }
  }

  /// Vérifier si le cache est valide
  static Future<bool> isCacheValid(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$cacheKey$_timestampSuffix';

      final timestampString = prefs.getString(timestampKey);
      if (timestampString == null) return false;

      final expirationTime = DateTime.parse(timestampString);
      return DateTime.now().isBefore(expirationTime);
    } catch (e) {
      return false;
    }
  }

  /// Supprimer un cache spécifique
  static Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$cacheKey$_timestampSuffix';

      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);

      print('🗑️  Cache supprimé: $key');
    } catch (e) {
      print('❌ Erreur suppression cache: $e');
    }
  }

  /// Supprimer tout le cache
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }

      print('🗑️  Tout le cache supprimé');
    } catch (e) {
      print('❌ Erreur suppression cache complet: $e');
    }
  }

  /// Obtenir la taille du cache (nombre d'entrées)
  static Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      int count = 0;
      for (final key in keys) {
        if (key.startsWith(_cachePrefix) && !key.endsWith(_timestampSuffix)) {
          count++;
        }
      }

      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Rafraîchir le cache (supprimer et forcer un nouveau chargement)
  static Future<void> refreshCache(String key) async {
    await clearCache(key);
    print('🔄 Cache rafraîchi: $key');
  }

  // ===== Clés de cache spécifiques pour l'app =====

  /// Cache pour les groupes (Métiers, Freelance, E-marché)
  static const String groupesKey = 'groupes';

  /// Cache pour les catégories par groupe
  /// Utilisation: categoriesPrefix + nomGroupe (ex: "categories_Métiers")
  static const String categoriesPrefix = 'categories_';

  /// Cache pour les services par catégorie
  /// Utilisation: servicesPrefix + categorieId (ex: "services_507f1f77")
  static const String servicesPrefix = 'services_';

  /// Helpers pour clés de cache

  static String getCategoriesCacheKey(String nomGroupe) {
    return '$categoriesPrefix$nomGroupe';
  }

  static String getServicesCacheKey(String categorieId) {
    return '$servicesPrefix$categorieId';
  }
}
