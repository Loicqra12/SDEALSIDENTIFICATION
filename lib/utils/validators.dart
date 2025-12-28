/// Validateurs réutilisables pour les formulaires
class Validators {
  /// Validation téléphone ivoirien
  /// Formats acceptés: +2250707123456, 00225 0707123456, 0707123456
  static String? validateIvorianPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }

    // Nettoyer le numéro (retirer espaces, tirets, parenthèses)
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Formats acceptés :
    // +2250707123456 (13 chiffres)
    // 00225 0707123456 (13 chiffres)
    // 0707123456 (10 chiffres)

    final regexWithCode = RegExp(r'^(\+225|00225)[0-9]{10}$');
    final regexWithoutCode = RegExp(r'^0[0-9]{9}$');

    if (!regexWithCode.hasMatch(cleaned) &&
        !regexWithoutCode.hasMatch(cleaned)) {
      return 'Format invalide. Ex: +225 07 07 12 34 56';
    }

    // Vérifier opérateurs valides (MTN, Orange, Moov)
    final number = cleaned.replaceAll(RegExp(r'^(\+225|00225)'), '');
    final prefix = number.substring(0, 2);

    final validPrefixes = ['05', '06', '07', '01', '02', '03'];
    if (!validPrefixes.contains(prefix)) {
      return 'Opérateur non reconnu';
    }

    return null;
  }

  /// Validation email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email optionnel
    }

    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!regex.hasMatch(value)) {
      return 'Email invalide';
    }

    return null;
  }

  /// Validation nom
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom est requis';
    }

    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }

    if (value.trim().length > 50) {
      return 'Le nom est trop long (max 50 caractères)';
    }

    // Accepter lettres, espaces, apostrophes, tirets
    final regex = RegExp(r"^[a-zA-ZÀ-ÿ\s'\-]+$");
    if (!regex.hasMatch(value)) {
      return 'Le nom contient des caractères invalides';
    }

    return null;
  }

  /// Validation champ requis générique
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  /// Formater téléphone ivoirien pour affichage
  /// Ex: 0707123456 -> 07 07 12 34 56
  static String formatIvorianPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Si commence par +225 ou 00225
    if (cleaned.startsWith('+225')) {
      final number = cleaned.substring(4);
      if (number.length >= 10) {
        return '+225 ${number.substring(0, 2)} ${number.substring(2, 4)} ${number.substring(4, 6)} ${number.substring(6, 8)} ${number.substring(8)}';
      }
    } else if (cleaned.startsWith('00225')) {
      final number = cleaned.substring(5);
      if (number.length >= 10) {
        return '+225 ${number.substring(0, 2)} ${number.substring(2, 4)} ${number.substring(4, 6)} ${number.substring(6, 8)} ${number.substring(8)}';
      }
    } else if (cleaned.startsWith('0') && cleaned.length >= 10) {
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2, 4)} ${cleaned.substring(4, 6)} ${cleaned.substring(6, 8)} ${cleaned.substring(8)}';
    }

    return phone;
  }

  /// Nettoyer téléphone pour stockage (retirer formatage)
  static String cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }
}
