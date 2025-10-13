import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/classification_model.dart';

class ApiService {
  static String get baseUrl =>
      dotenv.env['API_URL'] ?? 'http://localhost:3000/api';
  static int get timeout => int.parse(dotenv.env['API_TIMEOUT'] ?? '30000');

  // Headers par défaut
  static Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Charger les catégories par groupe (utilise le nom du groupe comme dans sdealsmobile)
  static Future<List<CategorieModel>> getCategoriesByGroupe(
    String nomGroupe,
  ) async {
    try {
      print('🔄 API: Chargement des catégories pour le groupe: $nomGroupe');

      final response = await http
          .get(Uri.parse('$baseUrl/categorie'), headers: _defaultHeaders)
          .timeout(Duration(milliseconds: timeout));

      if (response.statusCode == 200) {
        List<dynamic> allCategoriesJson = json.decode(response.body);
        List<CategorieModel> allCategories = [];

        // Debug: voir tous les groupes disponibles
        Set<String> groupesTrouves = {};
        for (var json in allCategoriesJson) {
          if (json['groupe'] is Map<String, dynamic>) {
            var groupeJson = json['groupe'];
            groupesTrouves.add(groupeJson['nomgroupe'] as String);
          }
        }
        print('🔍 Groupes trouvés dans l\'API: $groupesTrouves');
        print('🎯 Groupe recherché: "$nomGroupe"');

        // Traiter chaque catégorie et filtrer par groupe
        for (var json in allCategoriesJson) {
          try {
            String? groupeNom;

            // Extraire le nom du groupe
            if (json['groupe'] is Map<String, dynamic>) {
              var groupeJson = json['groupe'];
              groupeNom = groupeJson['nomgroupe'] as String?;
            }

            // Filtrer par nom de groupe (insensible à casse)
            if (groupeNom != null &&
                groupeNom.toLowerCase() == nomGroupe.toLowerCase()) {
              // Adapter le JSON pour notre modèle CategorieModel
              var jsonCopy = Map<String, dynamic>.from(json);

              if (json['groupe'] is Map<String, dynamic>) {
                var groupeJson = json['groupe'];
                jsonCopy['groupeId'] = groupeJson['_id'] as String;
                jsonCopy['nom'] = json['nomcategorie'] as String;
                jsonCopy['id'] = json['_id'] as String;
                jsonCopy['imagePath'] = json['imagecategorie'] as String;
              } else {
                jsonCopy['groupeId'] = json['groupe'] as String;
                jsonCopy['nom'] = json['nomcategorie'] as String;
                jsonCopy['id'] = json['_id'] as String;
                jsonCopy['imagePath'] = json['imagecategorie'] as String;
              }

              allCategories.add(CategorieModel.fromJson(jsonCopy));
            }
          } catch (e) {
            print('Erreur parsing catégorie: $e pour ${json.toString()}');
          }
        }

        // Les catégories sont déjà filtrées par groupe
        final filteredCategories = allCategories;

        print(
          '✅ ${filteredCategories.length} catégories trouvées pour "$nomGroupe"',
        );
        return filteredCategories;
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des catégories: $e');
      return [];
    }
  }

  // Charger les services par catégorie spécifique
  static Future<List<ServiceModel>> getServicesByCategorie(
    String categorieId,
    String? categorieNom,
  ) async {
    try {
      print(
        '🔄 API: Chargement des services pour la catégorie: $categorieId ($categorieNom)',
      );

      final response = await http
          .get(Uri.parse('$baseUrl/service'), headers: _defaultHeaders)
          .timeout(Duration(milliseconds: timeout));

      if (response.statusCode == 200) {
        final List<dynamic> allServicesJson = json.decode(response.body);
        print('📦 ${allServicesJson.length} services reçus de l\'API');

        List<ServiceModel> allServices = [];

        // Traiter chaque service et filtrer par catégorie spécifique
        for (var json in allServicesJson) {
          try {
            // Vérifier si le service appartient à la catégorie sélectionnée
            String? serviceCategorieId;

            if (json['categorie'] is Map<String, dynamic>) {
              // Si categorie est un objet peuplé, extraire l'ID
              serviceCategorieId = json['categorie']['_id'] as String?;
            } else if (json['categorie'] is String) {
              // Si categorie est une string
              serviceCategorieId = json['categorie'] as String?;
            }

            // Filtrer par catégorie spécifique
            bool matchesCategorie = serviceCategorieId == categorieId;

            if (matchesCategorie) {
              print(
                '✅ Service trouvé pour catégorie $categorieId: ${json['nomservice']}',
              );

              // Adapter le JSON pour notre modèle ServiceModel
              var jsonCopy = Map<String, dynamic>.from(json);

              // Mapper les champs de l'API vers notre modèle
              jsonCopy['id'] = json['_id'] as String;
              jsonCopy['nom'] = json['nomservice'] as String;
              jsonCopy['categorieId'] = serviceCategorieId ?? '';
              jsonCopy['prixMoyen'] = json['prixmoyen'] as String?;
              jsonCopy['imagePath'] = json['imageservice'] as String?;

              allServices.add(ServiceModel.fromJson(jsonCopy));
            }
          } catch (e) {
            print('Erreur parsing service: $e pour ${json.toString()}');
          }
        }

        print(
          '✅ ${allServices.length} services trouvés pour la catégorie $categorieId',
        );
        return allServices;
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des services: $e');
      return [];
    }
  }

  // Soumettre un recensement (utilise les APIs existantes)
  static Future<Map<String, dynamic>> submitRecensement(
    Map<String, dynamic> recensementData,
  ) async {
    try {
      String endpoint;
      String type = recensementData['type'] as String;

      // Transformer les données selon le type
      Map<String, dynamic> apiData;

      switch (type) {
        case 'prestataire':
          endpoint = '$baseUrl/prestataire';
          apiData = _transformToPrestataireData(recensementData);
          break;
        case 'freelance':
          endpoint = '$baseUrl/freelance';
          apiData = _transformToFreelanceData(recensementData);
          break;
        case 'vendeur':
          endpoint = '$baseUrl/vendeur';
          apiData = _transformToVendeurData(recensementData);
          break;
        default:
          throw Exception('Type de recensement non supporté: $type');
      }

      print('🔄 Envoi vers $endpoint avec données: ${apiData.keys.toList()}');

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: _defaultHeaders,
            body: json.encode(apiData),
          )
          .timeout(Duration(milliseconds: timeout));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de la soumission du recensement: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Transformer les données pour l'API prestataire
  static Map<String, dynamic> _transformToPrestataireData(
    Map<String, dynamic> data,
  ) {
    return {
      'utilisateur': 'temp_user_id', // TODO: Créer un utilisateur temporaire
      'service': data['service'] ?? '',
      'prixprestataire': 0, // Prix par défaut
      'localisation':
          data['ville'] ?? data['adresse'] ?? 'Localisation non spécifiée',
      'localisationmaps': {
        'latitude': data['latitude'],
        'longitude': data['longitude'],
      },
      'description': data['notes'] ?? '',
      'specialite': [data['categorie'] ?? ''],
      'verifier': false,
      'cni1': data['photoPath'] ?? '',
      'numeroCNI': data['telephone'] ?? '',
    };
  }

  // Transformer les données pour l'API freelance
  static Map<String, dynamic> _transformToFreelanceData(
    Map<String, dynamic> data,
  ) {
    return {
      'utilisateur': 'temp_user_id', // TODO: Créer un utilisateur temporaire
      'name': data['nom'] ?? '',
      'job': data['service'] ?? '',
      'category': data['categorie'] ?? '',
      'location':
          data['ville'] ?? data['adresse'] ?? 'Localisation non spécifiée',
      'phoneNumber': data['telephone'] ?? '',
      'hourlyRate': 0, // Prix par défaut
      'description': data['notes'] ?? '',
      'skills': [data['service'] ?? ''],
      'imagePath': data['photoPath'] ?? '',
      'verificationDocuments': {
        'cni1': data['photoPath'] ?? '',
        'isVerified': false,
      },
    };
  }

  // Transformer les données pour l'API vendeur
  static Map<String, dynamic> _transformToVendeurData(
    Map<String, dynamic> data,
  ) {
    return {
      'utilisateur': 'temp_user_id', // TODO: Créer un utilisateur temporaire
      'service': data['service'] ?? '',
      'prixprestataire': 0, // Prix par défaut
      'localisation':
          data['ville'] ?? data['adresse'] ?? 'Localisation non spécifiée',
      'localisationmaps': {
        'latitude': data['latitude'],
        'longitude': data['longitude'],
      },
      'description': data['notes'] ?? '',
      'specialite': [data['categorie'] ?? ''],
      'verifier': false,
      'cni1': data['photoPath'] ?? '',
      'numeroCNI': data['telephone'] ?? '',
      // Champs spécifiques au vendeur
      'shopName': data['shopName'] ?? '',
      'shopDescription': data['shopDescription'] ?? '',
    };
  }

  // Upload d'image
  static Future<String?> uploadImage(File imageFile, String type) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/image'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      request.fields['type'] = type;

      final response = await request.send().timeout(
        Duration(milliseconds: timeout),
      );

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);
        return data['url'];
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de l\'upload de l\'image: $e');
      return null;
    }
  }

  // Vérifier la connectivité au serveur
  static Future<bool> checkConnectivity() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'), headers: _defaultHeaders)
          .timeout(
            Duration(milliseconds: 5000),
          ); // Timeout court pour le health check

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur de connectivité: $e');
      return false;
    }
  }

  // Synchroniser les recensements en attente
  static Future<Map<String, dynamic>> syncPendingRecensements(
    List<dynamic> recensements,
  ) async {
    try {
      final results = <Map<String, dynamic>>[];
      int successCount = 0;
      int errorCount = 0;

      for (final recensement in recensements) {
        try {
          final response = await http
              .post(
                Uri.parse('$baseUrl/recensement'),
                headers: _defaultHeaders,
                body: json.encode(recensement),
              )
              .timeout(Duration(milliseconds: timeout));

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = json.decode(response.body);
            results.add({'success': true, 'data': data});
            successCount++;
          } else {
            results.add({
              'success': false,
              'error': 'Erreur ${response.statusCode}: ${response.body}',
            });
            errorCount++;
          }
        } catch (e) {
          results.add({'success': false, 'error': e.toString()});
          errorCount++;
        }
      }

      return {
        'success': true,
        'successCount': successCount,
        'errorCount': errorCount,
        'results': results,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
