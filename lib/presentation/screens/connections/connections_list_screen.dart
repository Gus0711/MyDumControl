import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myglobaldc/l10n/app_localizations.dart';
import '../../../application/providers/active_connection_provider.dart';
import '../../../application/providers/api_provider.dart';
import '../../../application/providers/connection_providers.dart';
import '../../../application/providers/folder_providers.dart';
import '../../../application/providers/super_favorites_provider.dart';
import '../../../core/router/routes.dart';
import '../../../data/database/app_database.dart';
import '../../../data/services/api_exceptions.dart';
import '../../../domain/models/bacnet_object.dart';
import '../../../domain/models/display_preferences.dart';
import '../../shared/utils/bacnet_type_utils.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/ui/ui.dart';

/// Écran de liste des connexions sauvegardées organisées par dossiers
class ConnectionsListScreen extends ConsumerStatefulWidget {
  const ConnectionsListScreen({super.key});

  @override
  ConsumerState<ConnectionsListScreen> createState() => _ConnectionsListScreenState();
}

class _ConnectionsListScreenState extends ConsumerState<ConnectionsListScreen> {
  final Set<int> _expandedFolders = {};
  String _query = '';

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
    final total = connectionsByFolderAsync.valueOrNull?.values.fold<int>(0, (n, l) => n + l.length);

