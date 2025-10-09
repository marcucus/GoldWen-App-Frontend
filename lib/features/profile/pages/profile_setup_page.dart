import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/profile.dart';
import '../providers/profile_provider.dart';
import '../widgets/photo_management_widget.dart';
import '../widgets/media_management_widget.dart';
import '../widgets/profile_completion_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../main/pages/main_navigation_page.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final ImagePicker _picker = ImagePicker();

  final _nameController = TextEditingController();
  DateTime? _birthDate;
  final _bioController = TextEditingController();
  final List<TextEditingController> _promptControllers = List.generate(
      3,
      (index) =>
          TextEditingController()); // Should be 3 prompts as per API requirements

  List<String> _selectedPromptIds = []; // Track selected prompt IDs
  List<String> _promptQuestions = []; // Display texts for selected prompts

  @override
  void initState() {
    super.initState();
    // Add listeners to update button state when user types
    _nameController.addListener(_updateButtonState);
    _bioController.addListener(_updateButtonState);
    for (final controller in _promptControllers) {
      controller.addListener(_updateButtonState);
    }

    // Load prompts from backend
    _loadPrompts();

    // Initialize to the correct page based on profile completion
    _initializeCurrentPage();
  }

  void _initializeCurrentPage() async {
    // Load profile completion status and navigate to first missing step
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    await profileProvider.loadProfileCompletion();

    if (mounted) {
      final completion = profileProvider.profileCompletion;
      if (completion != null && !completion.isCompleted) {
        int targetPage = 0;

        // Determine which page to show first based on missing steps
        if (!completion.hasRequiredProfileFields) {
          targetPage = 0; // Basic info page
        } else if (!completion.hasPhotos) {
          targetPage = 1; // Photos page
        } else if (!completion.hasPrompts) {
          targetPage = 3; // Prompts page (skip media page which is optional)
        } else {
          targetPage = 4; // Validation page
        }

        // Navigate to the appropriate page without animation
        if (targetPage != _currentPage) {
          setState(() {
            _currentPage = targetPage;
          });
          _pageController.jumpToPage(targetPage);
        }
      }
    }
  }

  void _loadPrompts() async {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    try {
      await profileProvider.loadPrompts();

      // Select first 3 prompts automatically
      if (profileProvider.availablePrompts.length >= 3) {
        setState(() {
          _selectedPromptIds = profileProvider.availablePrompts
              .take(3) // Should be 3 prompts as per API requirements
              .map((prompt) => prompt.id)
              .toList();
          _promptQuestions = profileProvider.availablePrompts
              .take(3) // Should be 3 prompts as per API requirements
              .map((prompt) => prompt.text)
              .toList();
        });
      } else {
        // If we don't have enough prompts, show error
        throw Exception(
            'Pas assez de prompts disponibles (${profileProvider.availablePrompts.length}/3)'); // Changed from 10 to 3
      }
    } catch (e) {
      print('Error loading prompts: $e');
      // Show error instead of fallback - we need real prompt IDs from backend
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des prompts: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: _loadPrompts,
            ),
          ),
        );
      }
    }
  }

  void _updateButtonState() {
    setState(() {
      // This will trigger a rebuild and update button states
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Étape ${_currentPage + 1}/6'),
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousPage,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentPage + 1) / 6,
            backgroundColor: AppColors.dividerLight,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable horizontal swiping
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildBasicInfoPage(),
                _buildPhotosPage(),
                _buildMediaPage(),
                _buildPromptsPage(),
                _buildValidationPage(),
                _buildReviewPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),

          Text(
            'Parlez-nous de vous',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'Ces informations aideront les autres à mieux vous connaître',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Name field
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Pseudo',
              hintText: 'Votre pseudo',
            ),
            textCapitalization: TextCapitalization.words,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Birth date field
          GestureDetector(
            onTap: _selectBirthDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.dividerLight),
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _birthDate != null
                          ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                          : 'Date de naissance',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: _birthDate != null
                                ? AppColors.textDark
                                : AppColors.textSecondary,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Bio field
          TextFormField(
            controller: _bioController,
            decoration: const InputDecoration(
              labelText: 'Bio',
              hintText: 'Décrivez-vous en quelques mots...',
            ),
            maxLines: 10,
            maxLength: 200,
          ),

          const SizedBox(height: AppSpacing.xxl),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isBasicInfoValid() ? _nextPage : null,
              child: const Text('Continuer'),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildPhotosPage() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Ajoutez vos photos',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Ajoutez au moins 3 photos pour continuer',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Expanded(
            child: Consumer<ProfileProvider>(
              builder: (context, profileProvider, child) {
                return PhotoManagementWidget(
                  photos: profileProvider.photos,
                  onPhotosChanged: (photos) {
                    profileProvider.updatePhotos(photos);
                  },
                  minPhotos: 3,
                  maxPhotos: 6,
                  showAddButton: true,
                );
              },
            ),
          ),
          Consumer<ProfileProvider>(
            builder: (context, profileProvider, child) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      profileProvider.photos.length >= 3 ? _nextPage : null,
                  child:
                      Text('Continuer (${profileProvider.photos.length}/6)'),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildMediaPage() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Médias Audio/Vidéo (Optionnel)',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Ajoutez des fichiers audio ou vidéo pour enrichir votre profil',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Expanded(
            child: Consumer<ProfileProvider>(
              builder: (context, profileProvider, child) {
                return MediaManagementWidget(
                  mediaFiles: profileProvider.mediaFiles,
                  onMediaFilesChanged: (mediaFiles) {
                    profileProvider.updateMediaFiles(mediaFiles);
                  },
                  maxAudioFiles: 2,
                  maxVideoFiles: 1,
                  showAddButton: true,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              child: const Text('Continuer'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildPromptsPage() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Complétez ces phrases',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Cela aide les autres à mieux vous connaître',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Expanded(
            child: _promptQuestions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppSpacing.md),
                        const Text('Chargement des questions...'),
                        const SizedBox(height: AppSpacing.lg),
                        TextButton(
                          onPressed: _loadPrompts,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: 3, // Should be 3 prompts as per API requirements
                    itemBuilder: (context, index) {
                      // Make sure we don't go out of bounds
                      final questionText = index < _promptQuestions.length
                          ? _promptQuestions[index]
                          : 'Question ${index + 1}...';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              questionText,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _promptControllers[index],
                              decoration: InputDecoration(
                                hintText:
                                    'Votre réponse... (max 300 caractères)',
                                counterText:
                                    '${_promptControllers[index].text.length}/300',
                              ),
                              maxLines: 3,
                              maxLength: 300,
                              onChanged: (text) {
                                setState(() {
                                  // This will trigger a rebuild to update validation and counter
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Progress indicator for prompts validation
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getValidAnswersCount() == 3
                      ? Icons.check_circle
                      : Icons.pending,
                  color: _getValidAnswersCount() == 3
                      ? Colors.green
                      : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Réponses complétées: ${_getValidAnswersCount()}/3',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getValidAnswersCount() == 3
                            ? Colors.green
                            : AppColors.textSecondary,
                        fontWeight: _getValidAnswersCount() == 3
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _arePromptsValid() ? _nextPage : null,
              child: Text(
                _arePromptsValid()
                    ? 'Continuer'
                    : 'Complétez les 3 réponses (${_getValidAnswersCount()}/3)',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildValidationPage() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Validation du profil',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Vérifiez que votre profil est complet avant activation',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Expanded(
            child: SingleChildScrollView(
              child: Consumer<ProfileProvider>(
                builder: (context, profileProvider, child) {
                  return ProfileCompletionWidget(
                    showProgress: true,
                    onMissingStepTap: _handleMissingStepTap,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: Consumer<ProfileProvider>(
              builder: (context, profileProvider, child) {
                final isComplete =
                    profileProvider.profileCompletion?.isCompleted ?? false;
                return ElevatedButton(
                  onPressed: isComplete ? _nextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isComplete
                        ? AppColors.primaryGold
                        : AppColors.textTertiary,
                  ),
                  child: Text(
                    isComplete ? 'Continuer' : 'Profil incomplet',
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  void _handleMissingStepTap() {
    // Navigate to the appropriate page based on missing steps
    final completion =
        Provider.of<ProfileProvider>(context, listen: false).profileCompletion;
    if (completion == null) return;

    if (!completion.hasRequiredProfileFields) {
      // Go to basic info page
      _goToPage(0);
    } else if (!completion.hasPhotos) {
      // Go to photos page
      _goToPage(1);
    } else if (!completion.hasPrompts) {
      // Go to prompts page (page 3, not 2 which is media)
      _goToPage(3);
    } else if (!completion.hasPersonalityAnswers) {
      // Show message about personality questionnaire
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Vous devez d\'abord compléter le questionnaire de personnalité'),
        ),
      );
    }
  }

  void _goToPage(int pageIndex) {
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildReviewPage() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Parfait !',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Votre profil est maintenant prêt. Vous recevrez votre première sélection demain à midi.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.accentCream,
              borderRadius: BorderRadius.circular(AppBorderRadius.large),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.schedule,
                  size: 48,
                  color: AppColors.primaryGold,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Votre rituel quotidien',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primaryGold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Chaque jour à 12h00, nous vous proposerons 10-5 profils soigneusement sélectionnés selon vos affinités.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _finishSetup,
              child: const Text('Commencer mon aventure'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  bool _isBasicInfoValid() {
    return _nameController.text.isNotEmpty &&
        _birthDate != null &&
        _bioController.text.isNotEmpty;
  }

  bool _arePromptsValid() {
    // Should be 3 prompts as per API requirements
    if (_promptControllers.length != 3) return false;

    // All 3 controllers must have non-empty text within character limit
    for (final controller in _promptControllers) {
      final text = controller.text.trim();
      if (text.isEmpty || text.length > 300) {
        return false;
      }
    }

    return true;
  }

  int _getValidAnswersCount() {
    int count = 0;
    for (final controller in _promptControllers) {
      final text = controller.text.trim();
      if (text.isNotEmpty && text.length <= 300) {
        count++;
      }
    }
    return count;
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryGold,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  void _nextPage() async {
    if (_currentPage < 5) { // Changed from 4 to 5 since we have 6 pages (0-5)
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);

      // Save basic info when leaving basic info page
      if (_currentPage == 0) {
        // Moving from basic info to photos
        if (_birthDate != null) {
          profileProvider.setBasicInfo(
            _nameController.text.trim(),
            _calculateAge(_birthDate!),
            _bioController.text.trim(),
            birthDate: _birthDate,
          );
        }
      }

      // Save prompt answers when leaving prompts page
      if (_currentPage == 3) { // Changed from 2 to 3 (prompts is now page 3)
        // Moving from prompts to validation
        try {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          // Save current data to provider first (if not already saved)
          if (_birthDate != null) {
            profileProvider.setBasicInfo(
              _nameController.text.trim(),
              _calculateAge(_birthDate!),
              _bioController.text.trim(),
              birthDate: _birthDate,
            );
          }

          // Set prompt answers in provider
          for (int i = 0;
              i < _promptControllers.length && i < _selectedPromptIds.length;
              i++) {
            if (_promptControllers[i].text.isNotEmpty) {
              profileProvider.setPromptAnswer(
                  _selectedPromptIds[i], _promptControllers[i].text.trim());
            }
          }

          // Persist profile data to backend
          await profileProvider.saveProfile();

          // Persist prompt answers to backend
          await profileProvider.submitPromptAnswers();

          // Load updated completion status from backend
          await profileProvider.loadProfileCompletion();

          // Hide loading indicator
          if (mounted) Navigator.of(context).pop();
        } catch (e) {
          // Hide loading indicator
          if (mounted) Navigator.of(context).pop();

          print('Error saving profile data: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de la sauvegarde: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 10),
              ),
            );
          }
          return; // Don't proceed to next page if save failed
        }
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishSetup() {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Validate required fields
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir votre pseudo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner votre date de naissance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_bioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez rédiger votre bio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate that we have valid prompt IDs before proceeding
    if (_selectedPromptIds.isEmpty ||
        _selectedPromptIds.any((id) => id.startsWith('fallback'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Erreur: Les prompts n\'ont pas été chargés correctement. Veuillez redémarrer l\'application.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    // Validate prompt answers - must have exactly 3 valid responses
    if (_promptControllers.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: 3 prompts requis pour continuer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    for (int i = 0; i < _promptControllers.length; i++) {
      final text = _promptControllers[i].text.trim();
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veuillez répondre à la question ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (text.length > 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'La réponse ${i + 1} dépasse 300 caractères (${text.length}/300)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    profileProvider.setBasicInfo(
      _nameController.text.trim(),
      _calculateAge(_birthDate!),
      _bioController.text.trim(),
      birthDate: _birthDate,
    );

    // Set prompt answers using real prompt IDs
    for (int i = 0;
        i < _promptControllers.length && i < _selectedPromptIds.length;
        i++) {
      if (_promptControllers[i].text.isNotEmpty) {
        print(
            'Setting prompt answer: ${_selectedPromptIds[i]} -> ${_promptControllers[i].text}');
        profileProvider.setPromptAnswer(
            _selectedPromptIds[i], _promptControllers[i].text.trim());
      }
    }

    // Submit to backend and mark completion
    _saveProfileToBackend(profileProvider, authProvider);
  }

  Future<void> _saveProfileToBackend(
      ProfileProvider profileProvider, AuthProvider authProvider) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Sauvegarde en cours...'),
          ],
        ),
      ),
    );

    try {
      print('Starting profile save process...');
      await profileProvider.saveProfile();
      print('Profile basic data saved successfully');

      await profileProvider.submitPromptAnswers();
      print('Prompt answers submitted successfully');

      // Check if profile is complete and validate for activation
      await profileProvider.loadProfileCompletion();

      if (profileProvider.profileCompletion?.isCompleted ?? false) {
        // Profile is complete, can activate
        await profileProvider.validateAndActivateProfile();
        print('Profile validated and activated successfully');

        // Refresh user data to get updated completion status from backend
        await authProvider.refreshUser();
        print('User data refreshed successfully');

        // Close loading dialog and navigate using GoRouter
        if (mounted) {
          // Close dialog first
          context.pop(); // This closes the dialog

          // Navigate to main page using GoRouter
          context.pushReplacement('/home');
        }
      } else {
        // Profile is not complete, show missing steps
        if (mounted) {
          context.pop(); // Close loading dialog

          _showProfileIncompleteDialog(profileProvider.profileCompletion);
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        context.pop(); // Close dialog using GoRouter
      }

      // Show error to user
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Erreur lors de la sauvegarde du profil: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: () =>
                  _saveProfileToBackend(profileProvider, authProvider),
            ),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  void _showProfileIncompleteDialog(ProfileCompletion? completion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil incomplet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Votre profil n\'est pas encore complet. Étapes manquantes:'),
            const SizedBox(height: 8),
            if (completion?.missingSteps.isNotEmpty ?? false)
              ...completion!.missingSteps
                  .map((step) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_right,
                                size: 16, color: AppColors.warningAmber),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(step,
                                    style:
                                        Theme.of(context).textTheme.bodySmall)),
                          ],
                        ),
                      ))
                  .toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Remove listeners before disposing
    _nameController.removeListener(_updateButtonState);
    _bioController.removeListener(_updateButtonState);
    for (final controller in _promptControllers) {
      controller.removeListener(_updateButtonState);
    }

    _nameController.dispose();
    _bioController.dispose();
    for (final controller in _promptControllers) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }
}
