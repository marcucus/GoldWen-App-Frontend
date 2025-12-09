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
                    Icons.person_outline_rounded,
                    size: 32,
                    color: AppColors.primaryGold,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Title and subtitle
                Text(
                  'Je suis...',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primaryGold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                Text(
                  'Cette information nous aide à personnaliser votre expérience et à vous présenter des profils pertinents.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
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
                              
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGold,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  ),
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
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  boxShadow: _selectedGender != null ? [
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
                    onPressed: _selectedGender != null ? _continue : null,
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