    return Scaffold(
      appBar: GradientAppBar(
        title: l10n.connections,
        subtitle: total == null ? null : l10n.connectionsCount(total),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => _showAddFolderDialog(context, l10n),
            tooltip: l10n.newFolder,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
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
          loading: () => const DcLoading(),
          error: (error, stack) => _buildErrorState(context, ref, l10n, error),
        ),
        loading: () => const DcLoading(),
        error: (error, stack) => _buildErrorState(context, ref, l10n, error),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.addConnection),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addConnection),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, AppLocalizations l10n, Object error) {
    return DcEmptyState.error(
      context,
      title: l10n.error,
      message: '$error',
      action: FilledButton.icon(
        onPressed: () {
          ref.invalidate(foldersStreamProvider);
          ref.invalidate(connectionsByFolderProvider);
        },
        icon: const Icon(Icons.refresh_rounded),
        label: Text(l10n.retry),
      ),
    );
  }

  bool _matches(Connection c) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return c.name.toLowerCase().contains(q) ||
        c.host.toLowerCase().contains(q) ||
        (c.modelName?.toLowerCase().contains(q) ?? false);
  }

  Widget _buildFoldersList(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<Folder> folders,
    Map<int?, List<Connection>> connectionsByFolder,
  ) {
    final searching = _query.trim().isNotEmpty;
    final rootConnections = (connectionsByFolder[null] ?? []).where(_matches).toList();
    final visibleFolders = folders
        .where((f) => !searching || (connectionsByFolder[f.id] ?? []).any(_matches))
        .toList();
    final noMatch = searching && rootConnections.isEmpty && visibleFolders.isEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0.0, DcSpace.contentMaxWidth);
        final columns = width >= 1100 ? 3 : (width >= 700 ? 2 : 1);

        return ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            DcContent(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _SearchField(
                hint: l10n.connectionsSearchHint,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            if (noMatch)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: DcEmptyState(
                  icon: Icons.search_off_rounded,
                  title: l10n.connectionsNoMatch,
                ),
              ),
            // Dossiers
            ...visibleFolders.map((folder) => DcContent(
                  child: _buildFolderSection(
                    context,
                    ref,
                    l10n,
                    folder,
                    (connectionsByFolder[folder.id] ?? []).where(_matches).toList(),
                    columns,
                    forceExpanded: searching,
                  ),
                )),

            // Connexions à la racine (sans dossier)
            if (rootConnections.isNotEmpty)
              DcContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DcSectionHeader(
                      folders.isNotEmpty ? l10n.noFolder : l10n.connections,
                      count: rootConnections.length,
                    ),
                    _ConnectionGrid(
                      columns: columns,
                      children: rootConnections.map((c) => _connectionCard(context, ref, l10n, c)).toList(),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _connectionCard(BuildContext context, WidgetRef ref, AppLocalizations l10n, Connection connection) {
    return _ConnectionCard(
      connection: connection,
      l10n: l10n,
      onTap: () => context.push('${Routes.home}?connectionId=${connection.id}'),
      onEdit: () => context.push(Routes.editConnectionPath(connection.id.toString())),
      onDelete: () => _showDeleteConnectionDialog(context, ref, l10n, connection),
      onMoveToFolder: () => _showMoveToFolderDialog(context, ref, l10n, connection),
    );
  }

  Widget _buildFolderSection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Folder folder,
    List<Connection> connections,
    int columns, {
    bool forceExpanded = false,
  }) {
    final dc = context.dc;
    final isExpanded = forceExpanded || _expandedFolders.contains(folder.id);
    final folderTone = dc.toneOf(_parseColor(folder.color));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête du dossier
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(DcRadius.md),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedFolders.remove(folder.id);
                } else {
                  _expandedFolders.add(folder.id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  DcIconBox(
                    icon: isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded,
                    tone: folderTone,
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(folder.name, style: context.text.titleMedium),
                        Text(
                          l10n.connectionsCount(connections.length),
                          style: context.text.bodySmall?.copyWith(color: dc.textMuted),
                        ),
                      ],
                    ),
                  ),
                  // Bouton refresh pour tout le dossier
                  _FolderRefreshButton(
                    connectionIds: connections.map((c) => c.id).toList(),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz_rounded, color: dc.textSecondary),
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
                      dcMenuItem(context, 'edit', Icons.edit_outlined, l10n.edit),
                      dcMenuItem(context, 'delete', Icons.delete_outline_rounded, l10n.delete, danger: true),
                    ],
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.expand_more_rounded, color: dc.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Contenu du dossier (connexions)
        if (isExpanded && connections.isNotEmpty)
          _ConnectionGrid(
            columns: columns,
            children: connections.map((c) => _connectionCard(context, ref, l10n, c)).toList(),
          ),
        if (isExpanded && connections.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(64, 0, 16, 8),
            child: Text(
              l10n.connectionsEmptyFolder,
              style: context.text.bodySmall?.copyWith(
                color: dc.textMuted,
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
      return AppColors.brandBlue;
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
          title: Text(l10n.newFolder),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.connectionsFolderName,
                  prefixIcon: const Icon(Icons.folder),
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
              child: Text(l10n.create),
            ),
          ],
        ),
      ),
    );

    final name = nameController.text.trim();
    // Dispose after the dialog exit animation (the TextField is still mounted)
    Future.delayed(const Duration(milliseconds: 500), nameController.dispose);

    if (result == true && name.isNotEmpty && mounted) {
      final repository = ref.read(folderRepositoryProvider);
      final newId = await repository.createFolder(
        name: name,
        color: selectedColor,
      );
      if (!mounted) return;
      // Déplier le nouveau dossier
      setState(() {
        _expandedFolders.add(newId);
      });
    }
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
          title: Text(l10n.connectionsEditFolder),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.connectionsFolderName,
                  prefixIcon: const Icon(Icons.folder),
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

    final name = nameController.text.trim();
    // Dispose after the dialog exit animation (the TextField is still mounted)
    Future.delayed(const Duration(milliseconds: 500), nameController.dispose);

    if (result == true && name.isNotEmpty && mounted) {
      final repository = ref.read(folderRepositoryProvider);
      await repository.updateFolder(
        id: folder.id,
        name: name,
        icon: folder.icon,
        color: selectedColor,
      );
    }
  }

  Future<void> _showDeleteFolderDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Folder folder,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.connectionsDeleteFolder,
      message: l10n.connectionsDeleteFolderMessage(folder.name),
      confirmLabel: l10n.delete,
      destructive: true,
    );

    if (confirmed == true && mounted) {
      final repository = ref.read(folderRepositoryProvider);
      await repository.deleteFolder(folder.id);
      _expandedFolders.remove(folder.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.connectionsFolderDeleted(folder.name))),
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
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteConfirmTitle,
      message: l10n.connectionsDeleteConfirm(connection.name),
      confirmLabel: l10n.delete,
      destructive: true,
    );

    if (confirmed == true && mounted) {
      await ref.read(connectionRepositoryProvider).deleteConnection(connection.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.connectionsDeleted(connection.name))),
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
        title: Text(l10n.connectionsMoveTo),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Option racine
              ListTile(
                leading: const Icon(Icons.home),
                title: Text(l10n.noFolder),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.connectionsMoved)),
        );
      }
    }
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return DcEmptyState(
      icon: Icons.dns_outlined,
      tone: context.dc.accentTone,
      title: l10n.noConnections,
      message: l10n.connectionsAddToStart,
      action: FilledButton.icon(
        onPressed: () => context.push(Routes.addConnection),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addConnection),
      ),
      secondaryAction: OutlinedButton.icon(
        onPressed: () => context.push(Routes.discoverEclypse),
        icon: const Icon(Icons.wifi_find_rounded),
        label: Text(l10n.discoverEclypse),
      ),
    );
  }
}

