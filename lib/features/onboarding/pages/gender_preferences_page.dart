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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundWhite,
              AppColors.accentCream.withOpacity(0.3),
              AppColors.backgroundWhite,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xl),
                
                // Icon header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_border_rounded,
                    size: 32,
                    color: AppColors.primaryGold,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Title and subtitle
                Text(
                  'Je suis intéressé(e) par...',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primaryGold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                Text(
                  'Vous pouvez sélectionner plusieurs options. Ces préférences nous aident à vous proposer des profils compatibles.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            gradient: isSelected ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryGold.withOpacity(0.15),
                                AppColors.primaryGold.withOpacity(0.08),
                              ],
                            ) : null,
                            color: isSelected ? null : AppColors.backgroundWhite,
                            borderRadius: BorderRadius.circular(AppBorderRadius.large),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryGold : AppColors.dividerLight,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: AppColors.primaryGold.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ] : [],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  gradient: isSelected ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primaryGold.withOpacity(0.3),
                                      AppColors.primaryGold.withOpacity(0.2),
                                    ],
                                  ) : null,
                                  color: isSelected ? null : AppColors.accentCream,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  gender.icon,
                                  color: isSelected 
                                      ? AppColors.primaryGold
                                      : AppColors.textSecondary,
                                  size: 28,
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
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  boxShadow: _selectedGenders.isNotEmpty ? [
                    BoxShadow(
                      color: AppColors.primaryGold.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ] : [],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedGenders.isNotEmpty ? _continue : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continuer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
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