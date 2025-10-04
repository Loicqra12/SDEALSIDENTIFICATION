import 'package:shared_preferences/shared_preferences.dart';

class PointsService {
  static const String _pointsKey = 'user_points';
  static const String _levelKey = 'user_level';
  static const String _badgesKey = 'user_badges';
  static const String _totalRecensementsKey = 'total_recensements';

  // Points par action
  static const int pointsPerRecensement = 10;
  static const int pointsPerPhoto = 5;
  static const int pointsPerLocation = 3;
  static const int pointsPerCompleteForm = 15;
  static const int bonusPointsFirstRecensement = 50;
  static const int bonusPointsStreak = 25; // Pour 5 recensements consécutifs

  // Seuils de niveaux
  static const List<int> levelThresholds = [
    0, // Niveau 1
    100, // Niveau 2
    250, // Niveau 3
    500, // Niveau 4
    1000, // Niveau 5
    2000, // Niveau 6
    3500, // Niveau 7
    5000, // Niveau 8
    7500, // Niveau 9
    10000, // Niveau 10
  ];

  // Badges disponibles
  static const Map<String, BadgeInfo> availableBadges = {
    'first_recensement': BadgeInfo(
      name: 'Premier Pas',
      description: 'Premier recensement effectué',
      icon: '🎯',
      pointsRequired: 0,
      condition: 'first_recensement',
    ),
    'explorer': BadgeInfo(
      name: 'Explorateur',
      description: '10 recensements effectués',
      icon: '🗺️',
      pointsRequired: 100,
      condition: 'recensements_count',
      conditionValue: 10,
    ),
    'photographer': BadgeInfo(
      name: 'Photographe',
      description: '50 photos prises',
      icon: '📸',
      pointsRequired: 250,
      condition: 'photos_count',
      conditionValue: 50,
    ),
    'local_expert': BadgeInfo(
      name: 'Expert Local',
      description: '100 recensements dans votre région',
      icon: '🏘️',
      pointsRequired: 500,
      condition: 'local_recensements',
      conditionValue: 100,
    ),
    'streak_master': BadgeInfo(
      name: 'Maître de la Série',
      description: '10 recensements consécutifs',
      icon: '🔥',
      pointsRequired: 200,
      condition: 'streak',
      conditionValue: 10,
    ),
    'data_collector': BadgeInfo(
      name: 'Collecteur de Données',
      description: '500 recensements effectués',
      icon: '📊',
      pointsRequired: 2000,
      condition: 'recensements_count',
      conditionValue: 500,
    ),
    'legend': BadgeInfo(
      name: 'Légende',
      description: '1000 recensements effectués',
      icon: '👑',
      pointsRequired: 5000,
      condition: 'recensements_count',
      conditionValue: 1000,
    ),
  };

  // Ajouter des points
  static Future<int> addPoints(String userId, int points, String reason) async {
    final prefs = await SharedPreferences.getInstance();
    final currentPoints = prefs.getInt(_pointsKey) ?? 0;
    final newPoints = currentPoints + points;

    await prefs.setInt(_pointsKey, newPoints);

    // Vérifier les badges
    await _checkBadges(userId, newPoints);

    // Vérifier le niveau
    await _updateLevel(newPoints);

    return newPoints;
  }

