import 'package:equatable/equatable.dart';

class GroupeModel extends Equatable {
  final String id;
  final String nom;
  final String? description;
  final String? iconPath;

  const GroupeModel({
    required this.id,
    required this.nom,
    this.description,
    this.iconPath,
  });

  factory GroupeModel.fromJson(Map<String, dynamic> json) {
    return GroupeModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      description: json['description'] as String?,
      iconPath: json['iconPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'iconPath': iconPath,
    };
  }

  @override
  List<Object?> get props => [id, nom, description, iconPath];
}

class CategorieModel extends Equatable {
  final String id;
  final String nom;
  final String groupeId;
  final String? description;
  final String? imagePath;

  const CategorieModel({
    required this.id,
    required this.nom,
    required this.groupeId,
    this.description,
    this.imagePath,
  });

  factory CategorieModel.fromJson(Map<String, dynamic> json) {
    return CategorieModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      groupeId: json['groupeId'] as String,
      description: json['description'] as String?,
      imagePath: json['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'groupeId': groupeId,
      'description': description,
      'imagePath': imagePath,
    };
  }

  @override
  List<Object?> get props => [id, nom, groupeId, description, imagePath];
}

class ServiceModel extends Equatable {
  final String id;
  final String nom;
  final String categorieId;
  final String? description;
  final String? imagePath;
  final String? prixMoyen;

  const ServiceModel({
    required this.id,
    required this.nom,
    required this.categorieId,
    this.description,
    this.imagePath,
    this.prixMoyen,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      categorieId: json['categorieId'] as String? ?? '',
      description: json['description'] as String?,
      imagePath: json['imagePath'] as String?,
      prixMoyen: json['prixMoyen'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'categorieId': categorieId,
      'description': description,
      'imagePath': imagePath,
      'prixMoyen': prixMoyen,
    };
  }

  @override
  List<Object?> get props => [
    id,
    nom,
    categorieId,
    description,
    imagePath,
    prixMoyen,
  ];
}

// Modèle pour la structure complète de classification
class ClassificationModel extends Equatable {
  final List<GroupeModel> groupes;
  final List<CategorieModel> categories;
  final List<ServiceModel> services;

  const ClassificationModel({
    required this.groupes,
    required this.categories,
    required this.services,
  });

  factory ClassificationModel.fromJson(Map<String, dynamic> json) {
    return ClassificationModel(
      groupes:
          (json['groupes'] as List)
              .map((g) => GroupeModel.fromJson(g as Map<String, dynamic>))
              .toList(),
      categories:
          (json['categories'] as List)
              .map((c) => CategorieModel.fromJson(c as Map<String, dynamic>))
              .toList(),
      services:
          (json['services'] as List)
              .map((s) => ServiceModel.fromJson(s as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupes': groupes.map((g) => g.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'services': services.map((s) => s.toJson()).toList(),
    };
  }

  // Obtenir les catégories d'un groupe
  List<CategorieModel> getCategoriesByGroupe(String groupeId) {
    return categories.where((c) => c.groupeId == groupeId).toList();
  }

  // Obtenir les services d'une catégorie
  List<ServiceModel> getServicesByCategorie(String categorieId) {
    return services.where((s) => s.categorieId == categorieId).toList();
  }

  // Obtenir la hiérarchie complète
  Map<String, dynamic> getHierarchy() {
    final Map<String, dynamic> hierarchy = {};

    for (final groupe in groupes) {
      final groupeCategories = getCategoriesByGroupe(groupe.id);
      final Map<String, dynamic> categoriesMap = {};

      for (final categorie in groupeCategories) {
        final categorieServices = getServicesByCategorie(categorie.id);
        categoriesMap[categorie.nom] =
            categorieServices.map((s) => s.nom).toList();
      }

      hierarchy[groupe.nom] = categoriesMap;
    }

    return hierarchy;
  }

  @override
  List<Object?> get props => [groupes, categories, services];
}
