import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/providers/profile_provider.dart';
import 'gender_preferences_page.dart';

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

class GenderSelectionPage extends StatefulWidget {
  const GenderSelectionPage({super.key});

  @override
  State<GenderSelectionPage> createState() => _GenderSelectionPageState();
}

class _GenderSelectionPageState extends State<GenderSelectionPage> {
  Gender? _selectedGender;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon genre'),
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
                'Je suis...',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Text(
                'Cette information nous aide à personnaliser votre expérience et à vous présenter des profils pertinents.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Gender options
              Expanded(
                child: ListView.builder(
                  itemCount: Gender.values.length,
                  itemBuilder: (context, index) {
                    final gender = Gender.values[index];
                    final isSelected = _selectedGender == gender;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedGender = gender;
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
                              
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryGold,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedGender != null ? _continue : null,
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
    if (_selectedGender == null) return;
    
    // Save the selected gender to the profile provider
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.setGender(_selectedGender!.value);
    
    // Navigate to gender preferences page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GenderPreferencesPage(),
      ),
    );
  }
}