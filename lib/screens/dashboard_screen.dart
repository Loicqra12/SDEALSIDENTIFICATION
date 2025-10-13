import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/recensement_model.dart';
import '../services/local_storage_service.dart';
import '../services/points_service.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _progress = {};
  List<RecensementModel> _recentRecensements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // 🆕 Charger depuis MongoDB au lieu du local
      final backendData = await ApiService.getRecensementsFromBackend();
      
      // Calculer les stats depuis les données backend
      final totalRecensements = backendData.length;
      final syncedRecensements = backendData.where((r) => r['status'] == 'active').length;
      final pendingRecensements = backendData.where((r) => r['status'] == 'pending').length;
      
      final stats = {
        'totalRecensements': totalRecensements,
        'syncedRecensements': syncedRecensements,
        'pendingSync': pendingRecensements,
      };
      
      // Points et progression
      final progress = await PointsService.getProgressInfo();
      
      // Convertir les 5 plus récents en RecensementModel
      final recent = backendData.take(5).map((data) {
        return RecensementModel(
          id: data['id'] ?? '',
          type: data['type'] ?? 'prestataire',
          nom: data['nom'] ?? '',
          telephone: data['telephone'] ?? '',
          email: '',
          adresse: data['localisation'] ?? '',
          ville: '',
          quartier: '',
          groupe: _getGroupeFromType(data['type'] ?? 'prestataire'),
          categorie: '',
          service: data['service'] ?? '',
          latitude: 0,
          longitude: 0,
          recenseurId: '',
          recenseurNom: 'Recenseur',
          dateRecensement: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
          synced: data['status'] == 'active',
          backendId: data['id'],
          status: data['status'] ?? 'pending',
          localisation: data['localisation'] ?? '',
        );
      }).toList();

      setState(() {
        _stats = stats;
        _progress = progress;
        _recentRecensements = recent;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement dashboard depuis backend: $e');
      
      // Fallback: charger depuis le local
      try {
        final stats = await LocalStorageService.getLocalStats();
        final progress = await PointsService.getProgressInfo();
        final allRecensements = await LocalStorageService.getAllRecensements();
        final recent = allRecensements.take(5).toList();

        setState(() {
          _stats = stats;
          _progress = progress;
          _recentRecensements = recent;
          _isLoading = false;
        });
      } catch (localError) {
        print('Erreur chargement local: $localError');
        setState(() => _isLoading = false);
      }
    }
  }

  String _getGroupeFromType(String type) {
    switch (type) {
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Soutrali Recensement',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1CBF3F),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Soutrali Recensement',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1CBF3F),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadDashboardData();
            },
            tooltip: 'Rafraîchir',
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              // Navigation vers le profil
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section de bienvenue
            _buildWelcomeSection(),
            const SizedBox(height: 24),

            // Statistiques
            _buildStatsSection(),
            const SizedBox(height: 24),

            // Bouton principal de recensement
            _buildMainActionButton(context),
            const SizedBox(height: 24),

            // Options rapides
            _buildQuickActions(context),
            const SizedBox(height: 24),

            // Historique récent
            _buildRecentHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1CBF3F), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bienvenue !',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Commencez à recenser des prestataires, freelances et vendeurs dans votre région.',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Niveau ${_progress['level'] ?? 1} - ${_getLevelName(_progress['level'] ?? 1)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Recensements',
            '${_stats['totalRecensements'] ?? 0}',
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Points',
            '${_progress['points'] ?? 0}',
            Icons.stars,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Badges',
            '${(_progress['badges'] as List?)?.length ?? 0}',
            Icons.emoji_events,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMainActionButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1CBF3F), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go('/type-selection'),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, size: 40, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'NOUVEAU RECENSEMENT',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Commencer à recenser',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Historique',
                Icons.history,
                Colors.orange,
                () => context.go('/history'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Paramètres',
                Icons.settings,
                Colors.grey,
                () => context.go('/settings'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recensements récents',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (_recentRecensements.isNotEmpty)
              TextButton(
                onPressed: () => context.go('/history'),
                child: const Text('Voir tout'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentRecensements.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Aucun recensement pour le moment',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    'Commencez par recenser quelqu\'un !',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ..._recentRecensements.map((recensement) => _buildRecentCard(recensement)),
      ],
    );
  }

  Widget _buildRecentCard(RecensementModel recensement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(recensement.status).withOpacity(0.1),
          child: Icon(
            _getTypeIcon(recensement.type),
            color: _getStatusColor(recensement.status),
          ),
        ),
        title: Text(
          recensement.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${recensement.type} • ${recensement.telephone}'),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        onTap: () => context.go('/history'),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'prestataire':
        return Icons.build;
      case 'freelance':
        return Icons.work;
      case 'vendeur':
        return Icons.store;
      default:
        return Icons.person;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'synced':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getLevelName(int level) {
    if (level <= 1) return 'Débutant';
    if (level <= 3) return 'Intermédiaire';
    if (level <= 5) return 'Avancé';
    if (level <= 7) return 'Expert';
    return 'Maître';
  }
}








