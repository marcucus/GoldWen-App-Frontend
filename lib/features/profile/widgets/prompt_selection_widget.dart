import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/profile.dart';

class PromptSelectionWidget extends StatefulWidget {
  final List<Prompt> availablePrompts;
  final List<String> selectedPromptIds;
  final Function(List<String>) onSelectionChanged;
  final int maxSelection;

  const PromptSelectionWidget({
    super.key,
    required this.availablePrompts,
    required this.selectedPromptIds,
    required this.onSelectionChanged,
    this.maxSelection = 3,
  });

  @override
  State<PromptSelectionWidget> createState() => _PromptSelectionWidgetState();
}

class _PromptSelectionWidgetState extends State<PromptSelectionWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Tous';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final categories = ['Tous'];
    final uniqueCategories = widget.availablePrompts
        .map((prompt) => prompt.category)
        .toSet()
        .toList()
      ..sort();
    categories.addAll(uniqueCategories);
    return categories;
  }

  List<Prompt> get _filteredPrompts {
    return widget.availablePrompts.where((prompt) {
      final matchesSearch =
          _searchQuery.isEmpty || prompt.text.toLowerCase().contains(_searchQuery);
      final matchesCategory =
          _selectedCategory == 'Tous' || prompt.category == _selectedCategory;
      return matchesSearch && matchesCategory && prompt.active;
    }).toList();
  }

  void _togglePromptSelection(String promptId) {
    final List<String> newSelection = List.from(widget.selectedPromptIds);
    
    if (newSelection.contains(promptId)) {
      newSelection.remove(promptId);
    } else {
      if (newSelection.length < widget.maxSelection) {
        newSelection.add(promptId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vous ne pouvez sélectionner que ${widget.maxSelection} prompts maximum'),
            backgroundColor: AppColors.warningOrange,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }
    
    widget.onSelectionChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un prompt...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
              ),
            ),
          ),
        ),

        // Category filter chips
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;
              
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  selectedColor: AppColors.primaryGold.withOpacity(0.2),
                  checkmarkColor: AppColors.primaryGold,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primaryGold : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Selection counter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prompts sélectionnés',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: widget.selectedPromptIds.length == widget.maxSelection
                      ? AppColors.successGreen.withOpacity(0.2)
                      : AppColors.primaryGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.selectedPromptIds.length}/${widget.maxSelection}',
                  style: TextStyle(
                    color: widget.selectedPromptIds.length == widget.maxSelection
                        ? AppColors.successGreen
                        : AppColors.primaryGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Prompts list
        Expanded(
          child: _filteredPrompts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Aucun prompt trouvé',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: _filteredPrompts.length,
                  itemBuilder: (context, index) {
                    final prompt = _filteredPrompts[index];
                    final isSelected = widget.selectedPromptIds.contains(prompt.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryGold
                              : AppColors.borderColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _togglePromptSelection(prompt.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prompt.text,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.backgroundGrey,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        prompt.category,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.primaryGold
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryGold
                                        : AppColors.borderColor,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
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
      ],
    );
  }
}
