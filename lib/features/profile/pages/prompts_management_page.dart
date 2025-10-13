import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/profile.dart';
import '../providers/profile_provider.dart';
import '../widgets/prompt_selection_widget.dart';

class PromptsManagementPage extends StatefulWidget {
  const PromptsManagementPage({super.key});

  @override
  State<PromptsManagementPage> createState() => _PromptsManagementPageState();
}

class _PromptsManagementPageState extends State<PromptsManagementPage> {
  bool _isEditMode = false;
  List<String> _selectedPromptIds = [];
  final Map<String, TextEditingController> _answerControllers = {};
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPrompts();
  }

  @override
  void dispose() {
    for (final controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCurrentPrompts() async {
    setState(() {
      _isLoading = true;
    });

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    
    try {
      await profileProvider.loadPrompts();
      await profileProvider.loadProfile();

      if (mounted) {
        setState(() {
          // Get current prompt answers from provider
          _selectedPromptIds = profileProvider.promptAnswers.keys.toList();
          
          // Initialize controllers with current answers
          for (final entry in profileProvider.promptAnswers.entries) {
            _answerControllers[entry.key] = TextEditingController(text: entry.value);
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _savePrompts() async {
    // Validate that all selected prompts have answers
    for (final promptId in _selectedPromptIds) {
      final controller = _answerControllers[promptId];
      if (controller == null || controller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez répondre à tous les prompts sélectionnés'),
            backgroundColor: AppColors.warningOrange,
          ),
        );
        return;
      }

      if (controller.text.trim().length > 150) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les réponses ne doivent pas dépasser 150 caractères'),
            backgroundColor: AppColors.warningOrange,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    try {
      // Clear existing answers
      profileProvider.clearPromptAnswers();

      // Set new answers
      for (final promptId in _selectedPromptIds) {
        final answer = _answerControllers[promptId]!.text.trim();
        profileProvider.setPromptAnswer(promptId, answer);
      }

      // Submit to backend
      await profileProvider.submitPromptAnswers();

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEditMode = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prompts mis à jour avec succès'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditMode = false;
      
      // Restore original values
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      _selectedPromptIds = profileProvider.promptAnswers.keys.toList();
      
      // Reset controllers
      for (final controller in _answerControllers.values) {
        controller.dispose();
      }
      _answerControllers.clear();
      
      for (final entry in profileProvider.promptAnswers.entries) {
        _answerControllers[entry.key] = TextEditingController(text: entry.value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer mes prompts'),
        actions: [
          if (!_isEditMode && !_isLoading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditMode = true;
                });
              },
              tooltip: 'Modifier',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<ProfileProvider>(
              builder: (context, profileProvider, child) {
                if (_isEditMode) {
                  return Column(
                    children: [
                      // Step 1: Select prompts
                      if (_selectedPromptIds.length < 3)
                        Expanded(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Étape 1: Sélectionnez vos prompts',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Choisissez 3 prompts qui vous représentent',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: PromptSelectionWidget(
                                  availablePrompts: profileProvider.availablePrompts,
                                  selectedPromptIds: _selectedPromptIds,
                                  onSelectionChanged: (newSelection) {
                                    setState(() {
                                      _selectedPromptIds = newSelection;
                                      
                                      // Create controllers for newly selected prompts
                                      for (final id in newSelection) {
                                        if (!_answerControllers.containsKey(id)) {
                                          _answerControllers[id] = TextEditingController();
                                        }
                                      }
                                      
                                      // Remove controllers for deselected prompts
                                      final keysToRemove = _answerControllers.keys
                                          .where((key) => !newSelection.contains(key))
                                          .toList();
                                      for (final key in keysToRemove) {
                                        _answerControllers[key]?.dispose();
                                        _answerControllers.remove(key);
                                      }
                                    });
                                  },
                                  maxSelection: 3,
                                ),
                              ),
                            ],
                          ),
                        )
                      // Step 2: Answer prompts
                      else
                        Expanded(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.arrow_back),
                                          onPressed: () {
                                            setState(() {
                                              _selectedPromptIds.clear();
                                            });
                                          },
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Étape 2: Répondez aux prompts',
                                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                              ),
                                              Text(
                                                'Maximum 150 caractères par réponse',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: AppColors.textSecondary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  itemCount: _selectedPromptIds.length,
                                  itemBuilder: (context, index) {
                                    final promptId = _selectedPromptIds[index];
                                    final prompt = profileProvider.availablePrompts
                                        .firstWhere((p) => p.id == promptId);
                                    final controller = _answerControllers[promptId]!;

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                                      child: Padding(
                                        padding: const EdgeInsets.all(AppSpacing.md),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              prompt.text,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: AppSpacing.sm),
                                            TextField(
                                              controller: controller,
                                              decoration: InputDecoration(
                                                hintText: 'Votre réponse...',
                                                counterText: '${controller.text.length}/150',
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              maxLines: 3,
                                              maxLength: 150,
                                              onChanged: (_) {
                                                setState(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Action buttons
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowMedium,
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSaving ? null : _cancelEdit,
                                  child: const Text('Annuler'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSaving || _selectedPromptIds.length != 3
                                      ? null
                                      : _savePrompts,
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text('Enregistrer'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Display mode
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    Text(
                      'Mes prompts',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    if (profileProvider.promptAnswers.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                          child: Column(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Aucun prompt configuré',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Ajoutez des prompts pour enrichir votre profil',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...profileProvider.promptAnswers.entries.map((entry) {
                        final prompt = profileProvider.availablePrompts.firstWhere(
                          (p) => p.id == entry.key,
                          orElse: () => Prompt(
                            id: entry.key,
                            text: 'Prompt inconnu',
                            category: 'general',
                            active: true,
                          ),
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prompt.text,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  entry.value,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                );
              },
            ),
    );
  }
}
