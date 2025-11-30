import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mydumcontrol/l10n/app_localizations.dart';
import '../../../application/providers/connection_providers.dart';
import '../../../application/providers/folder_providers.dart';
import '../../../core/router/routes.dart';
import '../../../data/database/app_database.dart';

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

/// Carte affichant une connexion
class _ConnectionCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final protocol = connection.useHttps ? 'https' : 'http';
    final url = '$protocol://${connection.host}:${connection.port}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
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
                    if (connection.apiVersion != null) ...[
                      const SizedBox(height: 4),
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
                  ],
                ),
              ),
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
        ),
      ),
    );
  }
}
