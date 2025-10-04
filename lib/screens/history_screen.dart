import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/recensement_model.dart';
import '../services/local_storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<RecensementModel> _recensements = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadRecensements();
  }

  Future<void> _loadRecensements() async {
    setState(() => _isLoading = true);

    try {
      final allRecensements = await LocalStorageService.getAllRecensements();
      setState(() {
        _recensements = allRecensements;
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

  List<RecensementModel> get _filteredRecensements {
    switch (_selectedFilter) {
      case 'synced':
        return _recensements.where((r) => r.status == 'synced').toList();
      case 'pending':
        return _recensements.where((r) => r.status == 'pending').toList();
      case 'draft':
        return _recensements.where((r) => r.status == 'draft').toList();
      default:
        return _recensements;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'synced':
        return 'Synchronisé';
      case 'pending':
        return 'En attente';
      case 'draft':
        return 'Brouillon';
      default:
        return 'Inconnu';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Recensements'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadRecensements,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filtrer par statut',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tous')),
                      DropdownMenuItem(
                        value: 'synced',
                        child: Text('Synchronisés'),
                      ),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('En attente'),
                      ),
                      DropdownMenuItem(
                        value: 'draft',
                        child: Text('Brouillons'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value ?? 'all';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_filteredRecensements.length} recensements',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          // Liste des recensements
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredRecensements.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      itemCount: _filteredRecensements.length,
                      itemBuilder: (context, index) {
                        final recensement = _filteredRecensements[index];
                        return _buildRecensementCard(recensement);
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/recensement-form'),
        backgroundColor: const Color(0xFF1CBF3F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun recensement trouvé',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par effectuer votre premier recensement',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/recensement-form'),
            icon: const Icon(Icons.add),
            label: const Text('Nouveau Recensement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1CBF3F),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecensementCard(RecensementModel recensement) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${recensement.type}'),
            Text('Téléphone: ${recensement.telephone}'),
            if (recensement.localisation.isNotEmpty)
              Text('Localisation: ${recensement.localisation}'),
            Text(
              'Date: ${_formatDate(recensement.dateRecensement)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(recensement.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(recensement.status),
                style: TextStyle(
                  color: _getStatusColor(recensement.status),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
        onTap: () => _showRecensementDetails(recensement),
      ),
    );
  }

  void _showRecensementDetails(RecensementModel recensement) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Détails du Recensement'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Nom', recensement.nom),
                  _buildDetailRow('Type', recensement.type),
                  _buildDetailRow('Téléphone', recensement.telephone),
                  if (recensement.localisation.isNotEmpty)
                    _buildDetailRow('Localisation', recensement.localisation),
                  _buildDetailRow('Statut', _getStatusText(recensement.status)),
                  _buildDetailRow('Recenseur', recensement.recenseurNom),
                  _buildDetailRow(
                    'Date',
                    _formatDate(recensement.dateRecensement),
                  ),
                  if (recensement.photoPath != null &&
                      recensement.photoPath!.isNotEmpty)
                    _buildDetailRow('Photo', 'Photo disponible'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Fermer'),
              ),
              if (recensement.status == 'draft')
                ElevatedButton(
                  onPressed: () {
                    context.pop();
                    // TODO: Naviguer vers l'édition du recensement
                  },
                  child: const Text('Modifier'),
                ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
