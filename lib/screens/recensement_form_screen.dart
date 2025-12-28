import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';

import '../models/recensement_model.dart';
import '../models/classification_model.dart';
import '../services/local_storage_service.dart';
import '../services/points_service.dart';
import '../services/sync_service.dart';
import '../services/api_service.dart';
import '../blocs/classification_bloc.dart';

// 🆕 Nouveaux imports pour UX/UI amélioré
import '../utils/toast_helper.dart';
import '../utils/validators.dart';
import '../services/image_service.dart';
import '../widgets/upload_progress_overlay.dart';
import '../widgets/success_animation.dart';
import '../widgets/image_preview_dialog.dart';

class RecensementFormScreen extends StatefulWidget {
  final String type;

  const RecensementFormScreen({super.key, required this.type});

  @override
  State<RecensementFormScreen> createState() => _RecensementFormScreenState();
}

class _RecensementFormScreenState extends State<RecensementFormScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Données du formulaire (pour usage futur)
  // final Map<String, dynamic> _formData = {};

  // Contrôleurs
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _quartierController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Images et localisation
  File? _photoFile;
  File? _cniRectoFile;
  File? _cniVersoFile;
  Position? _currentPosition;

  // Sélections
  String? _selectedCategorie;
  String? _selectedService;

  // Utilisateur connecté
  String? _currentUserId;
  String? _currentUserName;

  // Prix
  final TextEditingController _prixController = TextEditingController();

  // Champs spécifiques au vendeur
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopDescriptionController =
      TextEditingController();
  List<String> _selectedProductCategories = [];
  List<String> _selectedProductTypes = [];

  // 🆕 État pour upload progress
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // Classification (chargées depuis le backend)
  List<CategorieModel> _categories = [];
  List<ServiceModel> _services = [];

  // Données pour le vendeur
  final List<String> _productCategories = [
    'Mode',
    'Électronique',
    'Beauté',
    'Maison',
    'Informatique',
    'Sports & Loisirs',
    'Santé',
    'Alimentation',
    'Artisanat',
    'Livres',
    'Jouets',
    'Animaux',
    'Automobile',
  ];
  final List<String> _productTypes = [
    'Produits physiques',
    'Services numériques',
    'Produits artisanaux',
    'Produits alimentaires',
    'Produits de beauté',
    'Vêtements',
    'Électronique',
    'Livres',
    'Jouets',
    'Autre',
  ];

  // Groupe fixe selon le type (utilise les noms comme dans sdealsmobile)
  String get _fixedGroupeNom {
    switch (widget.type) {
      case 'prestataire':
        return 'Métiers';
      case 'freelance':
        return 'Freelance';
      case 'vendeur':
        return 'E-marché';
      default:
        return 'Métiers';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _getCurrentLocation();
    // Charger les catégories via le BLoC
    print('🚀 Initialisation du formulaire pour le type: ${widget.type}');
    print('🎯 Groupe à charger: $_fixedGroupeNom');
    context.read<ClassificationBloc>().add(
      LoadCategoriesByGroup(groupId: _fixedGroupeNom),
    );
  }

  Future<void> _loadCurrentUser() async {
    // TODO: Récupérer depuis AuthCubit ou SharedPreferences
    // Pour l'instant, valeurs par défaut
    setState(() {
      // TODO: Récupérer l'ID réel de l'utilisateur connecté depuis AuthCubit
      _currentUserId = '000000000000000000000000'; // ObjectId null valide
      _currentUserName = 'Recenseur Anonyme';
    });
  }

  List<Step> _buildSteps(ClassificationState state) {
    List<Step> steps = [
      Step(
        title: const Text('Informations personnelles'),
        content: _buildPersonalInfoStep(),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: const Text('Localisation'),
        content: _buildLocationStep(),
        isActive: _currentStep >= 1,
      ),
    ];

    // Ajouter l'étape spécifique au vendeur
    if (widget.type == 'vendeur') {
      steps.add(
        Step(
          title: const Text('Informations boutique'),
          content: _buildShopInfoStep(),
          isActive: _currentStep >= 2,
        ),
      );
      steps.add(
        Step(
          title: const Text('Produits'),
          content: _buildProductsStep(),
          isActive: _currentStep >= 3,
        ),
      );
    }

    // Classification (étape commune)
    steps.add(
      Step(
        title: const Text('Classification'),
        content: _buildClassificationStep(state),
        isActive:
            widget.type == 'vendeur' ? _currentStep >= 4 : _currentStep >= 2,
      ),
    );

    // Photo (étape commune)
    steps.add(
      Step(
        title: const Text('Photo'),
        content: _buildPhotoStep(),
        isActive:
            widget.type == 'vendeur' ? _currentStep >= 5 : _currentStep >= 3,
      ),
    );

    // Récapitulatif (étape commune)
    steps.add(
      Step(
        title: const Text('Récapitulatif'),
        content: _buildReviewStep(),
        isActive:
            widget.type == 'vendeur' ? _currentStep >= 6 : _currentStep >= 4,
      ),
    );

    return steps;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _quartierController.dispose();
    _notesController.dispose();
    _prixController.dispose();
    _shopNameController.dispose();
    _shopDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Erreur de localisation: $e');
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image != null) {
      File imageFile = File(image.path);

      // 🆕 Preview de la photo
      await ImagePreviewDialog.show(
        context,
        imageFile: imageFile,
        title: 'Photo du profil',
        onRetake: _takePhoto,
        onDelete: () {
          setState(() => _photoFile = null);
        },
      );

      // 🆕 Compression automatique
      ToastHelper.showLoading('Compression de l\'image...');
      final compressed = await ImageService.compressIfNeeded(imageFile);
      
      setState(() {
        _photoFile = compressed;
      });
      
      ToastHelper.showSuccess('Photo prête pour l\'envoi!');
    }
  }

  Future<void> _takeCniRecto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _cniRectoFile = File(image.path);
      });
    }
  }

  Future<void> _takeCniVerso() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _cniVersoFile = File(image.path);
      });
    }
  }

  // Méthode supprimée - on utilise maintenant le GPS automatique
  // au lieu d'une carte interactive compliquée

  void _nextStep() {
    int maxSteps =
        widget.type == 'vendeur' ? 6 : 4; // Vendeur a 2 étapes supplémentaires
    if (_currentStep < maxSteps) {
      setState(() {
        _currentStep++;
      });
    } else {
      _submitForm();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _submitForm() async {
    print('🔄 Début de la soumission avec API v2 simplifiée');
    print(
      '📋 Données: type=${widget.type}, categorie=$_selectedCategorie, service=$_selectedService',
    );

    if (!_formKey.currentState!.validate()) {
      // 🆕 Toast pour erreur de validation
      ToastHelper.showError('Veuillez corriger les erreurs du formulaire');
      return;
    }

    _formKey.currentState!.save();

    // 🆕 Afficher overlay de progression
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Préparer les données pour l'API v2 simplifiée
      final data = {
        'type': widget.type,
        'nom': _nomController.text,
        'telephone': _telephoneController.text,
        'email': _emailController.text.isNotEmpty ? _emailController.text : null,
        'service': _getServiceName(), // Nom du service, pas l'ID
        'categorie': _getCategoryName(), // Nom de la catégorie
        'photoPath': _photoFile?.path,
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'adresse': _buildFullAddress(),
        'ville': _villeController.text.isNotEmpty
            ? _villeController.text
            : 'Abidjan',
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        'genre': 'Non spécifié', // Requis par backend
        
        // Champs vendeur
        if (widget.type == 'vendeur') ...{
          'shopName': _shopNameController.text,
          'shopDescription': _shopDescriptionController.text,
          'businessType': 'Particulier',
        },
      };

      print('📤 Envoi des données vers API v2...');
      setState(() => _uploadProgress = 0.3);

      // Appeler l'API simplifiée
      final result = await ApiService.submitRecensementSimple(
        data: data,
        recenseurId: _currentUserId ?? 'unknown',
        recenseurNom: _currentUserName ?? 'Recenseur',
      );

      setState(() => _uploadProgress = 0.9);

      if (result['success'] == true) {
        print('✅ Recensement soumis avec succès');
        setState(() => _uploadProgress = 1.0);

        // Calculer les points
        final points = PointsService.calculateRecensementPoints(
          hasPhoto: _photoFile != null,
          hasLocation: _currentPosition != null,
          isComplete: true,
          isFirstRecensement: false,
          streakCount: 0,
        );

        // Ajouter les points
        await PointsService.addPoints(
          _currentUserId ?? 'unknown',
          points,
          'Recensement ${_getTypeTitle()}',
        );

        setState(() => _isUploading = false);

        // 🆕 Animation de succès
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: SizedBox(
              height: 200,
              child: SuccessAnimation(
                onComplete: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        );

        // 🆕 Toast de succès
        ToastHelper.showSuccess('✅ Recensement enregistré avec succès!');

        // Afficher dialog info
        _showSuccessDialog(points);
      } else {
        print('❌ Erreur soumission: ${result["error"]}');
        setState(() => _isUploading = false);
        // 🆕 Toast d'erreur
        ToastHelper.showError('❌ Erreur: ${result["error"]}');
        _showErrorDialog(result['error']?.toString() ?? 'Erreur inconnue');
      }
    } catch (e) {
      setState(() => _isUploading = false);
      // 🆕 Toast d'erreur
      ToastHelper.showError('❌ Erreur: ${e.toString()}');
      _showErrorDialog(e.toString());
    }
  }

  String _getTypeTitle() {
    switch (widget.type) {
      case 'prestataire':
        return 'Prestataire';
      case 'freelance':
        return 'Freelance';
      case 'vendeur':
        return 'Vendeur';
      default:
        return 'Personne';
    }
  }

  String _getGroupeName() {
    return _fixedGroupeNom;
  }

  // Méthodes helpers pour l'API v2
  String _getServiceName() {
    if (_selectedService == null) return '';
    return _services
        .firstWhere(
          (s) => s.id == _selectedService,
          orElse: () => ServiceModel(
            id: '',
            nom: '',
            categorieId: '',
            imagePath: '',
            prixMoyen: '',
          ),
        )
        .nom;
  }

  String _getCategoryName() {
    if (_selectedCategorie == null) return '';
    return _categories
        .firstWhere(
          (c) => c.id == _selectedCategorie,
          orElse: () => CategorieModel(
            id: '',
            nom: '',
            groupeId: '',
            imagePath: '',
          ),
        )
        .nom;
  }

  String _buildFullAddress() {
    final parts = <String>[];
    if (_quartierController.text.isNotEmpty) {
      parts.add(_quartierController.text);
    }
    if (_adresseController.text.isNotEmpty) {
      parts.add(_adresseController.text);
    }
    if (_villeController.text.isNotEmpty) {
      parts.add(_villeController.text);
    }
    return parts.isEmpty ? 'Non spécifié' : parts.join(', ');
  }

  void _showSuccessDialog(int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: const Text(
                'Recensement réussi !',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Les informations ont été enregistrées avec succès.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '+$points points gagnés !',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Le recensement sera validé par un administrateur.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/dashboard');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: const Text(
                'Erreur',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Une erreur est survenue lors de la soumission :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            const Text(
              'Vérifiez votre connexion internet et réessayez.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClassificationBloc, ClassificationState>(
      builder: (context, state) {
        // Debug: voir l'état actuel
        print('🔍 État du BLoC: ${state.runtimeType}');
        if (state is CategoriesLoaded) {
          print('📋 Catégories dans l\'état: ${state.categories.length}');
          // Mettre à jour les catégories locales
          _categories = state.categories;
        }

        if (state is ServicesLoaded) {
          print('🔧 Services dans l\'état: ${state.services.length}');
          // Mettre à jour les services locaux
          _services = state.services;
        }

        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                title: Text('Recensement ${_getTypeTitle()}'),
                backgroundColor: const Color(0xFF1CBF3F),
                foregroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(44),
                    bottomRight: Radius.circular(44),
                  ),
                ),
              ),
              body: Form(
                key: _formKey,
                child: Stepper(
                  type: StepperType.vertical,
                  currentStep: _currentStep,
                  steps: _buildSteps(state),
                  onStepContinue: _nextStep,
                  onStepCancel: _previousStep,
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: details.onStepContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1CBF3F),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                _currentStep == (widget.type == 'vendeur' ? 6 : 4)
                                    ? 'SOUMETTRE'
                                    : 'SUIVANT',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          if (_currentStep > 0) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: details.onStepCancel,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Color(0xFF1CBF3F)),
                                ),
                                child: const Text(
                                  'RETOUR',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            // 🆕 Overlay de progression
            if (_isUploading)
              UploadProgressOverlay(
                progress: _uploadProgress,
                message: _uploadProgress < 0.5
                    ? 'Préparation des données...'
                    : 'Envoi au serveur...',
              ),
          ],
        );
      },
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations personnelles',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // Nom - 🆕 Avec validation améliorée
        TextFormField(
          controller: _nomController,
          decoration: const InputDecoration(
            labelText: 'Nom complet *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          validator: Validators.validateName,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
        const SizedBox(height: 16),

        // Téléphone - 🆕 Avec validation ivoirienne
        TextFormField(
          controller: _telephoneController,
          decoration: const InputDecoration(
            labelText: 'Téléphone *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
            hintText: 'Ex: +225 07 07 12 34 56',
          ),
          keyboardType: TextInputType.phone,
          validator: Validators.validateIvorianPhone,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (value) {
            // Formater automatiquement pendant la saisie
            final formatted = Validators.formatIvorianPhone(value);
            if (formatted != value) {
              _telephoneController.text = formatted;
              _telephoneController.selection = TextSelection.fromPosition(
                TextPosition(offset: formatted.length),
              );
            }
          },
        ),
        const SizedBox(height: 16),

        // Email - 🆕 Avec validation regex
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email (optionnel)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
        const SizedBox(height: 16),

        // Notes
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (optionnel)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Localisation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // Position GPS
        if (_currentPosition != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Position GPS détectée',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Adresse
        TextFormField(
          controller: _adresseController,
          decoration: const InputDecoration(
            labelText: 'Adresse',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.home),
          ),
        ),
        const SizedBox(height: 16),

        // Ville
        TextFormField(
          controller: _villeController,
          decoration: const InputDecoration(
            labelText: 'Ville',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_city),
          ),
        ),
        const SizedBox(height: 16),

        // Quartier
        TextFormField(
          controller: _quartierController,
          decoration: const InputDecoration(
            labelText: 'Quartier',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.place),
          ),
        ),
        const SizedBox(height: 16),

        // Position GPS automatique (lecture seule)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            border: Border.all(color: const Color(0xFF1CBF3F)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF1CBF3F)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Position GPS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentPosition != null
                          ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, Long: ${_currentPosition!.longitude.toStringAsFixed(6)}'
                          : 'Position GPS récupérée automatiquement',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF1CBF3F)),
                onPressed: _getCurrentLocation,
                tooltip: 'Actualiser position',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShopInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations boutique',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // Nom de la boutique
        TextFormField(
          controller: _shopNameController,
          decoration: const InputDecoration(
            labelText: 'Nom de la boutique *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.store),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le nom de la boutique';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Description de la boutique
        TextFormField(
          controller: _shopDescriptionController,
          decoration: const InputDecoration(
            labelText: 'Description de la boutique *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            hintText: 'Décrivez votre boutique et vos produits',
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez décrire votre boutique';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProductsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Produits et services',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // Catégories de produits
        const Text(
          'Catégories de produits *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children:
              _productCategories.map((category) {
                final isSelected = _selectedProductCategories.contains(
                  category,
                );
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: const Color(0xFF1CBF3F).withOpacity(0.3),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedProductCategories.add(category);
                      } else {
                        _selectedProductCategories.remove(category);
                      }
                    });
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 20),

        // Types de produits
        const Text(
          'Types de produits *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children:
              _productTypes.map((type) {
                final isSelected = _selectedProductTypes.contains(type);
                return FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  selectedColor: const Color(0xFF1CBF3F).withOpacity(0.3),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedProductTypes.add(type);
                      } else {
                        _selectedProductTypes.remove(type);
                      }
                    });
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 16),

        // Validation
        if (_selectedProductCategories.isEmpty || _selectedProductTypes.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Veuillez sélectionner au moins une catégorie et un type de produit',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildClassificationStep(ClassificationState state) {
    // Utiliser l'état du BLoC au lieu des variables locales
    if (state is ClassificationLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des catégories...'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Classification et Prix',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // Prix normal/moyen
        TextFormField(
          controller: _prixController,
          decoration: const InputDecoration(
            labelText: 'Prix normal/moyen (FCFA)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
            hintText: 'Ex: 5000',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (double.tryParse(value) == null) {
                return 'Veuillez entrer un prix valide';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Sélection de la catégorie (utilise les catégories stockées localement)
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Catégorie *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.label),
          ),
          value: _selectedCategorie,
          hint: const Text('Sélectionner une catégorie'),
          isExpanded: true, // Fix overflow
          items:
              _categories.map((categorie) {
                return DropdownMenuItem<String>(
                  value: categorie.id,
                  child: Text(
                    categorie.nom,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategorie = value;
              _selectedService = null; // Reset service selection
            });
            if (value != null) {
              // Trouver la catégorie sélectionnée pour debug
              var categorieSelectionnee = _categories.firstWhere(
                (cat) => cat.id == value,
                orElse:
                    () => CategorieModel(
                      id: '',
                      nom: 'Inconnue',
                      groupeId: '',
                      imagePath: '',
                    ),
              );
              print(
                '🎯 Catégorie sélectionnée: ${categorieSelectionnee.nom} (ID: $value)',
              );

              context.read<ClassificationBloc>().add(
                LoadServicesByCategory(
                  categoryId: value,
                  categoryName: categorieSelectionnee.nom,
                ),
              );
            }
          },
          validator: (value) {
            if (value == null) {
              return 'Veuillez sélectionner une catégorie';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Sélection du service (chargé selon la catégorie)
        if (_selectedCategorie != null)
          BlocBuilder<ClassificationBloc, ClassificationState>(
            builder: (context, serviceState) {
              if (serviceState is ServicesLoaded) {
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Service *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                  value: _selectedService,
                  hint: const Text('Sélectionner un service'),
                  isExpanded: true, // Fix overflow
                  items:
                      serviceState.services.map((service) {
                        return DropdownMenuItem<String>(
                          value: service.id,
                          child: Text(
                            service.nom,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedService = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Veuillez sélectionner un service';
                    }
                    return null;
                  },
                );
              } else if (serviceState is ClassificationLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              } else {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Aucun service disponible'),
                );
              }
            },
          ),
      ],
    );
  }

  Widget _buildPhotoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos et Documents',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // Photo principale
        _buildPhotoSection(
          'Photo du prestataire',
          _photoFile,
          _takePhoto,
          'Photo optionnelle',
        ),
        const SizedBox(height: 24),

        // CNI Recto
        _buildPhotoSection(
          'CNI Recto',
          _cniRectoFile,
          _takeCniRecto,
          'Document optionnel',
        ),
        const SizedBox(height: 24),

        // CNI Verso
        _buildPhotoSection(
          'CNI Verso',
          _cniVersoFile,
          _takeCniVerso,
          'Document optionnel',
        ),
      ],
    );
  }

  Widget _buildPhotoSection(
    String title,
    File? file,
    VoidCallback onTap,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              if (file != null)
                Container(
                  height: 150,
                  width: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(file, fit: BoxFit.cover),
                  ),
                )
              else
                Container(
                  height: 150,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Aucune photo'),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.camera_alt),
                label: Text('Prendre $title'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1CBF3F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Récapitulatif',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Column(
            children: [
              _buildReviewItem('Nom', _nomController.text),
              _buildReviewItem('Téléphone', _telephoneController.text),
              if (_emailController.text.isNotEmpty)
                _buildReviewItem('Email', _emailController.text),
              if (_adresseController.text.isNotEmpty)
                _buildReviewItem('Adresse', _adresseController.text),
              if (_villeController.text.isNotEmpty)
                _buildReviewItem('Ville', _villeController.text),
              if (_quartierController.text.isNotEmpty)
                _buildReviewItem('Quartier', _quartierController.text),
              _buildReviewItem('Groupe', _getGroupeName()),
              if (_selectedCategorie != null)
                _buildReviewItem(
                  'Catégorie',
                  _categories
                      .firstWhere(
                        (c) => c.id == _selectedCategorie,
                        orElse:
                            () => CategorieModel(
                              id: '',
                              nom: 'Non trouvée',
                              groupeId: '',
                              imagePath: '',
                            ),
                      )
                      .nom,
                ),
              if (_selectedService != null)
                _buildReviewItem(
                  'Service',
                  _services
                      .firstWhere(
                        (s) => s.id == _selectedService,
                        orElse:
                            () => ServiceModel(
                              id: '',
                              nom: 'Non trouvé',
                              categorieId: '',
                              imagePath: '',
                              prixMoyen: '',
                            ),
                      )
                      .nom,
                ),
              if (_prixController.text.isNotEmpty)
                _buildReviewItem('Prix', '${_prixController.text} FCFA'),

              // Champs spécifiques au vendeur
              if (widget.type == 'vendeur') ...[
                if (_shopNameController.text.isNotEmpty)
                  _buildReviewItem('Nom boutique', _shopNameController.text),
                if (_shopDescriptionController.text.isNotEmpty)
                  _buildReviewItem(
                    'Description boutique',
                    _shopDescriptionController.text,
                  ),
                if (_selectedProductCategories.isNotEmpty)
                  _buildReviewItem(
                    'Catégories produits',
                    _selectedProductCategories.join(', '),
                  ),
                if (_selectedProductTypes.isNotEmpty)
                  _buildReviewItem(
                    'Types produits',
                    _selectedProductTypes.join(', '),
                  ),
              ],

              if (_photoFile != null) _buildReviewItem('Photo', 'Photo prise'),
              if (_cniRectoFile != null)
                _buildReviewItem('CNI Recto', 'Document fourni'),
              if (_cniVersoFile != null)
                _buildReviewItem('CNI Verso', 'Document fourni'),
              if (_currentPosition != null)
                _buildReviewItem(
                  'Position GPS',
                  'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
