import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mydumcontrol/l10n/app_localizations.dart';
import '../../../application/providers/connection_providers.dart';
import '../../../application/providers/folder_providers.dart';
import '../../../application/providers/super_favorites_provider.dart';
import '../../../core/router/routes.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/models/bacnet_object.dart';
import '../../shared/utils/bacnet_type_utils.dart';

/// Écran de liste des connexions sauvegardées organisées par dossiers
class ConnectionsListScreen extends ConsumerStatefulWidget {
  const ConnectionsListScreen({super.key});

  @override
  ConsumerState<ConnectionsListScreen> createState() => _ConnectionsListScreenState();
}

class _ConnectionsListScreenState extends ConsumerState<ConnectionsListScreen> {
  final Set<int> _expandedFolders = {};

  @override
  void initState() {
    super.initState();
    // Par défaut, tous les dossiers sont dépliés
    _expandedFolders.add(-1); // -1 = racine
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final foldersAsync = ref.watch(foldersStreamProvider);
    final connectionsByFolderAsync = ref.watch(connectionsByFolderProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.connections),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => _showAddFolderDialog(context, l10n),
            tooltip: 'Nouveau dossier',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(Routes.settings),
            tooltip: l10n.settings,
          ),
        ],
      ),
      body: foldersAsync.when(
        data: (folders) => connectionsByFolderAsync.when(
          data: (connectionsByFolder) {
            final rootConnections = connectionsByFolder[null] ?? [];
            final hasContent = folders.isNotEmpty || rootConnections.isNotEmpty;

            if (!hasContent) {
              return _buildEmptyState(context, l10n);
            }

            return _buildFoldersList(context, ref, l10n, folders, connectionsByFolder);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(context, ref, l10n, error),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, ref, l10n, error),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.addConnection),
        icon: const Icon(Icons.add),
        label: Text(l10n.addConnection),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, AppLocalizations l10n, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text('Erreur: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(foldersStreamProvider);
              ref.invalidate(connectionsByFolderProvider);
            },
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildFoldersList(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<Folder> folders,
    Map<int?, List<Connection>> connectionsByFolder,
  ) {
    final rootConnections = connectionsByFolder[null] ?? [];

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        // Dossiers
        ...folders.map((folder) => _buildFolderSection(
              context,
              ref,
              l10n,
              folder,
              connectionsByFolder[folder.id] ?? [],
            )),

        // Connexions à la racine (sans dossier)
        if (rootConnections.isNotEmpty) ...[
          if (folders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                'Sans dossier',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ),
          ...rootConnections.map((connection) => _ConnectionCard(
                connection: connection,
                l10n: l10n,
                onTap: () => context.push('${Routes.home}?connectionId=${connection.id}'),
                onEdit: () => context.push(Routes.editConnectionPath(connection.id.toString())),
                onDelete: () => _showDeleteConnectionDialog(context, ref, l10n, connection),
                onMoveToFolder: () => _showMoveToFolderDialog(context, ref, l10n, connection),
              )),
        ],
      ],
    );
  }

  Widget _buildFolderSection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Folder folder,
    List<Connection> connections,
  ) {
    final isExpanded = _expandedFolders.contains(folder.id);
    final folderColor = _parseColor(folder.color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête du dossier
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedFolders.remove(folder.id);
              } else {
                _expandedFolders.add(folder.id);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.folder_open : Icons.folder,
                  color: folderColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${connections.length} connexion${connections.length > 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
                // Bouton refresh pour tout le dossier
                _FolderRefreshButton(
                  connectionIds: connections.map((c) => c.id).toList(),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditFolderDialog(context, l10n, folder);
                        break;
                      case 'delete':
                        _showDeleteFolderDialog(context, ref, l10n, folder);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'Supprimer',
                            style: TextStyle(color: Colors.red.shade400),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
        // Contenu du dossier (connexions)
        if (isExpanded)
          ...connections.map((connection) => Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _ConnectionCard(
                  connection: connection,
                  l10n: l10n,
                  onTap: () => context.push('${Routes.home}?connectionId=${connection.id}'),
                  onEdit: () => context.push(Routes.editConnectionPath(connection.id.toString())),
                  onDelete: () => _showDeleteConnectionDialog(context, ref, l10n, connection),
                  onMoveToFolder: () => _showMoveToFolderDialog(context, ref, l10n, connection),
                ),
              )),
        if (isExpanded && connections.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 56, bottom: 8),
            child: Text(
              'Dossier vide',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
      ],
    );
  }

  Color _parseColor(String colorHex) {
    try {
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  Future<void> _showAddFolderDialog(BuildContext context, AppLocalizations l10n) async {
    final nameController = TextEditingController();
    String selectedColor = '#2196F3';

    final colors = [
      '#2196F3', // Blue
      '#4CAF50', // Green
      '#FF9800', // Orange
      '#E91E63', // Pink
      '#9C27B0', // Purple
      '#00BCD4', // Cyan
      '#795548', // Brown
      '#607D8B', // Blue Grey
    ];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouveau dossier'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du dossier',
                  prefixIcon: Icon(Icons.folder),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: colors.map((color) {
                  final isSelected = color == selectedColor;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _parseColor(color),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _parseColor(color).withAlpha(128),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.isNotEmpty && mounted) {
      final repository = ref.read(folderRepositoryProvider);
      final newId = await repository.createFolder(
        name: nameController.text.trim(),
        color: selectedColor,
      );
      // Déplier le nouveau dossier
      setState(() {
        _expandedFolders.add(newId);
      });
    }

    nameController.dispose();
  }

  Future<void> _showEditFolderDialog(BuildContext context, AppLocalizations l10n, Folder folder) async {
    final nameController = TextEditingController(text: folder.name);
    String selectedColor = folder.color;

    final colors = [
      '#2196F3', '#4CAF50', '#FF9800', '#E91E63',
      '#9C27B0', '#00BCD4', '#795548', '#607D8B',
    ];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier le dossier'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du dossier',
                  prefixIcon: Icon(Icons.folder),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: colors.map((color) {
                  final isSelected = color == selectedColor;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _parseColor(color),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _parseColor(color).withAlpha(128),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.isNotEmpty && mounted) {
      final repository = ref.read(folderRepositoryProvider);
      await repository.updateFolder(
        id: folder.id,
        name: nameController.text.trim(),
        icon: folder.icon,
        color: selectedColor,
      );
    }

    nameController.dispose();
  }

  Future<void> _showDeleteFolderDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Folder folder,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le dossier'),
        content: Text(
          'Voulez-vous supprimer le dossier "${folder.name}" ?\n\n'
          'Les connexions qu\'il contient seront déplacées à la racine.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repository = ref.read(folderRepositoryProvider);
      await repository.deleteFolder(folder.id);
      _expandedFolders.remove(folder.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dossier "${folder.name}" supprimé')),
        );
      }
    }
  }

  Future<void> _showDeleteConnectionDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Connection connection,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text('Voulez-vous supprimer "${connection.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(connectionRepositoryProvider).deleteConnection(connection.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connexion "${connection.name}" supprimée')),
        );
      }
    }
  }

  Future<void> _showMoveToFolderDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Connection connection,
  ) async {
    final foldersAsync = ref.read(foldersStreamProvider);

    final folders = foldersAsync.when(
      data: (data) => data,
      loading: () => <Folder>[],
      error: (_, _) => <Folder>[],
    );

    final selectedFolderId = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déplacer vers'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Option racine
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Sans dossier'),
                selected: connection.folderId == null,
                onTap: () => Navigator.pop(context, -1), // -1 = racine
              ),
              const Divider(),
              // Dossiers
              ...folders.map((folder) => ListTile(
                    leading: Icon(Icons.folder, color: _parseColor(folder.color)),
                    title: Text(folder.name),
                    selected: connection.folderId == folder.id,
                    onTap: () => Navigator.pop(context, folder.id),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (selectedFolderId != null && mounted) {
      final repository = ref.read(folderRepositoryProvider);
      final newFolderId = selectedFolderId == -1 ? null : selectedFolderId;
      await repository.moveConnectionToFolder(connection.id, newFolderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connexion déplacée')),
        );
      }
    }
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dns_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noConnections,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez une connexion pour commencer',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push(Routes.addConnection),
              icon: const Icon(Icons.add),
              label: Text(l10n.addConnection),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte affichant une connexion avec ses super favoris
class _ConnectionCard extends ConsumerWidget {
  final Connection connection;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMoveToFolder;

  const _ConnectionCard({
    required this.connection,
    required this.l10n,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onMoveToFolder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protocol = connection.useHttps ? 'https' : 'http';
    final url = '$protocol://${connection.host}:${connection.port}';

    // Récupérer les super favoris pour cette connexion
    final superFavsState = ref.watch(superFavoritesProvider);
    final superFavorites = superFavsState.forConnection(connection.id);
    final isRefreshing = superFavsState.isRefreshing(connection.id);
    final connectionInfo = superFavsState.getConnectionInfo(connection.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de la connexion
              Row(
                children: [
                  // Icône
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.dns,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Infos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          connection.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          url,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                        ),
                        // Badges : Modèle (depuis DB) + API version (toujours visibles)
                        if (connection.modelName != null || connection.apiVersion != null) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              // Badge modèle de l'automate (depuis DB = toujours visible)
                              if (connection.modelName != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    connection.modelName!,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.teal.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              // Badge API version
                              if (connection.apiVersion != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'API ${connection.apiVersion}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        // Heure de l'automate (si disponible)
                        if (connectionInfo?.controllerTime != null) ...[
                          const SizedBox(height: 4),
                          _buildControllerTimeRow(context, connectionInfo!.controllerTime!),
                        ],
                      ],
                    ),
                  ),
                  // Bouton refresh pour les super favoris (si présents)
                  if (superFavorites.isNotEmpty)
                    _RefreshButton(connectionId: connection.id),
                  // Actions
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'move':
                          onMoveToFolder();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.editConnection),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'move',
                        child: Row(
                          children: [
                            Icon(Icons.drive_file_move_outline, size: 20),
                            SizedBox(width: 8),
                            Text('Déplacer'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              l10n.deleteConnection,
                              style: TextStyle(color: Colors.red.shade400),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Super favoris (si présents)
              if (superFavorites.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                _buildSuperFavoritesList(context, superFavorites, isRefreshing),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Construit la liste des super favoris
  Widget _buildSuperFavoritesList(
    BuildContext context,
    List<SuperFavoriteWithValue> superFavorites,
    bool isRefreshing,
  ) {
    // Vérifier s'il y a une erreur globale (même erreur sur tous les favoris)
    final globalError = superFavorites.isNotEmpty &&
        superFavorites.every((sf) => sf.error != null)
        ? superFavorites.first.error
        : null;

    if (globalError != null && !isRefreshing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
            const SizedBox(width: 6),
            Text(
              globalError,
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: superFavorites.map((sf) {
        final liveData = sf.liveData;
        final hasValue = liveData != null;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              // Icône du type
              Icon(
                BacnetTypeUtils.getIconForType(sf.favorite.objectType),
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              // Nom du point
              Expanded(
                child: Text(
                  sf.favorite.pointName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Valeur
              if (isRefreshing && !hasValue)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: hasValue
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    sf.displayValue,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: hasValue
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Formate la date/heure de l'automate (DD/MM/YYYY HH:MM)
  String _formatControllerDateTime(ControllerTime controllerTime) {
    final dt = controllerTime.controllerDateTime;
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  /// Construit la ligne d'affichage de l'heure de l'automate
  Widget _buildControllerTimeRow(BuildContext context, ControllerTime controllerTime) {
    final hasTimeOffset = controllerTime.hasSignificantOffset;
    final hasCriticalOffset = controllerTime.hasCriticalOffset;

    return Row(
      children: [
        Icon(
          hasTimeOffset ? Icons.warning_amber : Icons.access_time,
          size: 12,
          color: hasCriticalOffset
              ? Colors.red.shade600
              : hasTimeOffset
                  ? Colors.orange.shade600
                  : Colors.grey.shade500,
        ),
        const SizedBox(width: 4),
        Text(
          _formatControllerDateTime(controllerTime),
          style: TextStyle(
            fontSize: 10,
            color: hasCriticalOffset
                ? Colors.red.shade700
                : hasTimeOffset
                    ? Colors.orange.shade700
                    : Colors.grey.shade600,
            fontWeight: hasTimeOffset ? FontWeight.bold : FontWeight.w500,
            fontFamily: 'monospace',
          ),
        ),
        // Indicateur de décalage si significatif
        if (hasTimeOffset) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: hasCriticalOffset ? Colors.red.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              controllerTime.offsetDescription,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: hasCriticalOffset ? Colors.red.shade800 : Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Bouton de refresh pour un dossier entier (tous les automates)
class _FolderRefreshButton extends ConsumerStatefulWidget {
  final List<int> connectionIds;

  const _FolderRefreshButton({required this.connectionIds});

  @override
  ConsumerState<_FolderRefreshButton> createState() => _FolderRefreshButtonState();
}

class _FolderRefreshButtonState extends ConsumerState<_FolderRefreshButton> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    final state = ref.read(superFavoritesProvider);
    // Prendre le max des cooldowns de toutes les connexions
    int maxRemaining = 0;
    for (final id in widget.connectionIds) {
      final remaining = state.secondsUntilRefresh(id);
      if (remaining > maxRemaining) maxRemaining = remaining;
    }

    if (maxRemaining > 0 && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {});
          // Vérifier si on peut arrêter le timer
          final newState = ref.read(superFavoritesProvider);
          int newMax = 0;
          for (final id in widget.connectionIds) {
            final r = newState.secondsUntilRefresh(id);
            if (r > newMax) newMax = r;
          }
          if (newMax == 0) {
            _timer?.cancel();
            _timer = null;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superFavoritesProvider);

    // Vérifier si au moins une connexion a des super favoris
    bool hasSuperFavorites = false;
    for (final id in widget.connectionIds) {
      if (state.forConnection(id).isNotEmpty) {
        hasSuperFavorites = true;
        break;
      }
    }

    // Ne pas afficher le bouton si aucun super favori dans le dossier
    if (!hasSuperFavorites) {
      return const SizedBox.shrink();
    }

    // Vérifier l'état de refresh pour toutes les connexions
    bool isAnyRefreshing = false;
    int maxSecondsRemaining = 0;

    for (final id in widget.connectionIds) {
      if (state.isRefreshing(id)) {
        isAnyRefreshing = true;
      }
      final remaining = state.secondsUntilRefresh(id);
      if (remaining > maxSecondsRemaining) {
        maxSecondsRemaining = remaining;
      }
    }

    // Démarrer le timer si nécessaire
    if (maxSecondsRemaining > 0 && _timer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTimerIfNeeded();
      });
    }

    // En cours de refresh : spinner
    if (isAnyRefreshing) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Cooldown actif : afficher le chrono
    if (maxSecondsRemaining > 0) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Text(
            '${maxSecondsRemaining}s',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      );
    }

    // Refresh possible : bouton normal
    return IconButton(
      icon: const Icon(Icons.refresh, size: 22),
      onPressed: () {
        ref.read(superFavoritesProvider.notifier).refreshFolder(widget.connectionIds);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startTimerIfNeeded();
        });
      },
      tooltip: 'Rafraîchir tous les super favoris du dossier',
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Bouton de refresh avec chrono de cooldown
class _RefreshButton extends ConsumerStatefulWidget {
  final int connectionId;

  const _RefreshButton({required this.connectionId});

  @override
  ConsumerState<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends ConsumerState<_RefreshButton> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    final state = ref.read(superFavoritesProvider);
    final remaining = state.secondsUntilRefresh(widget.connectionId);

    if (remaining > 0 && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {});
          // Arrêter le timer quand on atteint 0
          final newRemaining = ref.read(superFavoritesProvider).secondsUntilRefresh(widget.connectionId);
          if (newRemaining == 0) {
            _timer?.cancel();
            _timer = null;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superFavoritesProvider);
    final isRefreshing = state.isRefreshing(widget.connectionId);
    final secondsRemaining = state.secondsUntilRefresh(widget.connectionId);
    final canRefresh = !isRefreshing && secondsRemaining == 0;

    // Démarrer le timer si nécessaire (après un refresh)
    if (secondsRemaining > 0 && _timer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTimerIfNeeded();
      });
    }

    // En cours de refresh : spinner
    if (isRefreshing) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Cooldown actif : afficher le chrono
    if (secondsRemaining > 0) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Text(
            '${secondsRemaining}s',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      );
    }

    // Refresh possible : bouton normal
    return IconButton(
      icon: const Icon(Icons.refresh, size: 20),
      onPressed: () {
        ref.read(superFavoritesProvider.notifier).refreshConnection(widget.connectionId);
        // Démarrer le timer après le refresh
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startTimerIfNeeded();
        });
      },
      tooltip: 'Rafraîchir les valeurs',
      visualDensity: VisualDensity.compact,
    );
  }
}
