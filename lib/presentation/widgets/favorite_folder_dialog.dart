import 'package:flutter/material.dart';
import '../../data/database/app_database.dart';

/// Liste des couleurs disponibles pour les dossiers
const folderColors = [
  '#2196F3', // Blue
  '#4CAF50', // Green
  '#FF9800', // Orange
  '#E91E63', // Pink
  '#9C27B0', // Purple
  '#00BCD4', // Cyan
  '#795548', // Brown
  '#607D8B', // Blue Grey
  '#F44336', // Red
  '#FFEB3B', // Yellow
  '#009688', // Teal
  '#3F51B5', // Indigo
];

/// Liste des icônes disponibles pour les dossiers
const folderIcons = [
  ('folder', Icons.folder),
  ('local_fire_department', Icons.local_fire_department), // Chaudière
  ('water_drop', Icons.water_drop), // Eau
  ('air', Icons.air), // Ventilation
  ('ac_unit', Icons.ac_unit), // Climatisation
  ('thermostat', Icons.thermostat), // Température
  ('lightbulb', Icons.lightbulb), // Éclairage
  ('power', Icons.power), // Électrique
  ('sensors', Icons.sensors), // Capteurs
  ('speed', Icons.speed), // Vitesse/Débit
  ('compress', Icons.compress), // Pression
  ('opacity', Icons.opacity), // Humidité
  ('wb_sunny', Icons.wb_sunny), // Solaire
  ('settings', Icons.settings), // Réglages
  ('warning', Icons.warning), // Alarmes
  ('schedule', Icons.schedule), // Horaires
];

/// Dialog pour créer ou modifier un dossier de favoris
class FavoriteFolderDialog extends StatefulWidget {
  /// Dossier existant à modifier (null pour création)
  final FavoriteFolder? folder;

  const FavoriteFolderDialog({
    super.key,
    this.folder,
  });

  /// Affiche le dialog et retourne le résultat
  static Future<FavoriteFolderResult?> show(
    BuildContext context, {
    FavoriteFolder? folder,
  }) {
    return showDialog<FavoriteFolderResult>(
      context: context,
      builder: (context) => FavoriteFolderDialog(folder: folder),
    );
  }

  @override
  State<FavoriteFolderDialog> createState() => _FavoriteFolderDialogState();
}

/// Résultat du dialog
class FavoriteFolderResult {
  final String name;
  final String color;
  final String icon;

  FavoriteFolderResult({
    required this.name,
    required this.color,
    required this.icon,
  });
}

class _FavoriteFolderDialogState extends State<FavoriteFolderDialog> {
  late final TextEditingController _nameController;
  late String _selectedColor;
  late String _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.folder?.name ?? '');
    _selectedColor = widget.folder?.color ?? folderColors.first;
    _selectedIcon = widget.folder?.icon ?? 'folder';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      final hexCode = hex.replaceFirst('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _getIconData(String iconName) {
    final entry = folderIcons.cast<(String, IconData)?>().firstWhere(
          (e) => e?.$1 == iconName,
          orElse: () => null,
        );
    return entry?.$2 ?? Icons.folder;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.folder != null;
    final selectedColorParsed = _parseColor(_selectedColor);

    return AlertDialog(
      title: Text(isEditing ? 'Modifier le dossier' : 'Nouveau dossier'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom du dossier
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nom du dossier',
                prefixIcon: Icon(
                  _getIconData(_selectedIcon),
                  color: selectedColorParsed,
                ),
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Sélection de couleur
            Text(
              'Couleur',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: folderColors.map((color) {
                final isSelected = color == _selectedColor;
                final parsedColor = _parseColor(color);
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: parsedColor,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: parsedColor.withAlpha(128),
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
            const SizedBox(height: 24),

            // Sélection d'icône
            Text(
              'Icône',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: folderIcons.map((entry) {
                final (iconName, iconData) = entry;
                final isSelected = iconName == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = iconName),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? selectedColorParsed.withAlpha(50)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: selectedColorParsed, width: 2)
                          : Border.all(color: Colors.grey.shade300),
                    ),
                    child: Icon(
                      iconData,
                      color: isSelected ? selectedColorParsed : Colors.grey.shade600,
                      size: 24,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _nameController.text.trim().isEmpty
              ? null
              : () {
                  Navigator.pop(
                    context,
                    FavoriteFolderResult(
                      name: _nameController.text.trim(),
                      color: _selectedColor,
                      icon: _selectedIcon,
                    ),
                  );
                },
          child: Text(isEditing ? 'Modifier' : 'Créer'),
        ),
      ],
    );
  }
}
