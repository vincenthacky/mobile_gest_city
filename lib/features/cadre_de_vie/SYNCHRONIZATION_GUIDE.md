# Guide de Synchronisation pour le Cadre de Vie (Informations)

## Vue d'ensemble

Le système de synchronisation pour les informations du cadre de vie a été implémenté en utilisant la même architecture robuste que les projets et signalements :

- **Synchronisation intelligente** avec checksums SHA256
- **Cache local** avec Hive pour fonctionnement hors ligne  
- **Filtrage local** instantané (WhatsApp style)
- **Sync différentielle** optimisée pour les transferts réseau
- **Notifications contextuelles** pour une UX fluide

## Structure des fichiers

```
lib/features/cadre_de_vie/
├── services/
│   ├── information_local_storage_service.dart    # Stockage local Hive
│   ├── information_sync_service.dart             # Logique de synchronisation
│   └── information_checksum_service.dart         # Calculs de checksums
├── models/
│   ├── sync_models.dart                          # Modèles de synchronisation
│   └── information_model.dart                    # Modèle principal (mis à jour)
├── controllers/
│   ├── sync_information_controller.dart          # Controller avec sync (nouveau)
│   └── information_controller.dart               # Controller legacy
└── data_sources/
    └── information_data_source.dart              # API calls (mis à jour)
```

## API Configuration

### Endpoint de synchronisation
```
POST /information/sync
```

### Format de requête (identique aux projets)
```json
{
  "global_checksum": "2afb966cb565029eb613da2e2748d7c6bd24a3070034e07ee24ed6625894f34f",
  "items_checksums": [
    {
      "id": "907ea86f-f228-406a-a187-80bdfec7ae01",
      "checksum": "e4b0e9be7800cc1b06c559b226e8bed43167e93123178962006a3ae4aa4f7b98"
    }
  ]
}
```

### Réponse différentielle
```json
{
  "success": true,
  "status_code": 200,
  "message": "Synchronization completed",
  "data": {
    "sync_type": "differential",
    "global_checksum": "...",
    "changes": {
      "added": [[{
        "id": "907ea86f-f228-406a-a187-80bdfec7ae01",
        "checksum": "e4b0e9be7800cc1b06c559b226e8bed43167e93123178962006a3ae4aa4f7b98",
        "title": "Late Night Patrol Schedule",
        "description": "Security patrols will be increased during late night hours (11 PM - 5 AM) for enhanced safety.",
        "report_type": "security",
        "status": "pending",
        "place": "All Community Areas",
        "priority": "high",
        "reported_by": "dc13ecd4-f898-4e24-811c-54051800fdfd",
        "created_at": "2025-11-12 09:28:41",
        "updated_at": "2025-11-12 09:28:41",
        "new": true,
        "images": [],
        "user": {
          "id": "dc13ecd4-f898-4e24-811c-54051800fdfd",
          "full_name": "Trisha Dibbert DVM",
          "villa": {
            "id": "daca4e59-aecc-430f-8ddf-323852130e19",
            "number": "Villa-878"
          }
        }
      }]],
      "updated": [],
      "deleted": []
    },
    "stats": {
      "added_count": 20,
      "updated_count": 0,
      "deleted_count": 0
    }
  }
}
```

## Configuration Hive

Le système utilise des TypeId uniques pour éviter les conflits :

- **TypeId 4** : `InformationChecksum` 
- **TypeId 5** : `CachedInformation`

### Boxes Hive
- `information_checksums` : Checksums pour détection des changements
- `cached_informations` : Informations complètes en cache

## Utilisation dans l'application

### 1. Configuration du Provider

```dart
// Dans votre main.dart ou provider setup
MultiProvider(
  providers: [
    // Autres providers...
    ChangeNotifierProvider<SyncInformationController>(
      create: (_) => SyncInformationController(),
    ),
  ],
  child: MyApp(),
)
```

### 2. Page d'informations avec synchronisation

```dart
import 'package:provider/provider.dart';
import '../controllers/sync_information_controller.dart';

class CadreDeViePage extends StatefulWidget {
  @override
  _CadreDeViePageState createState() => _CadreDeViePageState();
}

class _CadreDeViePageState extends State<CadreDeViePage> {
  late SyncInformationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Provider.of<SyncInformationController>(context, listen: false);
    
    // Chargement initial avec synchronisation intelligente
    _loadInformations();
  }

  Future<void> _loadInformations() async {
    await _controller.fetchInformations(
      useSync: true,              // Utiliser la synchronisation
      showNotifications: true,    // Afficher les notifications
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cadre de Vie'),
        actions: [
          // Bouton de refresh manuel
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _controller.smartSync(),
          ),
          // Bouton de filtres
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilters(),
          ),
        ],
      ),
      body: Consumer<SyncInformationController>(
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
                Expanded(child: _buildInformationsList(controller)),
              ],
            );
          }
          
          return _buildInformationsList(controller);
        },
      ),
    );
  }

  Widget _buildInformationsList(SyncInformationController controller) {
    if (controller.isLoadingInformations && controller.informations.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    if (controller.informations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucune information disponible'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.smartSync(),
              child: Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.smartSync(),
      child: ListView.builder(
        itemCount: controller.informations.length,
        itemBuilder: (context, index) {
          final information = controller.informations[index];
          return InformationCard(information: information);
        },
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => InformationFilterPanel(
        controller: _controller,
      ),
    );
  }
}
```

### 3. Widget de carte d'information

