import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/local_storage_service.dart';
import '../services/points_service.dart';
import '../services/sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _progressInfo = {};
  bool _isLoading = true;
  String _userName = 'Recenseur';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    // TODO: Récupérer depuis SharedPreferences ou AuthCubit
    // Pour l'instant, valeur par défaut
    setState(() {
      _userName = 'Recenseur';
      _userEmail = 'recenseur@soutralideals.com';
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final stats = await LocalStorageService.getLocalStats();
      final progressInfo = await PointsService.getProgressInfo();

      setState(() {
        _stats = stats;
        _progressInfo = progressInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: const Color(0xFF1CBF3F),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            try {
              context.pop();
            } catch (e) {
              context.go('/dashboard');
            }
          },
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(44),
            bottomRight: Radius.circular(44),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Section Profil
                    _buildSection(
                      title: 'Profil',
                      children: [_buildProfileCard()],
                    ),

                    // Section Statistiques
                    _buildSection(
                      title: 'Statistiques',
                      children: [_buildStatsCard()],
                    ),

                    // Section Progression
                    _buildSection(
                      title: 'Progression',
                      children: [_buildProgressCard()],
                    ),

                    // Section Paramètres
                    _buildSection(
                      title: 'Paramètres',
                      children: [_buildSettingsList()],
                    ),

                    // Section Actions
                    _buildSection(
                      title: 'Actions',
                      children: [_buildActionsList()],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1CBF3F),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF1CBF3F).withOpacity(0.1),
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'R',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1CBF3F),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _userName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (_userEmail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _userEmail,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Niveau ${_progressInfo['level'] ?? 1}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF1CBF3F),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showComingSoon('Édition du profil'),
              icon: const Icon(Icons.edit),
              label: const Text('Modifier le profil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1CBF3F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Recensements',
                  '${_stats['totalRecensements'] ?? 0}',
                  Icons.list_alt,
                ),
                _buildStatItem(
                  'Synchronisés',
                  '${_stats['synced'] ?? 0}',
                  Icons.sync,
                ),
                _buildStatItem(
                  'En attente',
                  '${_stats['pendingSync'] ?? 0}',
                  Icons.schedule,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1CBF3F), size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1CBF3F),
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    final points = _progressInfo['points'] ?? 0;
    final level = _progressInfo['level'] ?? 1;
    final pointsToNext = _progressInfo['pointsToNextLevel'] ?? 0;
    final progress = _progressInfo['levelProgress'] ?? 0.0;
    final badges = _progressInfo['badges'] ?? <String>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Niveau $level',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$points points',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF1CBF3F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF1CBF3F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pointsToNext > 0
                  ? '$pointsToNext points pour le niveau suivant'
                  : 'Niveau maximum atteint !',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  '${badges.length} badges obtenus',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList() {
    return Card(
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Gérer les notifications',
            onTap: () => _showComingSoon('Notifications'),
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.language,
            title: 'Langue',
            subtitle: 'Français',
            onTap: () => _showComingSoon('Langue'),
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.dark_mode,
            title: 'Thème',
            subtitle: 'Système',
            onTap: () => _showComingSoon('Thème'),
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.storage,
            title: 'Stockage',
            subtitle: 'Gérer l\'espace de stockage',
            onTap: () => _showStorageInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1CBF3F)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildActionsList() {
    return Card(
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.sync,
            title: 'Synchroniser maintenant',
            subtitle: 'Envoyer les données en attente',
            onTap: _performSync,
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.download,
            title: 'Exporter les données',
            subtitle: 'Télécharger vos recensements',
            onTap: () => _showComingSoon('Export'),
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.refresh,
            title: 'Actualiser',
            subtitle: 'Recharger les données',
            onTap: _loadData,
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.delete_forever,
            title: 'Effacer toutes les données',
            subtitle: 'Attention: action irréversible',
            onTap: _showResetDialog,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF1CBF3F),
      ),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : null),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Future<void> _performSync() async {
    // Afficher dialog de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Synchronisation en cours...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Appeler la synchronisation (retourne void)
      await SyncService.forceSync();
      
      if (mounted) {
        context.pop(); // Fermer dialog chargement

        // Récupérer les stats pour voir combien ont été synchronisés
        final stats = await LocalStorageService.getLocalStats();
        final pendingCount = stats['pendingSync'] ?? 0;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pendingCount == 0
                  ? '✅ Synchronisation terminée avec succès'
                  : '⚠️ $pendingCount recensement(s) encore en attente',
            ),
            backgroundColor: pendingCount == 0 ? Colors.green : Colors.orange,
          ),
        );
        
        // Recharger les données
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        context.pop(); // Fermer dialog chargement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur de synchronisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('$feature'),
            content: const Text(
              'Cette fonctionnalité sera bientôt disponible.',
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showStorageInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Informations de stockage'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recensements: ${_stats['totalRecensements'] ?? 0}'),
                Text('Données en attente: ${_stats['pendingSync'] ?? 0}'),
                Text('Brouillons: ${_stats['draft'] ?? 0}'),
                const SizedBox(height: 16),
                const Text(
                  'Les données sont stockées localement sur votre appareil et synchronisées avec le serveur quand possible.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Effacer toutes les données'),
            content: const Text(
              'Cette action supprimera définitivement tous vos recensements et paramètres. Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  context.pop();
                  await LocalStorageService.clearAllData();
                  await PointsService.reset();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Toutes les données ont été effacées'),
                      ),
                    );
                    _loadData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Effacer'),
              ),
            ],
          ),
    );
  }
}
