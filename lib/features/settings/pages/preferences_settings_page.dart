import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';

/// Settings screen for the user's matching criteria (age range, distance,
/// preferred genders, visibility in the daily selection).
///
/// Reads and writes `GET/PUT /preferences/me` — the backend endpoint has
/// existed since the audit but was never called from the app (item 3.1 of
/// the finalisation plan, ":661 Préférences").
class PreferencesSettingsPage extends StatefulWidget {
  const PreferencesSettingsPage({super.key});

  @override
  State<PreferencesSettingsPage> createState() =>
      _PreferencesSettingsPageState();
}

class _GenderOption {
  final String value;
  final String label;
  const _GenderOption(this.value, this.label);
}

class _PreferencesSettingsPageState extends State<PreferencesSettingsPage> {
  static const List<_GenderOption> _genderOptions = [
    _GenderOption('man', 'Hommes'),
    _GenderOption('woman', 'Femmes'),
    _GenderOption('non_binary', 'Personnes non-binaires'),
    _GenderOption('other', 'Autres'),
  ];

  static const double _minAgeLimit = 18;
  static const double _maxAgeLimit = 80;
  static const double _maxDistanceLimit = 100;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  double _minAge = 18;
  double _maxAge = 45;
  double _maxDistance = 50;
  final Set<String> _preferredGenders = {};
  bool _showMeInDiscovery = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiService.getPreferences();
      final data = (response['data'] ?? response) as Map<String, dynamic>;
      final filters = (data['filters'] ?? {}) as Map<String, dynamic>;

      setState(() {
        _minAge = ((filters['ageMin'] as num?) ?? 18).toDouble().clamp(
            _minAgeLimit, _maxAgeLimit);
        _maxAge = ((filters['ageMax'] as num?) ?? 45).toDouble().clamp(
            _minAgeLimit, _maxAgeLimit);
        _maxDistance = ((filters['maxDistance'] as num?) ?? 50)
            .toDouble()
            .clamp(1, _maxDistanceLimit);
        _showMeInDiscovery = (filters['showMeInDiscovery'] as bool?) ?? true;
        _preferredGenders
          ..clear()
          ..addAll(
            ((filters['preferredGenders'] as List?) ?? const [])
                .map((g) => g.toString()),
          );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Impossible de charger vos préférences. Réessayez.';
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await ApiService.updatePreferences({
        'filters': {
          'ageMin': _minAge.round(),
          'ageMax': _maxAge.round(),
          'maxDistance': _maxDistance.round(),
          'preferredGenders': _preferredGenders.toList(),
          'showMeInDiscovery': _showMeInDiscovery,
        },
      });
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Préférences enregistrées')),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _error = 'L\'enregistrement a échoué. Réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Préférences'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryGold),
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Critères de recherche',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Ces critères affinent votre sélection quotidienne. '
                      'La taille de la sélection (5 profils/jour) ne change pas.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.medium),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.errorRed),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Âge : ${_minAge.round()} - ${_maxAge.round()} ans',
                                style: Theme.of(context).textTheme.titleMedium),
                            RangeSlider(
                              values: RangeValues(_minAge, _maxAge),
                              min: _minAgeLimit,
                              max: _maxAgeLimit,
                              divisions:
                                  (_maxAgeLimit - _minAgeLimit).round(),
                              activeColor: AppColors.primaryGold,
                              labels: RangeLabels(
                                  '${_minAge.round()}', '${_maxAge.round()}'),
                              onChanged: (values) {
                                setState(() {
                                  _minAge = values.start;
                                  _maxAge = values.end;
                                });
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              _maxDistance >= _maxDistanceLimit
                                  ? 'Distance : aucune limite'
                                  : 'Distance : jusqu\'à ${_maxDistance.round()} km',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Slider(
                              value: _maxDistance,
                              min: 1,
                              max: _maxDistanceLimit,
                              divisions: _maxDistanceLimit.round(),
                              activeColor: AppColors.primaryGold,
                              onChanged: (value) {
                                setState(() => _maxDistance = value);
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text('Je souhaite rencontrer',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: _genderOptions.map((option) {
                                final selected =
                                    _preferredGenders.contains(option.value);
                                return FilterChip(
                                  label: Text(option.label),
                                  selected: selected,
                                  selectedColor: AppColors.primaryGold
                                      .withValues(alpha: 0.2),
                                  checkmarkColor: AppColors.primaryGold,
                                  onSelected: (value) {
                                    setState(() {
                                      if (value) {
                                        _preferredGenders.add(option.value);
                                      } else {
                                        _preferredGenders.remove(option.value);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Être visible dans les sélections'),
                              subtitle: const Text(
                                  'Désactivez pour ne plus apparaître dans la sélection quotidienne des autres membres.'),
                              value: _showMeInDiscovery,
                              activeThumbColor: AppColors.primaryGold,
                              onChanged: (value) {
                                setState(() => _showMeInDiscovery = value);
                              },
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isSaving ||
                                _preferredGenders.isEmpty)
                            ? null
                            : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Enregistrer'),
                      ),
                    ),
                    if (_preferredGenders.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          'Sélectionnez au moins un genre pour enregistrer.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
