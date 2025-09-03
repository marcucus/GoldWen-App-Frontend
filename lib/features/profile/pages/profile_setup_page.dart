import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';
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
  final List<TextEditingController> _promptControllers = List.generate(3, (index) => TextEditingController());

  final List<String> _promptQuestions = [
    'Ce qui me rend vraiment heureux(se), c\'est...',
    'Je ne peux pas vivre sans...',
    'Ma passion secrète est...',
  ];

  @override
  void initState() {
    super.initState();
    // Add listeners to update button state when user types
    _nameController.addListener(_updateButtonState);
    _bioController.addListener(_updateButtonState);
    for (final controller in _promptControllers) {
      controller.addListener(_updateButtonState);
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
      appBar: AppBar(
        title: Text('Étape ${_currentPage + 1}/4'),
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
            value: (_currentPage + 1) / 4,
            backgroundColor: AppColors.dividerLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
          ),
          
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildBasicInfoPage(),
                _buildPhotosPage(),
                _buildPromptsPage(),
                _buildReviewPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return Padding(
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
            maxLines: 3,
            maxLength: 200,
          ),
          
          const Spacer(),
          
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
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    final hasPhoto = index < profileProvider.photos.length;
                    
                    return GestureDetector(
                      onTap: hasPhoto ? null : () => _addPhoto(profileProvider),
                      child: Container(
                        decoration: BoxDecoration(
                          color: hasPhoto ? null : AppColors.accentCream,
                          borderRadius: BorderRadius.circular(AppBorderRadius.large),
                          border: Border.all(
                            color: AppColors.dividerLight,
                            width: 1,
                          ),
                        ),
                        child: hasPhoto
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.large),
                                    child: Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      color: AppColors.primaryGold.withOpacity(0.3),
                                      child: profileProvider.photos[index].startsWith('file://')
                                          ? Image.file(
                                              File(profileProvider.photos[index].replaceFirst('file://', '')),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.image,
                                                  size: 40,
                                                  color: Colors.white,
                                                );
                                              },
                                            )
                                          : const Icon(
                                              Icons.image,
                                              size: 40,
                                              color: Colors.white,
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => profileProvider.removePhoto(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 40,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    index == 0 ? 'Photo principale' : 'Ajouter une photo',
                                    style: Theme.of(context).textTheme.bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          Consumer<ProfileProvider>(
            builder: (context, profileProvider, child) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: profileProvider.photos.length >= 3 ? _nextPage : null,
                  child: Text('Continuer (${profileProvider.photos.length}/3)'),
                ),
              );
            },
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
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _promptQuestions[index],
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _promptControllers[index],
                        decoration: const InputDecoration(
                          hintText: 'Votre réponse...',
                        ),
                        maxLines: 2,
                        maxLength: 100,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _arePromptsValid() ? _nextPage : null,
              child: const Text('Continuer'),
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
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
                  'Chaque jour à 12h00, nous vous proposerons 3-5 profils soigneusement sélectionnés selon vos affinités.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
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
    return _promptControllers.every((controller) => controller.text.isNotEmpty);
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
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
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

  void _nextPage() {
    if (_currentPage < 3) {
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

  Future<void> _addPhoto(ProfileProvider profileProvider) async {
    if (profileProvider.photos.length >= 6) {
      return; // Maximum photos reached
    }

    try {
      // Show dialog to choose between camera and gallery
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        // For now, we'll add the image path as a mock URL
        // In a real app, you would upload the image to a server
        profileProvider.addPhoto('file://${image.path}');
        
        // TODO: In production, upload the image to backend
        // final uploadedUrl = await ApiService.uploadPhoto(image.path);
        // profileProvider.addPhoto(uploadedUrl);
      }
    } catch (e) {
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout de la photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choisir une source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Appareil photo'),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galerie'),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.gallery);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  void _finishSetup() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    profileProvider.setBasicInfo(
      _nameController.text,
      _calculateAge(_birthDate!),
      _bioController.text,
      birthDate: _birthDate,
    );
    
    for (int i = 0; i < _promptControllers.length; i++) {
      profileProvider.addPrompt(_promptControllers[i].text);
    }
    
    // Submit to backend and mark completion
    _saveProfileToBackend(profileProvider, authProvider);
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MainNavigationPage(),
      ),
    );
  }

  Future<void> _saveProfileToBackend(ProfileProvider profileProvider, AuthProvider authProvider) async {
    try {
      await profileProvider.saveProfile();
      await profileProvider.submitPromptAnswers();
      await authProvider.markProfileCompleted();
    } catch (e) {
      // Show error to user
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde du profil: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
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