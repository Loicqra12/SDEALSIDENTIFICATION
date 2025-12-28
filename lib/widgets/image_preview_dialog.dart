import 'dart:io';
import 'package:flutter/material.dart';

/// Dialog de prévisualisation d'image
class ImagePreviewDialog extends StatelessWidget {
  final File imageFile;
  final String title;
  final VoidCallback? onDelete;
  final VoidCallback? onRetake;

  const ImagePreviewDialog({
    super.key,
    required this.imageFile,
    this.title = 'Aperçu de la photo',
    this.onDelete,
    this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1CBF3F),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Image
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: Image.file(
                imageFile,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (onRetake != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onRetake!();
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Reprendre'),
                  ),
                if (onDelete != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDelete!();
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Supprimer',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper pour afficher le dialog facilement
  static Future<void> show(
    BuildContext context, {
    required File imageFile,
    String? title,
    VoidCallback? onDelete,
    VoidCallback? onRetake,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ImagePreviewDialog(
        imageFile: imageFile,
        title: title ?? 'Aperçu de la photo',
        onDelete: onDelete,
        onRetake: onRetake,
      ),
    );
  }
}
