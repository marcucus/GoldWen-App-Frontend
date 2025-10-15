import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// A widget for selecting and displaying a favorite song or artist.
///
/// This widget allows users to:
/// - Enter their favorite song or artist name
/// - Optionally specify the music platform (Apple Music, Spotify, Deezer)
/// - Clear the selection
///
/// Example usage:
/// ```dart
/// FavoriteSongWidget(
///   favoriteSong: profileProvider.favoriteSong,
///   onChanged: (song) => profileProvider.updateFavoriteSong(song),
/// )
/// ```
class FavoriteSongWidget extends StatefulWidget {
  final String? favoriteSong;
  final Function(String?) onChanged;
  final bool isOptional;

  const FavoriteSongWidget({
    super.key,
    this.favoriteSong,
    required this.onChanged,
    this.isOptional = true,
  });

  @override
  State<FavoriteSongWidget> createState() => _FavoriteSongWidgetState();
}

class _FavoriteSongWidgetState extends State<FavoriteSongWidget> {
  final TextEditingController _songController = TextEditingController();
  String _selectedPlatform = 'Aucune';

  @override
  void initState() {
    super.initState();
    if (widget.favoriteSong != null) {
      _parseFavoriteSong(widget.favoriteSong!);
    }
  }

  @override
  void dispose() {
    _songController.dispose();
    super.dispose();
  }

  void _parseFavoriteSong(String favoriteSong) {
    // Parse format: "Song Name - Artist (Platform)"
    // or just "Song Name - Artist"
    final platformMatch = RegExp(r'\((.*?)\)$').firstMatch(favoriteSong);
    if (platformMatch != null) {
      _selectedPlatform = platformMatch.group(1) ?? 'Aucune';
      _songController.text =
          favoriteSong.substring(0, platformMatch.start).trim();
    } else {
      _songController.text = favoriteSong;
      _selectedPlatform = 'Aucune';
    }
  }

  String? _buildFavoriteSongString() {
    if (_songController.text.trim().isEmpty) {
      return null;
    }

    String result = _songController.text.trim();
    if (_selectedPlatform != 'Aucune') {
      result += ' ($_selectedPlatform)';
    }
    return result;
  }

  void _updateFavoriteSong() {
    widget.onChanged(_buildFavoriteSongString());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        side: BorderSide(
          color: AppColors.dividerLight,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.music_note,
                  color: AppColors.primaryGold,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Morceau/Artiste préféré',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (widget.isOptional)
                  Text(
                    'Optionnel',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _songController,
              decoration: InputDecoration(
                hintText: 'Ex: Bohemian Rhapsody - Queen',
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _songController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () {
                          setState(() {
                            _songController.clear();
                            _updateFavoriteSong();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  borderSide: BorderSide(color: AppColors.dividerLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  borderSide: BorderSide(color: AppColors.dividerLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _updateFavoriteSong();
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Plateforme (optionnel)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                'Aucune',
                'Apple Music',
                'Spotify',
                'Deezer',
              ].map((platform) {
                final isSelected = _selectedPlatform == platform;
                return ChoiceChip(
                  label: Text(platform),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPlatform = platform;
                      _updateFavoriteSong();
                    });
                  },
                  selectedColor: AppColors.primaryGold,
                  backgroundColor: AppColors.accentCream.withOpacity(0.3),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textDark,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            if (_buildFavoriteSongString() != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.accentCream.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppBorderRadius.small),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _buildFavoriteSongString()!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textDark,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
