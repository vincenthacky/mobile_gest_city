import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/project_controller.dart';
import '../models/sync_models.dart';

/// Exemple d'utilisation de la fonctionnalité de synchronisation
class SyncUsageExample extends StatefulWidget {
  const SyncUsageExample({super.key});

  @override
  State<SyncUsageExample> createState() => _SyncUsageExampleState();
}

class _SyncUsageExampleState extends State<SyncUsageExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exemples de Synchronisation')),
      body: Consumer<ProjectController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status de sync
                _buildSyncStatus(controller),
                const SizedBox(height: 20),
                
                // Actions de sync
                _buildSyncActions(controller),
                const SizedBox(height: 20),
                
                // Exemples d'utilisation
                _buildUsageExamples(controller),
                const SizedBox(height: 20),
                
                // Statistiques
                _buildStats(controller),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSyncStatus(ProjectController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('État de synchronisation', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(
                  _getSyncStatusIcon(controller.syncStatus),
                  color: _getSyncStatusColor(controller.syncStatus),
                ),
                const SizedBox(width: 8),
                Text('Status: ${controller.syncStatus.name}'),
              ],
            ),
            
            if (controller.isSyncing)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
              
            if (controller.syncMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('✅ ${controller.syncMessage}',
                  style: const TextStyle(color: Colors.green)),
              ),
              
            if (controller.syncErrorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('❌ ${controller.syncErrorMessage}',
                  style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncActions(ProjectController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Actions de synchronisation', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: controller.isSyncing ? null : () {
                    // Synchronisation intelligente automatique
                    controller.smartSync();
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync Auto'),
                ),
                
                ElevatedButton.icon(
                  onPressed: controller.isSyncing ? null : () {
                    // Force une synchronisation complète
                    controller.forceFullSync();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Sync Complète'),
                ),
                
                ElevatedButton.icon(
                  onPressed: controller.isSyncing ? null : () {
                    // Sync avec filtre
                    final filters = SyncFilters(status: 'vote_open');
                    controller.syncWithFilters(filters);
                  },
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Sync Filtrée'),
                ),
                
                ElevatedButton.icon(
                  onPressed: controller.isSyncing ? null : () {
                    // Utiliser fetchProjects avec sync activée (défaut)
                    controller.fetchProjects();
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Fetch + Sync'),
                ),
                
                ElevatedButton.icon(
                  onPressed: controller.isSyncing ? null : () {
                    // Utiliser fetchProjects sans sync (mode legacy)
                    controller.fetchProjects(useSync: false);
                  },
                  icon: const Icon(Icons.download_done),
                  label: const Text('Fetch Legacy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageExamples(ProjectController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cas d\'usage typiques', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            const Text('1. Ouverture de l\'app (première fois)', 
              style: TextStyle(fontWeight: FontWeight.w600)),
            const Text('→ Sync automatique complète'),
            const SizedBox(height: 8),
            
            const Text('2. Ouverture de l\'app (données existantes)', 
              style: TextStyle(fontWeight: FontWeight.w600)),
            const Text('→ Sync intelligente avec checksums'),
            const SizedBox(height: 8),
            
            const Text('3. Application de filtres', 
              style: TextStyle(fontWeight: FontWeight.w600)),
            const Text('→ Sync avec filtres uniquement'),
            const SizedBox(height: 8),
            
            const Text('4. Pull to refresh', 
              style: TextStyle(fontWeight: FontWeight.w600)),
            const Text('→ Sync intelligente automatique'),
            const SizedBox(height: 8),
            
            const Text('5. Problème de réseau', 
              style: TextStyle(fontWeight: FontWeight.w600)),
            const Text('→ Fallback vers données locales'),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(ProjectController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Actions de maintenance', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final stats = await controller.getSyncStats();
                    if (mounted) {
                      _showStatsDialog(stats);
                    }
                  },
                  icon: const Icon(Icons.analytics),
                  label: const Text('Voir Stats'),
                ),
                const SizedBox(width: 8),
                
                ElevatedButton.icon(
                  onPressed: () async {
                    final validation = await controller.validateLocalData();
                    if (mounted) {
                      _showValidationDialog(validation);
                    }
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Valider'),
                ),
                const SizedBox(width: 8),
                
                ElevatedButton.icon(
                  onPressed: () async {
                    await controller.clearSyncData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Données de sync effacées'))
                      );
                    }
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Nettoyer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStatsDialog(Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques de synchronisation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total checksums: ${stats['total_checksums']}'),
            Text('Checksums récents: ${stats['recent_checksums']}'),
            if (stats['oldest_checksum'] != null)
              Text('Plus ancien: ${stats['oldest_checksum']}'),
            if (stats['newest_checksum'] != null)
              Text('Plus récent: ${stats['newest_checksum']}'),
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

  void _showValidationDialog(SyncValidation validation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(validation.isValid ? 'Validation réussie' : 'Problèmes détectés'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(validation.summary),
            if (validation.issues.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Problèmes:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...validation.issues.map((issue) => Text('• $issue')),
            ],
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

  IconData _getSyncStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return Icons.sync_disabled;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.success:
        return Icons.check_circle;
      case SyncStatus.error:
        return Icons.error;
    }
  }

  Color _getSyncStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return Colors.grey;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.success:
        return Colors.green;
      case SyncStatus.error:
        return Colors.red;
    }
  }
}