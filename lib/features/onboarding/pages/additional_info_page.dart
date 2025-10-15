import 'package:flutter/material.dart';
import 'package:goldwen_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/text_validator.dart';
import '../../../core/utils/translations_helper.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/pages/profile_setup_page.dart';

class AdditionalInfoPage extends StatefulWidget {
  const AdditionalInfoPage({super.key});

  @override
  State<AdditionalInfoPage> createState() => _AdditionalInfoPageState();
}

class _AdditionalInfoPageState extends State<AdditionalInfoPage> {
  final _jobTitleController = TextEditingController();
  final _companyController = TextEditingController();
  final _educationController = TextEditingController();
  final _heightController = TextEditingController();

  final List<String> _selectedInterests = [];
  final List<String> _selectedLanguages = [];

  // Lists will be populated in build method using translations
  List<String> _availableInterests = [];
  List<String> _availableLanguages = [];

  @override
  void dispose() {
    _jobTitleController.dispose();
    _companyController.dispose();
    _educationController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Initialize translated lists
    _availableInterests = TranslationsHelper.getAvailableInterests(context);
    _availableLanguages = TranslationsHelper.getAvailableLanguages(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.additionalInfoTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    // Title and subtitle
                    Text(
                      l10n.shareMoreTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Text(
                      l10n.shareMoreSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Professional info section
                    _buildSectionTitle(l10n.professionalInfoSection),
                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _jobTitleController,
                      decoration: InputDecoration(
                        labelText: l10n.jobTitleLabel,
                        hintText: l10n.jobTitleHint,
                        prefixIcon: const Icon(Icons.work_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => TextValidator.validateText(
                        value,
                        checkForbiddenWords: true,
                        checkContactInfo: false,
                        checkSpamPatterns: false,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    TextFormField(
                      controller: _companyController,
                      decoration: const InputDecoration(
                        labelText: 'Entreprise',
                        hintText: 'Nom de votre entreprise',
                        prefixIcon: Icon(Icons.business_center),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => TextValidator.validateText(
                        value,
                        checkForbiddenWords: true,
                        checkContactInfo: false,
                        checkSpamPatterns: false,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    TextFormField(
                      controller: _educationController,
                      decoration: const InputDecoration(
                        labelText: 'Formation',
                        hintText: 'École, université, diplôme...',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => TextValidator.validateText(
                        value,
                        checkForbiddenWords: true,
                        checkContactInfo: false,
                        checkSpamPatterns: false,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Physical info section
                    _buildSectionTitle('Informations physiques'),
                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        labelText: 'Taille (cm)',
                        hintText: '175',
                        prefixIcon: Icon(Icons.height),
                        suffixText: 'cm',
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Interests section
                    _buildSectionTitle('Centres d\'intérêt'),
                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Sélectionnez vos passions (maximum 8)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _availableInterests.map((interest) {
                        final isSelected =
                            _selectedInterests.contains(interest);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedInterests.remove(interest);
                              } else if (_selectedInterests.length < 8) {
                                _selectedInterests.add(interest);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryGold.withOpacity(0.1)
                                  : AppColors.accentCream,
                              borderRadius:
                                  BorderRadius.circular(AppBorderRadius.large),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryGold
                                    : AppColors.dividerLight,
                              ),
                            ),
                            child: Text(
                              interest,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: isSelected
                                        ? AppColors.primaryGold
                                        : AppColors.textDark,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    if (_selectedInterests.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Text(
                          '${_selectedInterests.length}/8 sélectionnés',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Languages section
                    _buildSectionTitle('Langues parlées'),
                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Quelles langues parlez-vous ? (maximum 5)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _availableLanguages.map((language) {
                        final isSelected =
                            _selectedLanguages.contains(language);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedLanguages.remove(language);
                              } else if (_selectedLanguages.length < 5) {
                                _selectedLanguages.add(language);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryGold.withOpacity(0.1)
                                  : AppColors.accentCream,
                              borderRadius:
                                  BorderRadius.circular(AppBorderRadius.large),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryGold
                                    : AppColors.dividerLight,
                              ),
                            ),
                            child: Text(
                              language,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: isSelected
                                        ? AppColors.primaryGold
                                        : AppColors.textDark,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    if (_selectedLanguages.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Text(
                          '${_selectedLanguages.length}/5 sélectionnées',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _continue,
                      child: const Text('Continuer'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _skip,
                      child: const Text('Passer cette étape'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryGold,
          ),
    );
  }

  void _continue() {
    _saveAdditionalInfo();
    _navigateToProfileSetup();
  }

  void _skip() {
    _navigateToProfileSetup();
  }

  void _saveAdditionalInfo() {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);

    // Save professional info
    if (_jobTitleController.text.isNotEmpty) {
      profileProvider.setJobTitle(_jobTitleController.text.trim());
    }

    if (_companyController.text.isNotEmpty) {
      profileProvider.setCompany(_companyController.text.trim());
    }

    if (_educationController.text.isNotEmpty) {
      profileProvider.setEducation(_educationController.text.trim());
    }

    // Save height
    if (_heightController.text.isNotEmpty) {
      final height = int.tryParse(_heightController.text);
      if (height != null && height > 0) {
        profileProvider.setHeight(height);
      }
    }

    // Save interests and languages
    if (_selectedInterests.isNotEmpty) {
      profileProvider.setInterests(_selectedInterests);
    }

    if (_selectedLanguages.isNotEmpty) {
      profileProvider.setLanguages(_selectedLanguages);
    }
  }

  void _navigateToProfileSetup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileSetupPage(),
      ),
    );
  }
}
