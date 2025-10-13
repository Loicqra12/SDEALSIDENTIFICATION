import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/local_storage_service.dart';

class TypeSelectionScreen extends StatefulWidget {
  const TypeSelectionScreen({super.key});

  @override
  State<TypeSelectionScreen> createState() => _TypeSelectionScreenState();
}

class _TypeSelectionScreenState extends State<TypeSelectionScreen> {
  Map<String, int> _counters = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounters();
  }

  Future<void> _loadCounters() async {
    try {
      final recensements = await LocalStorageService.getAllRecensements();
      
      final prestataireCount = recensements.where((r) => r.type == 'prestataire').length;
      final freelanceCount = recensements.where((r) => r.type == 'freelance').length;
      final vendeurCount = recensements.where((r) => r.type == 'vendeur').length;
      
      setState(() {
        _counters = {
          'prestataire': prestataireCount,
          'freelance': freelanceCount,
          'vendeur': vendeurCount,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement compteurs: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner le type'),
        backgroundColor: const Color(0xFF1CBF3F),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed:
              () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(44),
            bottomRight: Radius.circular(44),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choisissez le type de recensement',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1CBF3F),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Prestataire
            _buildTypeCard(
              context,
              title: 'Prestataire',
              subtitle: 'Artisans, réparateurs, services à domicile',
              icon: Icons.build,
              color: Colors.blue,
              count: _counters['prestataire'] ?? 0,
              onTap: () => context.push('/recensement-form?type=prestataire'),
            ),

            const SizedBox(height: 16),

            // Freelance
            _buildTypeCard(
              context,
              title: 'Freelance',
              subtitle: 'Travailleurs indépendants, consultants',
              icon: Icons.work,
              color: Colors.orange,
              count: _counters['freelance'] ?? 0,
              onTap: () => context.push('/recensement-form?type=freelance'),
            ),

            const SizedBox(height: 16),

            // Vendeur
            _buildTypeCard(
              context,
              title: 'Vendeur',
              subtitle: 'Commerçants, boutiques, e-commerce',
              icon: Icons.store,
              color: Colors.purple,
              count: _counters['vendeur'] ?? 0,
              onTap: () => context.push('/recensement-form?type=vendeur'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int count = 0,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1CBF3F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (count > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count recensé${count > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
