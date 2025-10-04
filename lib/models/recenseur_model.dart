import 'package:equatable/equatable.dart';

class RecenseurModel extends Equatable {
  final String id;
  final String nom;
  final String telephone;
  final String? email;
  final String? photoPath;
  final int points;
  final int niveau;
  final List<String> badges;
  final int totalRecensements;
  final DateTime dateInscription;
  final bool isActive;
  final String? token; // Token d'authentification

  const RecenseurModel({
    required this.id,
    required this.nom,
    required this.telephone,
    this.email,
    this.photoPath,
    this.points = 0,
    this.niveau = 1,
    this.badges = const [],
    this.totalRecensements = 0,
    required this.dateInscription,
    this.isActive = true,
    this.token,
  });

  factory RecenseurModel.fromJson(Map<String, dynamic> json) {
    return RecenseurModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      telephone: json['telephone'] as String,
      email: json['email'] as String?,
      photoPath: json['photoPath'] as String?,
      points: json['points'] as int? ?? 0,
      niveau: json['niveau'] as int? ?? 1,
      badges: List<String>.from(json['badges'] as List? ?? []),
      totalRecensements: json['totalRecensements'] as int? ?? 0,
      dateInscription: DateTime.parse(json['dateInscription'] as String),
      isActive: json['isActive'] as bool? ?? true,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'telephone': telephone,
      'email': email,
      'photoPath': photoPath,
      'points': points,
      'niveau': niveau,
      'badges': badges,
      'totalRecensements': totalRecensements,
      'dateInscription': dateInscription.toIso8601String(),
      'isActive': isActive,
      'token': token,
    };
  }

  RecenseurModel copyWith({
    String? id,
    String? nom,
    String? telephone,
    String? email,
    String? photoPath,
    int? points,
    int? niveau,
    List<String>? badges,
    int? totalRecensements,
    DateTime? dateInscription,
    bool? isActive,
    String? token,
  }) {
    return RecenseurModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      photoPath: photoPath ?? this.photoPath,
      points: points ?? this.points,
      niveau: niveau ?? this.niveau,
      badges: badges ?? this.badges,
      totalRecensements: totalRecensements ?? this.totalRecensements,
      dateInscription: dateInscription ?? this.dateInscription,
      isActive: isActive ?? this.isActive,
      token: token ?? this.token,
    );
  }

  // Calculer le niveau basé sur les points
  int calculateNiveau() {
    if (points < 100) return 1;
    if (points < 500) return 2;
    if (points < 1000) return 3;
    if (points < 2000) return 4;
    return 5;
  }

  // Ajouter des points
  RecenseurModel addPoints(int newPoints) {
    final newTotalPoints = points + newPoints;
    return copyWith(points: newTotalPoints, niveau: calculateNiveau());
  }

  // Ajouter un badge
  RecenseurModel addBadge(String badge) {
    if (badges.contains(badge)) return this;
    return copyWith(badges: [...badges, badge]);
  }

  @override
  List<Object?> get props => [
    id,
    nom,
    telephone,
    email,
    photoPath,
    points,
    niveau,
    badges,
    totalRecensements,
    dateInscription,
    isActive,
    token,
  ];
}