/// Champ de recherche des connexions.
class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

/// Grille responsive des cartes de connexion (1 à 3 colonnes).
class _ConnectionGrid extends StatelessWidget {
  final int columns;
  final List<Widget> children;

  const _ConnectionGrid({required this.columns, required this.children});

  @override
  Widget build(BuildContext context) {
    const spacing = 12.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [for (final child in children) SizedBox(width: itemWidth, child: child)],
          );
        },
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
    final dc = context.dc;
    final protocol = connection.useHttps ? 'https' : 'http';
    final isBacnet = connection.connectionType == 'bacnet';
    final address = isBacnet
        ? '${connection.host}:${connection.port}'
        : '$protocol://${connection.host}:${connection.port}';

    // Récupérer les super favoris pour cette connexion
    final superFavsState = ref.watch(superFavoritesProvider);
    final superFavorites = superFavsState.forConnection(connection.id);
    final isRefreshing = superFavsState.isRefreshing(connection.id);
    final connectionInfo = superFavsState.getConnectionInfo(connection.id);

    // Connexion importée sans son mot de passe : à ressaisir
    final isDistech = !isBacnet;
    final missingPassword = isDistech &&
        ref.watch(connectionHasPasswordProvider(connection.passwordKey)).valueOrNull == false;

    return DcCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la connexion
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DcIconBox(
                icon: isBacnet ? Icons.lan_outlined : Icons.memory_rounded,
                tone: isBacnet ? dc.violet : dc.accentTone,
                size: 42,
              ),
              const SizedBox(width: 12),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connection.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.monospacedValue.copyWith(
                        fontSize: 11.5,
                        color: dc.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Bouton refresh pour les super favoris (si présents)
              if (superFavorites.isNotEmpty) _RefreshButton(connectionId: connection.id),
              // Actions
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: dc.textSecondary, size: 20),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'move':
                      onMoveToFolder();
                      break;
                    case 'redetect':
                      _redetectApiVersion(context, ref, l10n);
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  dcMenuItem(context, 'edit', Icons.edit_outlined, l10n.editConnection),
                  if (isDistech)
                    dcMenuItem(context, 'redetect', Icons.manage_search_rounded, l10n.redetectApiVersion),
                  dcMenuItem(context, 'move', Icons.drive_file_move_outline, l10n.connectionsMove),
                  const PopupMenuDivider(),
                  dcMenuItem(context, 'delete', Icons.delete_outline_rounded, l10n.deleteConnection, danger: true),
                ],
              ),
            ],
          ),
          // Badges : protocole, modèle, version d'API, mot de passe manquant
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (isBacnet)
                  DcTag(
                    connection.bacnetDeviceId != null
                        ? 'BACnet · ${connection.bacnetDeviceId}'
                        : 'BACnet/IP',
                    tone: dc.violet,
                    dense: true,
                  ),
                if (connection.modelName != null)
                  DcTag(connection.modelName!, dense: true),
                if (isDistech)
                  Tooltip(
                    message: connection.apiVersion != null
                        ? l10n.apiVersionBadgeTooltip
                        : l10n.apiVersionUnknownTooltip,
                    child: DcTag(
                      'API ${connection.apiVersion ?? '?'}',
                      tone: connection.apiVersion != null ? dc.accentTone : dc.warning,
                      dense: true,
                    ),
                  ),
                if (missingPassword)
                  DcTag(
                    l10n.passwordMissingBadge,
                    icon: Icons.key_off_rounded,
                    tone: dc.warning,
                    dense: true,
                  ),
                // Heure de l'automate (si disponible)
                if (connectionInfo?.controllerTime != null)
                  _buildControllerTimeTag(context, connectionInfo!.controllerTime!),
              ],
            ),
          ),
          // Super favoris (si présents)
          if (superFavorites.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildSuperFavoritesList(context, superFavorites, isRefreshing),
            ),
          ],
        ],
      ),
    );
  }

  /// Re-détecte la version d'API (automate mis à jour ou remplacé à la même
  /// adresse) et l'enregistre ; la connexion active est rouverte pour
  /// utiliser les bonnes routes.
  Future<void> _redetectApiVersion(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    final dc = context.dc;
    messenger.showSnackBar(SnackBar(content: Text(l10n.redetectingApiVersion)));
    String message;
    Color color;
    try {
      final version = await ref.read(apiClientFactoryProvider).redetectApiVersion(connection);
      if (version == null) {
        message = l10n.redetectApiVersionFailed;
        color = dc.danger.fg;
      } else {
        message = l10n.redetectApiVersionDone(version);
        color = dc.success.fg;
        final active = ref.read(activeConnectionProvider);
        if (active.connection?.id == connection.id && version != connection.apiVersion) {
          await ref.read(activeConnectionProvider.notifier).connect(connection.id);
        }
      }
    } on ApiException catch (e) {
      message = e.message;
      color = dc.danger.fg;
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(dcSnackBar(message, color: color));
  }

  /// Construit la liste des super favoris
  Widget _buildSuperFavoritesList(
    BuildContext context,
    List<SuperFavoriteWithValue> superFavorites,
    bool isRefreshing,
  ) {
    final dc = context.dc;
    // Vérifier s'il y a une erreur globale (même erreur sur tous les favoris)
    final globalError = superFavorites.isNotEmpty &&
        superFavorites.every((sf) => sf.error != null)
        ? superFavorites.first.error
        : null;

    if (globalError != null && !isRefreshing) {
      return DcBanner(
        tone: dc.warning,
        icon: Icons.info_outline_rounded,
        message: globalError,
        dense: true,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: dc.surfaceSunken,
        borderRadius: BorderRadius.circular(DcRadius.md),
        border: Border.all(color: dc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: superFavorites.map((sf) {
          final liveData = sf.liveData;
          final hasValue = liveData != null;
          final tone = hasValue ? dc.accentTone : dc.neutral;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                // Icône du type
                Icon(
                  BacnetTypeUtils.getIconForType(sf.favorite.objectType),
                  size: 15,
                  color: dc.textMuted,
                ),
                const SizedBox(width: 8),
                // Nom du point
                Expanded(
                  child: Text(
                    sf.favorite.pointName,
                    style: context.text.bodySmall?.copyWith(color: dc.textSecondary),
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
                  Text(
                    sf.displayValue,
                    style: AppTextStyles.monospacedValue.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasValue ? tone.fg : dc.textMuted,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Formate la date/heure de l'automate (DD/MM/YYYY HH:MM)
  String _formatControllerDateTime(ControllerTime controllerTime) =>
      DisplayPreferences.formatDateTime(controllerTime.controllerDateTime);

  /// Pastille de l'heure de l'automate (orange/rouge si décalée)
  Widget _buildControllerTimeTag(BuildContext context, ControllerTime controllerTime) {
    final dc = context.dc;
    final tone = controllerTime.hasCriticalOffset
        ? dc.danger
        : controllerTime.hasSignificantOffset
            ? dc.warning
            : dc.neutral;
    final label = controllerTime.hasSignificantOffset
        ? '${_formatControllerDateTime(controllerTime)} · ${controllerTime.offsetDescription}'
        : _formatControllerDateTime(controllerTime);

    return DcTag(
      label,
      icon: controllerTime.hasSignificantOffset ? Icons.warning_amber_rounded : Icons.schedule_rounded,
      tone: tone,
      dense: true,
      mono: true,
    );
  }
}

// Bouton de refresh pour un dossier entier (tous les automates)
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
              color: context.dc.textMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
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
      tooltip: AppLocalizations.of(context)!.connectionsRefreshFolderTooltip,
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
              color: context.dc.textMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
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
      tooltip: AppLocalizations.of(context)!.connectionsRefreshValuesTooltip,
      visualDensity: VisualDensity.compact,
    );
  }
}