```dart
class InformationCard extends StatelessWidget {
  final InformationModel information;

  const InformationCard({Key? key, required this.information}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec type et priorité
            Row(
              children: [
                Icon(information.typeIcon, color: information.priorityColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    information.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: information.priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: information.priorityColor),
                  ),
                  child: Text(
                    information.priorityText,
                    style: TextStyle(
                      color: information.priorityColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8),
            
            // Description
            Text(
              information.description,
              style: TextStyle(color: Colors.grey[600]),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            SizedBox(height: 12),
            
            // Métadonnées
            Row(
              children: [
                if (information.place != null) ...[
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      information.place!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                
                // Badge nouveau
                if (information.isNew)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'NOUVEAU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: 8),
            
            // Footer avec auteur et date
            Row(
              children: [
                Expanded(
                  child: Text(
                    information.authorText,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                Text(
                  information.formattedDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### 4. Panel de filtres

```dart
class InformationFilterPanel extends StatefulWidget {
  final SyncInformationController controller;

  const InformationFilterPanel({Key? key, required this.controller}) : super(key: key);

  @override
  _InformationFilterPanelState createState() => _InformationFilterPanelState();
}

class _InformationFilterPanelState extends State<InformationFilterPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtrer les informations', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          SizedBox(height: 16),
          
          // Filtre par statut
          _buildDropdown<InformationStatus?>(
            'Statut',
            widget.controller.currentStatusFilter,
            [
              _buildDropdownItem(null, 'Tous les statuts'),
              ...InformationStatus.values.map((status) => 
                _buildDropdownItem(status, _getStatusText(status))
              ),
            ],
            (value) => widget.controller.applyStatusFilter(value),
          ),
          
          SizedBox(height: 12),
          
          // Filtre par priorité
          _buildDropdown<PriorityLevel?>(
            'Priorité',
            widget.controller.currentPriorityFilter,
            [
              _buildDropdownItem(null, 'Toutes les priorités'),
              ...PriorityLevel.values.map((priority) => 
                _buildDropdownItem(priority, _getPriorityText(priority))
              ),
            ],
            (value) => widget.controller.applyPriorityFilter(value),
          ),
          
          SizedBox(height: 12),
          
          // Filtre par type
          _buildDropdown<InformationType?>(
            'Type',
            widget.controller.currentTypeFilter,
            [
              _buildDropdownItem(null, 'Tous les types'),
              ...InformationType.values.map((type) => 
                _buildDropdownItem(type, _getTypeText(type))
              ),
            ],
            (value) => widget.controller.applyTypeFilter(value),
          ),
          
          SizedBox(height: 12),
          
          // Recherche
          TextField(
            decoration: InputDecoration(
              labelText: 'Rechercher',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (text) => widget.controller.applySearchFilter(text),
          ),
          
          SizedBox(height: 16),
          
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.controller.clearAllFilters();
                    setState(() {});
                  },
                  child: Text('Tout effacer'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Fermer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>(
    String label,
    T? value,
    List<DropdownMenuItem<T>> items,
    void Function(T?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
        SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          isExpanded: true,
          onChanged: (newValue) {
            onChanged(newValue);
            setState(() {});
          },
          items: items,
        ),
      ],
    );
  }

  DropdownMenuItem<T> _buildDropdownItem<T>(T value, String text) {
    return DropdownMenuItem<T>(value: value, child: Text(text));
  }

  String _getStatusText(InformationStatus status) {
    switch (status) {
      case InformationStatus.pending: return 'En attente';
      case InformationStatus.inProgress: return 'En cours';
      case InformationStatus.resolved: return 'Résolu';
    }
  }

  String _getPriorityText(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.low: return 'Faible';
      case PriorityLevel.medium: return 'Moyen';
      case PriorityLevel.high: return 'Élevé';
      case PriorityLevel.urgent: return 'Urgent';
    }
  }

  String _getTypeText(InformationType type) {
    switch (type) {
      case InformationType.security: return 'Sécurité';
      case InformationType.drugs: return 'Drogue';
      case InformationType.suspect: return 'Suspect';
      case InformationType.nuisance: return 'Nuisance';
      case InformationType.infrastructure: return 'Infrastructure';
      case InformationType.other: return 'Autre';
    }
  }
}
```

## Fonctionnalités

### Synchronisation intelligente
```dart
// Sync automatique au démarrage
await controller.smartSync();

// Sync avec filtres spécifiques
await controller.syncWithFilters(InformationSyncFilters(
  status: 'pending',
  priority: 'high',
));

// Force une resynchronisation complète
await controller.forceFullSync();
```

### Filtrage local instantané
```dart
// Filtrer par statut
controller.applyStatusFilter(InformationStatus.pending);

// Filtrer par priorité
controller.applyPriorityFilter(PriorityLevel.high);

// Recherche textuelle
controller.applySearchFilter('sécurité');

// Effacer tous les filtres
controller.clearAllFilters();
```

### Gestion des notifications
```dart
// Afficher une notification personnalisée
controller.showSyncCompleteNotification('10 nouvelles informations');

// Effacer les notifications
controller.clearNotification();
```

## Points d'attention

1. **TypeId uniques** : Les informations utilisent les TypeId 4 et 5
2. **Boxes distinctes** : `information_checksums` et `cached_informations`
3. **Endpoint API** : `/information/sync` (au lieu de `/reports/sync`)
4. **Ordre préservé** : L'ordre de réception depuis l'API Laravel est maintenu
5. **Checksums API** : Utilisation des checksums fournis par l'API

Cette implémentation fournit une expérience utilisateur cohérente avec les autres modules tout en étant optimisée pour les informations du cadre de vie.