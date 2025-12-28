import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/classification_model.dart';
import 'cache_service.dart';

/// 🆕 VERSION SIMPLIFIÉE - API Service pour SDEALSIDENTIFICATION
/// Option C: Utilise les endpoints existants avec champs source, status, recenseur
class ApiService {
  static String get baseUrl =>
      dotenv.env['API_URL'] ?? 'http://localhost:3000/api';
  static int get timeout => int.parse(dotenv.env['API_TIMEOUT'] ?? '30000');

  static Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ═══════════════════════════════════════════════════════════════════════════
  // 📋 CHARGER LES CLASSIFICATIONS (Groupes, Catégories, Services)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Charger les catégories par groupe
  static Future<List<CategorieModel>> getCategoriesByGroupe(
    String nomGroupe,
  ) async {
    try {
      print('🔄 Chargement catégories pour: $nomGroupe');

      // 🆕 Vérifier le cache d'abord
      final cacheKey = CacheService.getCategoriesCacheKey(nomGroupe);
      final cachedData = await CacheService.getCache(cacheKey);
      
      if (cachedData != null && cachedData is List) {
        print('📦 Catégories chargées depuis le cache');
        List<CategorieModel> categories = [];
        for (var json in cachedData) {
          try {
            categories.add(CategorieModel.fromJson(json));
          } catch (e) {
            print('⚠️ Erreur parsing catégorie cachée: $e');
          }
        }
        return categories;
      }

      // Appel API si pas de cache
      final response = await http
          .get(Uri.parse('$baseUrl/categorie'), headers: _defaultHeaders)
          .timeout(Duration(milliseconds: timeout));

      if (response.statusCode == 200) {
        List<dynamic> allCategoriesJson = json.decode(response.body);
        List<CategorieModel> categories = [];
        List<dynamic> categoriesToCache = [];

        for (var json in allCategoriesJson) {
          try {
            String? groupeNom;
            if (json['groupe'] is Map<String, dynamic>) {
              groupeNom = json['groupe']['nomgroupe'] as String?;
            }

            if (groupeNom != null &&
                groupeNom.toLowerCase() == nomGroupe.toLowerCase()) {
              categories.add(CategorieModel.fromJson(json));
              categoriesToCache.add(json);
            }
          } catch (e) {
            print('⚠️ Erreur parsing catégorie: $e');
          }
        }

        // 🆕 Sauvegarder en cache
        if (categoriesToCache.isNotEmpty) {
          await CacheService.saveCache(
            cacheKey,
            categoriesToCache,
            duration: const Duration(hours: 24),
          );
        }

        print('✅ ${categories.length} catégories chargées');
        return categories;
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur getCategoriesByGroupe: $e');
      return [];
    }
  }

  /// Charger les services par catégorie
  static Future<List<ServiceModel>> getServicesByCategorie(
    String categorieId,
  ) async {
    try {
      print('🔄 Chargement services pour catégorie: $categorieId');

      // 🆕 Vérifier le cache d'abord
      final cacheKey = CacheService.getServicesCacheKey(categorieId);
      final cachedData = await CacheService.getCache(cacheKey);
      
      if (cachedData != null && cachedData is List) {
        print('📦 Services chargés depuis le cache');
        List<ServiceModel> services = [];
        for (var json in cachedData) {
          try {
            services.add(ServiceModel.fromJson(json));
          } catch (e) {
            print('⚠️ Erreur parsing service caché: $e');
          }
        }
        return services;
      }

      // Appel API si pas de cache
      final response = await http
          .get(Uri.parse('$baseUrl/service'), headers: _defaultHeaders)
          .timeout(Duration(milliseconds: timeout));

      if (response.statusCode == 200) {
        List<dynamic> allServicesJson = json.decode(response.body);
        List<ServiceModel> services = [];
        List<dynamic> servicesToCache = [];

        for (var json in allServicesJson) {
          try {
            String? serviceCategorieId;
            if (json['categorie'] is Map<String, dynamic>) {
              serviceCategorieId = json['categorie']['_id'] as String?;
            } else if (json['categorie'] is String) {
              serviceCategorieId = json['categorie'];
            }

            if (serviceCategorieId == categorieId) {
              services.add(ServiceModel.fromJson(json));
              servicesToCache.add(json);
            }
          } catch (e) {
            print('⚠️ Erreur parsing service: $e');
          }
        }

        // 🆕 Sauvegarder en cache
        if (servicesToCache.isNotEmpty) {
          await CacheService.saveCache(
            cacheKey,
            servicesToCache,
            duration: const Duration(hours: 24),
          );
        }

        print('✅ ${services.length} services chargés');
        return services;
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur getServicesByCategorie: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🚀 SOUMISSION RECENSEMENT SIMPLIFIÉE (VERSION OPTION C)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 🎯 Point d'entrée principal - Soumettre un recensement simplifié
  static Future<Map<String, dynamic>> submitRecensementSimple({
    required Map<String, dynamic> data,
    required String recenseurId,
    required String recenseurNom,
  }) async {
    try {
      print('📝 ═══════════════════════════════════════════════════════════');
      print('📝 DÉBUT SOUMISSION RECENSEMENT SIMPLIFIÉ');
      print('📝 Type: ${data['type']}');
      print('📝 Nom: ${data['nom']}');
      print('📝 ═══════════════════════════════════════════════════════════');

      // ─────────────────────────────────────────────────────────────────────
      // ÉTAPE 1: Créer l'utilisateur
      // ─────────────────────────────────────────────────────────────────────
      print('\n🔹 ÉTAPE 1: Création utilisateur...');
      final userId = await _createUser(data);
      print('✅ Utilisateur créé: $userId');

      // ─────────────────────────────────────────────────────────────────────
      // ÉTAPE 2: Récupérer l'ObjectId du service
      // ─────────────────────────────────────────────────────────────────────
      print('\n🔹 ÉTAPE 2: Récupération service ID...');
      final serviceId = await _getServiceId(data['service']);
      if (serviceId == null) {
        print('⚠️ Service "${data['service']}" non trouvé, utilisation valeur par défaut');
      } else {
        print('✅ Service ID: $serviceId');
      }

      // ─────────────────────────────────────────────────────────────────────
      // ÉTAPE 3: Enrichir les données avec valeurs par défaut
      // ─────────────────────────────────────────────────────────────────────
      print('\n🔹 ÉTAPE 3: Enrichissement des données...');
      final enrichedData = await _enrichWithDefaults(
        data,
        userId,
        serviceId,
        recenseurId,
        recenseurNom,
      );
      print('✅ Données enrichies');

      // ─────────────────────────────────────────────────────────────────────
      // ÉTAPE 4: Créer l'entité selon le type
      // ─────────────────────────────────────────────────────────────────────
      print('\n🔹 ÉTAPE 4: Création entité ${data['type']}...');
      Map<String, dynamic> result;

      switch (data['type']) {
        case 'prestataire':
          result = await _createPrestataireSimple(enrichedData);
          break;
        case 'freelance':
          result = await _createFreelanceSimple(enrichedData);
          break;
        case 'vendeur':
          result = await _createVendeurSimple(enrichedData);
          break;
        default:
          throw Exception('Type inconnu: ${data['type']}');
      }

      print('\n📝 ═══════════════════════════════════════════════════════════');
      print('✅ RECENSEMENT SOUMIS AVEC SUCCÈS');
      print('📝 ═══════════════════════════════════════════════════════════');

      return {
        'success': true,
        'data': result,
        'userId': userId,
        'message': 'Recensement soumis avec succès',
      };
    } catch (e) {
      print('\n📝 ═══════════════════════════════════════════════════════════');
      print('❌ ERREUR SOUMISSION: $e');
      print('📝 ═══════════════════════════════════════════════════════════');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📥 RÉCUPÉRATION DES RECENSEMENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Récupérer tous les recensements créés via l'app
  static Future<List<Map<String, dynamic>>> getRecensementsFromBackend() async {
    try {
      final allRecensements = <Map<String, dynamic>>[];

      // Récupérer prestataires
      final prestRes = await http
          .get(Uri.parse('$baseUrl/prestataire'), headers: _defaultHeaders)
          .timeout(Duration(milliseconds: timeout));

      if (prestRes.statusCode == 200) {
        final body = json.decode(prestRes.body);
        
        // Vérifier si c'est une liste ou un objet d'erreur
        if (body is List) {
          for (var p in body) {
            if (p['source'] == 'sdealsidentification') {
              allRecensements.add({
                'id': p['_id'],
                'type': 'prestataire',
                'nom': p['utilisateur']?['nom'] ?? 'N/A',
                'telephone': p['utilisateur']?['telephone'] ?? 'N/A',
                'service': p['service']?['nomservice'] ?? 'N/A',
                'status': p['status'] ?? 'pending',
                'date': p['dateRecensement'] ?? p['createdAt'],
                'localisation': p['localisation'] ?? 'N/A',
              });
            }
          }
        } else {
          print('⚠️ Prestataires: réponse non-liste: $body');
        }
      }

      // Récupérer freelances
      final freelRes = await http
          .get(Uri.parse('$baseUrl/freelance'), headers: _defaultHeaders)
          .timeout(Duration(milliseconds: timeout));

      if (freelRes.statusCode == 200) {
        final body = json.decode(freelRes.body);
        
        if (body is List) {
          for (var f in body) {
            if (f['source'] == 'sdealsidentification') {
              allRecensements.add({
                'id': f['_id'],
                'type': 'freelance',
                'nom': f['utilisateur']?['nom'] ?? 'N/A',
                'telephone': f['utilisateur']?['telephone'] ?? 'N/A',
                'service': f['job'] ?? 'N/A',
                'status': f['status'] ?? 'pending',
                'date': f['dateRecensement'] ?? f['createdAt'],
                'localisation': f['location'] ?? 'N/A',
              });
            }
          }
        } else {
          print('⚠️ Freelances: réponse non-liste: $body');
        }
      }

      // Récupérer vendeurs
      final vendRes = await http
          .get(Uri.parse('$baseUrl/vendeur'), headers: _defaultHeaders)
          .timeout(Duration(milliseconds: timeout));

      if (vendRes.statusCode == 200) {
        final body = json.decode(vendRes.body);
        
        if (body is List) {
          for (var v in body) {
            if (v['source'] == 'sdealsidentification') {
              allRecensements.add({
                'id': v['_id'],
                'type': 'vendeur',
                'nom': v['utilisateur']?['nom'] ?? 'N/A',
                'telephone': v['utilisateur']?['telephone'] ?? 'N/A',
                'service': v['shopName'] ?? 'N/A',
                'status': v['status'] ?? 'pending',
                'date': v['dateRecensement'] ?? v['createdAt'],
                'localisation': 'N/A',
              });
            }
          }
        } else {
          print('⚠️ Vendeurs: réponse non-liste: $body');
        }
      }

      // Trier par date (plus récents en premier)
      allRecensements.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      return allRecensements;
    } catch (e) {
      print('❌ Erreur récupération recensements: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔧 MÉTHODES PRIVÉES - LOGIQUE INTERNE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Créer un utilisateur
  static Future<String> _createUser(Map<String, dynamic> data) async {
    final password = _generatePassword(data['telephone']);
    final email = data['email'] ?? '${data['telephone']}@temp.com';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _defaultHeaders,
        body: json.encode({
          'nom': data['nom'],
          'telephone': data['telephone'],
          'email': email,
          'password': password,
          'role': _getRoleFromType(data['type']),
          'genre': data['genre'] ?? 'Non spécifié',
        }),
      ).timeout(Duration(milliseconds: timeout));

      print('📡 Réponse register: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final userData = json.decode(response.body);
        
        // Vérifier la structure de la réponse
        if (userData['utilisateur'] == null) {
          throw Exception('Structure réponse invalide: ${response.body}');
        }
        
        final userId = userData['utilisateur']['_id'];
        if (userId == null || userId.isEmpty) {
          throw Exception('ID utilisateur manquant dans la réponse');
        }
        
        return userId;
      } else if (response.statusCode == 400) {
        // Utilisateur existe déjà, on essaie de le récupérer
        final errorData = json.decode(response.body);
        final errorMsg = errorData['error'] ?? '';
        
        if (errorMsg.contains('téléphone') || errorMsg.contains('Email')) {
          print('⚠️ Utilisateur existe, recherche...');
          return await _findExistingUser(data['telephone'], email);
        }
        
        throw Exception('Erreur 400: $errorMsg');
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur _createUser: $e');
      rethrow;
    }
  }

  /// Trouver un utilisateur existant par téléphone ou email
  static Future<String> _findExistingUser(String telephone, String email) async {
    try {
      // Rechercher dans la liste des utilisateurs
      final response = await http
          .get(Uri.parse('$baseUrl/utilisateur'), headers: _defaultHeaders)
          .timeout(Duration(milliseconds: timeout));

      if (response.statusCode == 200) {
        List<dynamic> users = json.decode(response.body);
        final user = users.firstWhere(
          (u) => u['telephone'] == telephone || u['email'] == email,
          orElse: () => null,
        );

        if (user != null && user['_id'] != null) {
          print('✅ Utilisateur trouvé: ${user['_id']}');
          return user['_id'];
        }
      }

      throw Exception('Utilisateur non trouvé');
    } catch (e) {
      print('❌ Erreur recherche utilisateur: $e');
      rethrow;
    }
  }

  /// Récupérer l'ObjectId d'un service depuis son nom
  static Future<String?> _getServiceId(String serviceName) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/service'), headers: _defaultHeaders)
          .timeout(Duration(milliseconds: timeout));

      if (response.statusCode == 200) {
        List<dynamic> services = json.decode(response.body);
        final service = services.firstWhere(
          (s) =>
              (s['nomservice'] ?? '').toLowerCase() ==
              serviceName.toLowerCase(),
          orElse: () => null,
        );
        return service?['_id'];
      }
    } catch (e) {
      print('⚠️ Erreur récupération service: $e');
    }
    return null;
  }

  /// Enrichir les données avec valeurs par défaut intelligentes
  static Future<Map<String, dynamic>> _enrichWithDefaults(
    Map<String, dynamic> data,
    String userId,
    String? serviceId,
    String recenseurId,
    String recenseurNom,
  ) async {
    // Extraire ville/quartier de l'adresse
    final adresse = data['adresse'] ?? data['ville'] ?? 'Non spécifié';
    final parts = adresse.split(',');
    final quartier = parts.isNotEmpty ? parts[0].trim() : adresse;
    final ville = parts.length > 1 ? parts[1].trim() : 'Abidjan';

    // Définir tarifs par défaut selon service
    final defaultRates = _getDefaultRatesByService(data['service']);

    return {
      // Données originales
      ...data,

      // IDs
      'utilisateurId': userId,
      'serviceId': serviceId,
      'recenseurId': recenseurId,
      'recenseurNom': recenseurNom,

      // Géolocalisation enrichie
      'quartier': quartier,
      'ville': ville,
      'localisation': '$quartier, $ville',

      // Tarifs par défaut
      'tarifHoraireMin': data['tarifHoraireMin'] ?? defaultRates['min'],
      'tarifHoraireMax': data['tarifHoraireMax'] ?? defaultRates['max'],
      'prixMoyen': ((defaultRates['min']! + defaultRates['max']!) / 2).toInt(),

      // Métier par défaut
      'anneeExperience': data['anneeExperience'] ?? '0',
      'description':
          data['notes'] ?? 'Professionnel recensé par $recenseurNom',
      'specialite': [data['service']],
      'zoneIntervention': [quartier],

      // 🆕 OPTION C - Validation
      'verifier': false,
      'status': 'pending', // 🔑 En attente validation
      'source': 'sdealsidentification', // 🔑 Traçabilité
      'dateRecensement': DateTime.now().toIso8601String(),
    };
  }

  /// Tarifs par défaut selon le service
  static Map<String, int> _getDefaultRatesByService(String service) {
    final rates = {
      'Plomberie': {'min': 15000, 'max': 35000},
      'Électricité': {'min': 15000, 'max': 35000},
      'Menuiserie': {'min': 20000, 'max': 40000},
      'Maçonnerie': {'min': 15000, 'max': 30000},
      'Peinture': {'min': 10000, 'max': 25000},
      'Jardinage': {'min': 8000, 'max': 20000},
      'Nettoyage': {'min': 5000, 'max': 15000},
      'Coiffure': {'min': 3000, 'max': 15000},
      'Couture': {'min': 5000, 'max': 20000},
      'Mécanique': {'min': 15000, 'max': 40000},
      'Climatisation': {'min': 20000, 'max': 50000},
      'Soudure': {'min': 15000, 'max': 35000},
      'Informatique': {'min': 10000, 'max': 30000},
      'Photographie': {'min': 15000, 'max': 50000},
      'Design': {'min': 20000, 'max': 60000},
    };

    return rates[service] ?? {'min': 10000, 'max': 30000};
  }

  /// Créer un prestataire (version simplifiée)
  static Future<Map<String, dynamic>> _createPrestataireSimple(
    Map<String, dynamic> data,
  ) async {
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/prestataire'));

    // ✅ Champs OBLIGATOIRES
    request.fields['utilisateur'] = data['utilisateurId'];
    request.fields['service'] = data['serviceId'] ?? '';
    request.fields['prixprestataire'] = data['prixMoyen'].toString();

    // Champs recommandés avec defaults
    request.fields['localisation'] = data['localisation'];
    request.fields['description'] = data['description'];
    request.fields['anneeExperience'] = data['anneeExperience'];
    request.fields['tarifHoraireMin'] = data['tarifHoraireMin'].toString();
    request.fields['tarifHoraireMax'] = data['tarifHoraireMax'].toString();
    request.fields['verifier'] = 'false';

    // Géolocalisation
    if (data['latitude'] != null && data['longitude'] != null) {
      request.fields['localisationmaps'] = json.encode({
        'latitude': data['latitude'],
        'longitude': data['longitude'],
      });
    }

    // Arrays
    request.fields['specialite'] = json.encode(data['specialite']);
    request.fields['zoneIntervention'] = json.encode(data['zoneIntervention']);

    // 🆕 OPTION C - Traçabilité
    request.fields['source'] = data['source'];
    request.fields['recenseur'] = data['recenseurId'];
    request.fields['dateRecensement'] = data['dateRecensement'];
    request.fields['status'] = data['status']; // pending

    // Photo (si existe)
    if (data['photoPath'] != null && File(data['photoPath']).existsSync()) {
      request.files.add(
        await http.MultipartFile.fromPath('cni1', data['photoPath']),
      );
    }

    // Envoi
    print('📤 Envoi prestataire...');
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ Prestataire créé');
      return json.decode(responseBody);
    } else {
      throw Exception('Erreur ${response.statusCode}: $responseBody');
    }
  }

  /// Créer un freelance (version simplifiée)
  static Future<Map<String, dynamic>> _createFreelanceSimple(
    Map<String, dynamic> data,
  ) async {
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/freelance'));

    // ✅ Champs OBLIGATOIRES
    request.fields['utilisateur'] = data['utilisateurId'];
    request.fields['name'] = data['nom'];
    request.fields['job'] = data['service'];
    request.fields['category'] = data['categorie'] ?? data['service'];
    request.fields['location'] = data['localisation'];
    request.fields['hourlyRate'] = data['prixMoyen'].toString();

    // Champs recommandés
    request.fields['phoneNumber'] = data['telephone'];
    request.fields['description'] = data['description'];
    request.fields['experienceLevel'] = 'Débutant';
    request.fields['availabilityStatus'] = 'Disponible';
    request.fields['workingHours'] = 'Temps partiel';

    // Skills
    request.fields['skills'] = json.encode(data['specialite']);

    // 🆕 OPTION C - Traçabilité
    request.fields['source'] = data['source'];
    request.fields['recenseur'] = data['recenseurId'];
    request.fields['dateRecensement'] = data['dateRecensement'];
    request.fields['status'] = data['status']; // pending

    // Photo
    if (data['photoPath'] != null && File(data['photoPath']).existsSync()) {
      request.files.add(
        await http.MultipartFile.fromPath('profileImage', data['photoPath']),
      );
    }

    print('📤 Envoi freelance...');
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ Freelance créé');
      return json.decode(responseBody);
    } else {
      throw Exception('Erreur ${response.statusCode}: $responseBody');
    }
  }

  /// Créer un vendeur (version simplifiée)
  static Future<Map<String, dynamic>> _createVendeurSimple(
    Map<String, dynamic> data,
  ) async {
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/vendeur'));

    // ✅ Champs OBLIGATOIRES
    request.fields['utilisateur'] = data['utilisateurId'];
    request.fields['shopName'] = data['shopName'] ?? data['nom'];
    request.fields['shopDescription'] =
        data['shopDescription'] ?? data['description'];
    request.fields['businessType'] = data['businessType'] ?? 'Particulier';

    // Champs recommandés
    request.fields['businessCategories'] =
        json.encode([data['categorie'] ?? data['service']]);
    request.fields['businessPhone'] = data['telephone'];

    // Localisation
    final businessAddress = {
      'city': data['ville'],
      'quartier': data['quartier'],
      'country': 'Côte d\'Ivoire',
    };
    request.fields['businessAddress'] = json.encode(businessAddress);
    request.fields['deliveryZones'] = json.encode([data['ville']]);

    // 🆕 OPTION C - Traçabilité
    request.fields['source'] = data['source'];
    request.fields['recenseur'] = data['recenseurId'];
    request.fields['dateRecensement'] = data['dateRecensement'];
    request.fields['status'] = data['status']; // pending

    // Photo (logo boutique)
    if (data['photoPath'] != null && File(data['photoPath']).existsSync()) {
      request.files.add(
        await http.MultipartFile.fromPath('shopLogo', data['photoPath']),
      );
    }

    print('📤 Envoi vendeur...');
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ Vendeur créé');
      return json.decode(responseBody);
    } else {
      throw Exception('Erreur ${response.statusCode}: $responseBody');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🛠️ UTILITAIRES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Générer mot de passe temporaire depuis téléphone
  static String _generatePassword(String telephone) {
    return 'temp_${telephone.replaceAll(RegExp(r'[^0-9]'), '')}';
  }

  /// Obtenir le rôle selon le type
  static String _getRoleFromType(String type) {
    switch (type) {
      case 'prestataire':
        return 'Prestataire';
      case 'freelance':
        return 'Freelance';
      case 'vendeur':
        return 'Vendeur';
      default:
        return 'Client';
    }
  }

  /// Vérifier la connectivité au serveur
  static Future<bool> checkConnectivity() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/service'), headers: _defaultHeaders)
          .timeout(Duration(milliseconds: 5000));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erreur connectivité: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📊 SYNCHRONISATION BATCH (pour sync service)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Synchroniser plusieurs recensements en une fois
  static Future<Map<String, dynamic>> syncPendingRecensements(
    List<dynamic> recensements,
    String recenseurId,
    String recenseurNom,
  ) async {
    final results = <Map<String, dynamic>>[];
    int successCount = 0;
    int errorCount = 0;

    for (var recensement in recensements) {
      try {
        final result = await submitRecensementSimple(
          data: recensement,
          recenseurId: recenseurId,
          recenseurNom: recenseurNom,
        );

        if (result['success'] == true) {
          successCount++;
        } else {
          errorCount++;
        }

        results.add({
          'syncId': recensement['id'],
          'success': result['success'],
          'data': result['data'],
        });
      } catch (e) {
        errorCount++;
        results.add({
          'syncId': recensement['id'],
          'success': false,
          'error': e.toString(),
        });
      }
    }

    return {
      'success': true,
      'message': '$successCount recensements synchronisés, $errorCount erreurs',
      'results': results,
      'successCount': successCount,
      'errorCount': errorCount,
    };
  }
}
