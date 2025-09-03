import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/providers/profile_provider.dart';
import 'additional_info_page.dart';

class PreferencesSetupPage extends StatefulWidget {
  const PreferencesSetupPage({super.key});

  @override
  State<PreferencesSetupPage> createState() => _PreferencesSetupPageState();
}

class _PreferencesSetupPageState extends State<PreferencesSetupPage> {
  double _minAge = 18;
  double _maxAge = 35;
  double _maxDistance = 25; // in kilometers
  
  static const double _minAgeLimit = 18;
  static const double _maxAgeLimit = 80;
  static const double _maxDistanceLimit = 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes préférences'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              
              // Title and subtitle
              Text(
                'Personnalisez vos critères',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Text(
                'Définissez vos préférences pour que nous puissions vous proposer les profils les plus compatibles.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Age range section
                      _buildPreferenceSection(
                        title: 'Tranche d\'âge',
                        subtitle: 'Entre ${_minAge.round()} et ${_maxAge.round()} ans',
                        child: Column(
                          children: [
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Âge minimum : ${_minAge.round()} ans',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Slider(
                              value: _minAge,
                              min: _minAgeLimit,
                              max: _maxAgeLimit,
                              divisions: (_maxAgeLimit - _minAgeLimit).round(),
                              activeColor: AppColors.primaryGold,
                              onChanged: (value) {
                                setState(() {
                                  _minAge = value;
                                  if (_minAge >= _maxAge) {
                                    _maxAge = _minAge + 1;
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Âge maximum : ${_maxAge.round()} ans',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Slider(
                              value: _maxAge,
                              min: _minAgeLimit,
                              max: _maxAgeLimit,
                              divisions: (_maxAgeLimit - _minAgeLimit).round(),
                              activeColor: AppColors.primaryGold,
                              onChanged: (value) {
                                setState(() {
                                  _maxAge = value;
                                  if (_maxAge <= _minAge) {
                                    _minAge = _maxAge - 1;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Distance section
                      _buildPreferenceSection(
                        title: 'Distance maximale',
                        subtitle: 'Jusqu\'à ${_maxDistance.round()} km',
                        child: Column(
                          children: [
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: _maxDistance,
                                    min: 1,
                                    max: _maxDistanceLimit,
                                    divisions: _maxDistanceLimit.round(),
                                    activeColor: AppColors.primaryGold,
                                    onChanged: (value) {
                                      setState(() {
                                        _maxDistance = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentCream,
                                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                                  ),
                                  child: Text(
                                    '${_maxDistance.round()} km',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _maxDistance >= _maxDistanceLimit 
                                  ? 'Aucune limite de distance'
                                  : 'Profils dans un rayon de ${_maxDistance.round()} km',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Info box
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.accentCream,
                          borderRadius: BorderRadius.circular(AppBorderRadius.large),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.primaryGold,
                                  size: 24,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    'Conseil personnalisé',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppColors.primaryGold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Vous pourrez modifier ces préférences à tout moment dans votre profil. Nous recommandons de rester ouvert pour maximiser vos chances de connexions authentiques.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continue,
                  child: const Text('Continuer'),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        border: Border.all(color: AppColors.dividerLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  void _continue() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    
    // Save preferences to profile provider
    profileProvider.setAgePreferences(
      minAge: _minAge.round(),
      maxAge: _maxAge.round(),
    );
    
    profileProvider.setDistancePreference(
      maxDistance: _maxDistance.round(),
    );
    
    // Navigate to additional info page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AdditionalInfoPage(),
      ),
    );
  }
}