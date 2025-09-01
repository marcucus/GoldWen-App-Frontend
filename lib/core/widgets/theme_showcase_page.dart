import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/app_logo.dart';
import '../widgets/art_deco_card.dart';

class ThemeShowcasePage extends StatelessWidget {
  const ThemeShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thème Art Déco GoldWen'),
        centerTitle: true,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo showcase
                const AppLogo(
                  width: 120,
                  height: 120,
                  useTransparentVersion: true,
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Theme status
                ArtDecoCard(
                  showGradient: true,
                  child: Column(
                    children: [
                      Text(
                        'Thème Actuel',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _getThemeName(themeProvider.themeMode),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        themeProvider.isDarkMode ? 'Mode Sombre' : 'Mode Clair',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Theme selection buttons
                Text(
                  'Changer le thème',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildThemeButton(
                        context,
                        themeProvider,
                        AppThemeMode.light,
                        'Clair',
                        Icons.light_mode,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildThemeButton(
                        context,
                        themeProvider,
                        AppThemeMode.dark,
                        'Sombre',
                        Icons.dark_mode,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildThemeButton(
                        context,
                        themeProvider,
                        AppThemeMode.system,
                        'Système',
                        Icons.settings_system_daydream,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Art Deco showcase
                Text(
                  'Style Art Déco',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Color palette
                _buildColorPalette(context, themeProvider),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Sample content
                ArtDecoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exemple de contenu',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Ce texte utilise la typographie Art Déco avec Playfair Display pour les titres et Lato pour le corps du texte.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text('Action'),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Secondaire'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getThemeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Thème Clair';
      case AppThemeMode.dark:
        return 'Thème Sombre';
      case AppThemeMode.system:
        return 'Thème Système';
    }
  }

  Widget _buildThemeButton(
    BuildContext context,
    ThemeProvider themeProvider,
    AppThemeMode mode,
    String label,
    IconData icon,
  ) {
    final isSelected = themeProvider.themeMode == mode;
    
    return ArtDecoCard(
      showGradient: isSelected,
      onTap: () => themeProvider.setThemeMode(mode),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: isSelected 
                ? Colors.white 
                : (themeProvider.isDarkMode 
                    ? AppColors.primaryGoldDark 
                    : AppColors.primaryGold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : null,
              fontWeight: isSelected ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette(BuildContext context, ThemeProvider themeProvider) {
    final colors = themeProvider.isDarkMode
        ? [
            AppColors.primaryGoldDark,
            AppColors.backgroundDark,
            AppColors.backgroundDarkSecondary,
            AppColors.textLight,
            AppColors.artDecoBronze,
          ]
        : [
            AppColors.primaryGold,
            AppColors.secondaryBeige,
            AppColors.accentCream,
            AppColors.textDark,
            AppColors.artDecoCopper,
          ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: colors.map((color) {
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        );
      }).toList(),
    );
  }
}