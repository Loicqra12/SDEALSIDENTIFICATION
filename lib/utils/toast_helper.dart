import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Service pour afficher des notifications toast élégantes
class ToastHelper {
  /// Toast de succès (vert)
  static void showSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color(0xFF1CBF3F),
      textColor: Colors.white,
      fontSize: 16.0,
      timeInSecForIosWeb: 3,
    );
  }

  /// Toast d'erreur (rouge)
  static void showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red.shade700,
      textColor: Colors.white,
      fontSize: 16.0,
      timeInSecForIosWeb: 3,
    );
  }

  /// Toast d'information (bleu)
  static void showInfo(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.blue.shade700,
      textColor: Colors.white,
      fontSize: 14.0,
      timeInSecForIosWeb: 2,
    );
  }

  /// Toast d'avertissement (orange)
  static void showWarning(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.orange.shade700,
      textColor: Colors.white,
      fontSize: 16.0,
      timeInSecForIosWeb: 3,
    );
  }

  /// Toast de chargement (gris)
  static void showLoading(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.grey.shade700,
      textColor: Colors.white,
      fontSize: 14.0,
      timeInSecForIosWeb: 2,
    );
  }
}