  // Obtenir les points actuels
  static Future<int> getCurrentPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pointsKey) ?? 0;
  }

  // Obtenir le niveau actuel
  static Future<int> getCurrentLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_levelKey) ?? 1;
  }

  // Obtenir les badges
  static Future<List<String>> getBadges() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_badgesKey) ?? [];
  }

  // Calculer le niveau basé sur les points
  static int calculateLevel(int points) {
    for (int i = levelThresholds.length - 1; i >= 0; i--) {
      if (points >= levelThresholds[i]) {
        return i + 1;
      }
    }
    return 1;
  }

  // Obtenir les points nécessaires pour le prochain niveau
  static int getPointsToNextLevel(int currentPoints) {
    final currentLevel = calculateLevel(currentPoints);
    if (currentLevel >= levelThresholds.length) {
      return 0; // Niveau maximum atteint
    }
    return levelThresholds[currentLevel] - currentPoints;
  }

  // Obtenir le pourcentage de progression vers le prochain niveau
  static double getLevelProgress(int currentPoints) {
    final currentLevel = calculateLevel(currentPoints);
    if (currentLevel >= levelThresholds.length) {
      return 1.0; // Niveau maximum atteint
    }

    final currentLevelPoints = levelThresholds[currentLevel - 1];
    final nextLevelPoints = levelThresholds[currentLevel];
    final progress =
        (currentPoints - currentLevelPoints) /
        (nextLevelPoints - currentLevelPoints);

    return progress.clamp(0.0, 1.0);
  }

  // Calculer les points pour un recensement
  static int calculateRecensementPoints({
    required bool hasPhoto,
    required bool hasLocation,
    required bool isComplete,
    required bool isFirstRecensement,
    required int streakCount,
  }) {
    int points = 0;

    // Points de base
    points += pointsPerRecensement;

    // Bonus photo
    if (hasPhoto) points += pointsPerPhoto;

    // Bonus localisation
    if (hasLocation) points += pointsPerLocation;

    // Bonus formulaire complet
    if (isComplete) points += pointsPerCompleteForm;

    // Bonus premier recensement
    if (isFirstRecensement) points += bonusPointsFirstRecensement;

    // Bonus série
    if (streakCount >= 5) points += bonusPointsStreak;

    return points;
  }

  // Vérifier et attribuer les badges
  static Future<void> _checkBadges(String userId, int totalPoints) async {
    final prefs = await SharedPreferences.getInstance();
    final currentBadges = prefs.getStringList(_badgesKey) ?? [];
    final totalRecensements = prefs.getInt(_totalRecensementsKey) ?? 0;

    for (final entry in availableBadges.entries) {
      final badgeId = entry.key;
      final badgeInfo = entry.value;

      // Vérifier si le badge n'est pas déjà attribué
      if (currentBadges.contains(badgeId)) continue;

      // Vérifier les conditions
      bool shouldAward = false;

      switch (badgeInfo.condition) {
        case 'first_recensement':
          shouldAward = totalRecensements >= 1;
          break;
        case 'recensements_count':
          shouldAward = totalRecensements >= (badgeInfo.conditionValue ?? 0);
          break;
        case 'photos_count':
          // TODO: Implémenter le comptage des photos
          break;
        case 'local_recensements':
          // TODO: Implémenter le comptage des recensements locaux
          break;
        case 'streak':
          // TODO: Implémenter le comptage des séries
          break;
      }

      if (shouldAward) {
        currentBadges.add(badgeId);
        await prefs.setStringList(_badgesKey, currentBadges);
      }
    }
  }

  // Mettre à jour le niveau
  static Future<void> _updateLevel(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final newLevel = calculateLevel(points);
    await prefs.setInt(_levelKey, newLevel);
  }

  // Incrémenter le compteur de recensements
  static Future<void> incrementRecensements() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_totalRecensementsKey) ?? 0;
    await prefs.setInt(_totalRecensementsKey, current + 1);
  }

  // Obtenir le nombre total de recensements
  static Future<int> getTotalRecensements() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalRecensementsKey) ?? 0;
  }

  // Obtenir les informations d'un badge
  static BadgeInfo? getBadgeInfo(String badgeId) {
    return availableBadges[badgeId];
  }

  // Obtenir toutes les informations de progression
  static Future<Map<String, dynamic>> getProgressInfo() async {
    final points = await getCurrentPoints();
    final level = await getCurrentLevel();
    final badges = await getBadges();
    final totalRecensements = await getTotalRecensements();

    return {
      'points': points,
      'level': level,
      'badges': badges,
      'totalRecensements': totalRecensements,
      'pointsToNextLevel': getPointsToNextLevel(points),
      'levelProgress': getLevelProgress(points),
      'badgeCount': badges.length,
    };
  }

  // Réinitialiser les données (pour les tests)
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pointsKey);
    await prefs.remove(_levelKey);
    await prefs.remove(_badgesKey);
    await prefs.remove(_totalRecensementsKey);
  }
}

// Classe pour les informations de badge
class BadgeInfo {
  final String name;
  final String description;
  final String icon;
  final int pointsRequired;
  final String condition;
  final int? conditionValue;

  const BadgeInfo({
    required this.name,
    required this.description,
    required this.icon,
    required this.pointsRequired,
    required this.condition,
    this.conditionValue,
  });
}
