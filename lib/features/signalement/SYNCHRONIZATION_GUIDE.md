# Guide de Synchronisation pour les Signalements

## Vue d'ensemble

Le système de synchronisation pour les signalements a été implémenté en s'inspirant du système des projets, avec les mêmes fonctionnalités :

- **Synchronisation intelligente** avec checksums SHA256
- **Cache local** avec Hive pour fonctionnement hors ligne
- **Filtrage local** instantané (comme WhatsApp)
- **Sync différentielle** pour optimiser les transferts réseau
- **Notifications contextuelles** pour l'UX

## Structure des fichiers

```
lib/features/signalement/
├── services/
│   ├── report_local_storage_service.dart    # Stockage local Hive
│   ├── report_sync_service.dart             # Logique de synchronisation
│   └── report_checksum_service.dart         # Calculs de checksums
├── models/
│   ├── sync_models.dart                     # Modèles de synchronisation
│   └── report_model.dart                    # Modèle principal (mis à jour)
├── controllers/
│   ├── sync_report_controller.dart          # Controller avec sync (nouveau)
│   └── report_controller.dart               # Controller legacy
└── data_sources/
    └── report_data_source.dart              # API calls (mis à jour)
```

## Utilisation dans une page

```dart
// 1. Importer le nouveau controller
import 'package:provider/provider.dart';
import '../controllers/sync_report_controller.dart';

// 2. Dans votre widget
class SignalementsPage extends StatefulWidget {
  @override
  _SignalementsPageState createState() => _SignalementsPageState();
}

class _SignalementsPageState extends State<SignalementsPage> {
  late SyncReportController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Provider.of<SyncReportController>(context, listen: false);
    
    // Chargement initial avec synchronisation intelligente
    _loadReports();
  }

  Future<void> _loadReports() async {
    await _controller.fetchReports(
      useSync: true,              // Utiliser la synchronisation
      showNotifications: true,    // Afficher les notifications
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Signalements'),
        actions: [
          // Bouton de refresh manuel
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _controller.smartSync(),
          ),
        ],
      ),
      body: Consumer<SyncReportController>(
        builder: (context, controller, child) {
          // Afficher la notification de sync si nécessaire
          if (controller.notificationType != SyncNotificationType.none) {
            return Column(
              children: [
                SyncNotification(
                  type: controller.notificationType,
                  message: controller.notificationMessage,
                  onDismiss: () => controller.clearNotification(),
                ),
                Expanded(child: _buildReportsList(controller)),
              ],
            );
          }
          
          return _buildReportsList(controller);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFilters(),
        child: Icon(Icons.filter_list),
      ),
    );
  }

  Widget _buildReportsList(SyncReportController controller) {
    if (controller.isLoadingReports && controller.reports.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    if (controller.reports.isEmpty) {
      return Center(child: Text('Aucun signalement'));
    }

    return RefreshIndicator(
      onRefresh: () => controller.smartSync(),
      child: ListView.builder(
        itemCount: controller.reports.length,
        itemBuilder: (context, index) {
          final report = controller.reports[index];
          return ReportCard(report: report);
        },
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => FilterPanel(
        controller: _controller,
      ),
    );
  }
}
```

## Panel de filtres

```dart
class FilterPanel extends StatefulWidget {
  final SyncReportController controller;

  const FilterPanel({Key? key, required this.controller}) : super(key: key);

  @override
  _FilterPanelState createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtrer les signalements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          
          // Filtre par statut
          DropdownButton<ReportStatus?>(
            value: widget.controller.currentStatusFilter,
            hint: Text('Statut'),
            isExpanded: true,
            onChanged: (status) {
              widget.controller.applyStatusFilter(status);
              setState(() {});
            },
            items: [
              DropdownMenuItem(value: null, child: Text('Tous les statuts')),
              ...ReportStatus.values.map((status) => 
                DropdownMenuItem(value: status, child: Text(status.toString()))
              ),
            ],
          ),
          
          // Filtre par priorité
          DropdownButton<PriorityLevel?>(
            value: widget.controller.currentPriorityFilter,
            hint: Text('Priorité'),
            isExpanded: true,
            onChanged: (priority) {
              widget.controller.applyPriorityFilter(priority);
              setState(() {});
            },
            items: [
              DropdownMenuItem(value: null, child: Text('Toutes les priorités')),
              ...PriorityLevel.values.map((priority) => 
                DropdownMenuItem(value: priority, child: Text(priority.toString()))
              ),
            ],
          ),
          
          // Recherche
          TextField(
            decoration: InputDecoration(labelText: 'Rechercher'),
            onChanged: (text) => widget.controller.applySearchFilter(text),
          ),
          
          // Boutons d'action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => widget.controller.clearAllFilters(),
                child: Text('Effacer'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fermer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

## Configuration dans le provider

```dart
// Dans votre main.dart ou provider setup
MultiProvider(
  providers: [
    // Autres providers...
    ChangeNotifierProvider<SyncReportController>(
      create: (_) => SyncReportController(),
    ),
  ],
  child: MyApp(),
)
```

## API Request/Response

### Requête de synchronisation
```json
{
  "global_checksum": "2b71d863e00ad5d722bd715f75d3a6c74a8ed3d97fa8cbdf2d0f412791712ea8",
  "items_checksums": [
    {
      "id": "11f4e32b-6728-4a76-b2e6-0ced6cc4f67f",
      "checksum": "e120c7f731f6d7a944c5ff04f3ae96095dd5181764718a4ef288af0a055b5716"
    }
  ]
}
```

### Réponse différentielle
```json
{
  "success": true,
  "data": {
    "sync_type": "differential",
    "changes": {
      "added": [[{
        "id": "new-report-id",
        "checksum": "abc123...",
        "title": "Speed bump needed",
        "description": "...",
        "report_type": "infrastructure",
        "status": "pending"
      }]],
      "updated": [],
      "deleted": []
    }
  }
}
```

## Fonctionnalités clés

### 1. Synchronisation intelligente
- **Full sync** : Premier chargement ou force refresh
- **Check sync** : Vérification par checksums
- **Filter sync** : Application de nouveaux filtres

### 2. Cache local
- Stockage Hive avec 2 boxes : `report_checksums` et `cached_reports`
- Fonctionne hors ligne
- Ordre de réception préservé

### 3. Filtrage local
- Filtres appliqués instantanément en mémoire
- Pas de requêtes API répétées
- Compatible avec recherche textuelle

### 4. Notifications UX
- État de synchronisation visible
- Mode hors ligne indiqué
- Progression des opérations

### 5. Performance
- Sync différentielle minimise les transferts
- Cache local pour accès instantané
- Filtrage en mémoire ultra-rapide

## Points d'attention

1. **Génération des adaptateurs** : Exécuter `dart run build_runner build` après modification des modèles
2. **TypeId Hive** : Utiliser des IDs uniques (2,3 pour reports vs 0,1 pour projects)
3. **Ordre de réception** : Préservé pour cohérence avec l'API Laravel
4. **Checksums API** : Utiliser ceux fournis par l'API, ne pas recalculer

Cette implémentation fournit une expérience utilisateur fluide avec synchronisation transparente et fonctionnement optimal hors ligne.