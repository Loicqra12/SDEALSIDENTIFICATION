import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Service de compression et gestion d'images
class ImageService {
  static const int maxWidth = 1024;
  static const int maxHeight = 1024;
  static const int quality = 85; // 0-100

  /// Compresser une image avant upload
  static Future<File?> compressImage(File file) async {
    try {
      // Obtenir le répertoire temporaire
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${const Uuid().v4()}.jpg';

      print('📸 Compression image: ${file.path}');

      // Compresser l'image
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        print('❌ Compression échouée');
        return null;
      }

      // Calculer la réduction
      final originalSize = await file.length();
      final compressedSize = await result.length();
      final reduction =
          ((originalSize - compressedSize) / originalSize * 100)
              .toStringAsFixed(1);

      print('✅ Compression réussie : $reduction% de réduction');
      print(
          '   Original : ${(originalSize / 1024).toStringAsFixed(1)} KB');
      print(
          '   Compressé : ${(compressedSize / 1024).toStringAsFixed(1)} KB');

      return File(result.path);
    } catch (e) {
      print('❌ Erreur compression : $e');
      return null;
    }
  }

  /// Obtenir les dimensions d'une image
  static Future<Map<String, int>?> getImageDimensions(File file) async {
    try {
      final bytes = await file.readAsBytes();
      // FlutterImageCompress peut lire les dimensions sans décompresser
      // Pour une implémentation simple, on retourne null
      // Dans un cas réel, on utiliserait un package comme image
      return null;
    } catch (e) {
      print('❌ Erreur obtention dimensions : $e');
      return null;
    }
  }

  /// Vérifier si une image nécessite compression
  static Future<bool> needsCompression(File file) async {
    try {
      final size = await file.length();

      // Compresser si > 500 KB
      if (size > 500 * 1024) {
        print('⚠️  Image > 500KB, compression nécessaire');
        return true;
      }

      print('✅ Image OK, pas de compression nécessaire');
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Compresser uniquement si nécessaire
  static Future<File> compressIfNeeded(File file) async {
    final needsComp = await needsCompression(file);

    if (!needsComp) {
      return file;
    }

    final compressed = await compressImage(file);
    return compressed ?? file;
  }
}
