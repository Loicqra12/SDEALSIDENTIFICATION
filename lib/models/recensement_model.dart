import 'package:equatable/equatable.dart';

class RecensementModel extends Equatable {
  final String id;
  final String type; // 'prestataire', 'freelance', 'vendeur'
  final String nom;
  final String telephone;
  final String? email;
  final String? photoPath;
  final double? latitude;
  final double? longitude;
  final String? adresse;
  final String? ville;
  final String? quartier;
  final String groupe; // 'Métiers', 'Freelance', 'E-marché'
  final String categorie;
  final String service;
  final String? notes;

  // Champs spécifiques au vendeur
  final String? shopName;
  final String? shopDescription;
  final List<String>? productCategories;
  final List<String>? productTypes;
  final String recenseurId; // ID de la personne qui recense
  final String recenseurNom;
  final DateTime dateRecensement;
  final bool synced; // Synchronisé avec le backend
  final String? backendId; // ID dans le backend après sync
  final String status; // 'draft', 'pending', 'synced'
  final String localisation; // Adresse complète formatée

  const RecensementModel({
    required this.id,
    required this.type,
    required this.nom,
    required this.telephone,
    this.email,
    this.photoPath,
    this.latitude,
    this.longitude,
    this.adresse,
    this.ville,
    this.quartier,
    required this.groupe,
    required this.categorie,
    required this.service,
    this.notes,
    this.shopName,
    this.shopDescription,
    this.productCategories,
    this.productTypes,
    required this.recenseurId,
    required this.recenseurNom,
    required this.dateRecensement,
    this.synced = false,
    this.backendId,
    this.status = 'draft',
    this.localisation = '',
  });

  factory RecensementModel.fromJson(Map<String, dynamic> json) {
    return RecensementModel(
      id: json['id'] as String,
      type: json['type'] as String,
      nom: json['nom'] as String,
      telephone: json['telephone'] as String,
      email: json['email'] as String?,
      photoPath: json['photoPath'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      adresse: json['adresse'] as String?,
      ville: json['ville'] as String?,
      quartier: json['quartier'] as String?,
      groupe: json['groupe'] as String,
      categorie: json['categorie'] as String,
      service: json['service'] as String,
      notes: json['notes'] as String?,
      shopName: json['shopName'] as String?,
      shopDescription: json['shopDescription'] as String?,
      productCategories:
          json['productCategories'] != null
              ? List<String>.from(json['productCategories'])
              : null,
      productTypes:
          json['productTypes'] != null
              ? List<String>.from(json['productTypes'])
              : null,
      recenseurId: json['recenseurId'] as String,
      recenseurNom: json['recenseurNom'] as String,
      dateRecensement: DateTime.parse(json['dateRecensement'] as String),
      synced: json['synced'] as bool? ?? false,
      backendId: json['backendId'] as String?,
      status: json['status'] as String? ?? 'draft',
      localisation: json['localisation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'nom': nom,
      'telephone': telephone,
      'email': email,
      'photoPath': photoPath,
      'latitude': latitude,
      'longitude': longitude,
      'adresse': adresse,
      'ville': ville,
      'quartier': quartier,
      'groupe': groupe,
      'categorie': categorie,
      'service': service,
      'notes': notes,
      'shopName': shopName,
      'shopDescription': shopDescription,
      'productCategories': productCategories,
      'productTypes': productTypes,
      'recenseurId': recenseurId,
      'recenseurNom': recenseurNom,
      'dateRecensement': dateRecensement.toIso8601String(),
      'synced': synced,
      'backendId': backendId,
      'status': status,
      'localisation': localisation,
    };
  }

  RecensementModel copyWith({
    String? id,
    String? type,
    String? nom,
    String? telephone,
    String? email,
    String? photoPath,
    double? latitude,
    double? longitude,
    String? adresse,
    String? ville,
    String? quartier,
    String? groupe,
    String? categorie,
    String? service,
    String? notes,
    String? shopName,
    String? shopDescription,
    List<String>? productCategories,
    List<String>? productTypes,
    String? recenseurId,
    String? recenseurNom,
    DateTime? dateRecensement,
    bool? synced,
    String? backendId,
    String? status,
    String? localisation,
  }) {
    return RecensementModel(
      id: id ?? this.id,
      type: type ?? this.type,
      nom: nom ?? this.nom,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      photoPath: photoPath ?? this.photoPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      adresse: adresse ?? this.adresse,
      ville: ville ?? this.ville,
      quartier: quartier ?? this.quartier,
      groupe: groupe ?? this.groupe,
      categorie: categorie ?? this.categorie,
      service: service ?? this.service,
      notes: notes ?? this.notes,
      shopName: shopName ?? this.shopName,
      shopDescription: shopDescription ?? this.shopDescription,
      productCategories: productCategories ?? this.productCategories,
      productTypes: productTypes ?? this.productTypes,
      recenseurId: recenseurId ?? this.recenseurId,
      recenseurNom: recenseurNom ?? this.recenseurNom,
      dateRecensement: dateRecensement ?? this.dateRecensement,
      synced: synced ?? this.synced,
      backendId: backendId ?? this.backendId,
      status: status ?? this.status,
      localisation: localisation ?? this.localisation,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    nom,
    telephone,
    email,
    photoPath,
    latitude,
    longitude,
    adresse,
    ville,
    quartier,
    groupe,
    categorie,
    service,
    notes,
    shopName,
    shopDescription,
    productCategories,
    productTypes,
    recenseurId,
    recenseurNom,
    dateRecensement,
    synced,
    backendId,
    status,
    localisation,
  ];
}
