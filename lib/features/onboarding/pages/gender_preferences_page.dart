import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/providers/profile_provider.dart';
import 'location_setup_page.dart';

enum Gender {
  man('man', 'Homme', Icons.male),
  woman('woman', 'Femme', Icons.female),
  nonBinary('non_binary', 'Non-binaire', Icons.person),
  other('other', 'Autre', Icons.person_outline);

  const Gender(this.value, this.label, this.icon);
  final String value;
  final String label;
  final IconData icon;
}

class GenderPreferencesPage extends StatefulWidget {
  const GenderPreferencesPage({super.key});

  @override
  State<GenderPreferencesPage> createState() => _GenderPreferencesPageState();
}

class _GenderPreferencesPageState extends State<GenderPreferencesPage> {
  final Set<Gender> _selectedGenders = {};

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
                'Je suis intéressé(e) par...',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Text(
                'Vous pouvez sélectionner plusieurs options. Ces préférences nous aident à vous proposer des profils compatibles.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Gender preference options
              Expanded(
                child: ListView.builder(
                  itemCount: Gender.values.length,
                  itemBuilder: (context, index) {
                    final gender = Gender.values[index];
                    final isSelected = _selectedGenders.contains(gender);
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedGenders.remove(gender);
                            } else {
                              _selectedGenders.add(gender);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryGold.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppBorderRadius.large),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryGold : AppColors.dividerLight,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? AppColors.primaryGold.withOpacity(0.2)
                                      : AppColors.accentCream,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  gender.icon,
                                  color: isSelected 
                                      ? AppColors.primaryGold
                                      : AppColors.textSecondary,
                                  size: 32,
                                ),
                              ),
                              
                              const SizedBox(width: AppSpacing.lg),
                              
                              Expanded(
                                child: Text(
                                  gender.label,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: isSelected ? AppColors.primaryGold : AppColors.textDark,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? AppColors.primaryGold : AppColors.dividerLight,
                                    width: 2,
                                  ),
                                  color: isSelected ? AppColors.primaryGold : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Selection summary
              if (_selectedGenders.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.accentCream,
                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryGold,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${_selectedGenders.length} préférence${_selectedGenders.length > 1 ? 's' : ''} sélectionnée${_selectedGenders.length > 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedGenders.isNotEmpty ? _continue : null,
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

  void _continue() {
    if (_selectedGenders.isEmpty) return;
    
    // Save the selected gender preferences to the profile provider
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final selectedValues = _selectedGenders.map((g) => g.value).toList();
    profileProvider.setGenderPreferences(selectedValues);
    
    // Navigate to location setup page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LocationSetupPage(),
      ),
    );
  }
}