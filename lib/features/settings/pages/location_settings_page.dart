import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/location_service.dart';
import '../../profile/providers/profile_provider.dart';

/// Settings screen letting the user check / refresh the location GoldWen
/// uses to build their daily selection. `LocationService` and `geolocator`
/// already existed (used during onboarding) but had no post-onboarding
/// entry point (item 3.1 of the finalisation plan, ":821 Localisation").
class LocationSettingsPage extends StatefulWidget {
  const LocationSettingsPage({super.key});

  @override
  State<LocationSettingsPage> createState() => _LocationSettingsPageState();
}

class _LocationSettingsPageState extends State<LocationSettingsPage> {
  bool _isRefreshing = false;
  String? _error;
  String? _successMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localisation'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, _) {
          final hasLocation = profileProvider.location != null &&
              profileProvider.location!.isNotEmpty;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.accentCream.withValues(alpha: 0.4),
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.large),
                      border: Border.all(color: AppColors.dividerLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: AppColors.primaryGold, size: 32),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Position actuelle',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasLocation
                                    ? profileProvider.location!
                                    : 'Non définie',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'GoldWen utilise votre position pour vous proposer des profils à '
                    'proximité et affiner votre sélection quotidienne. Elle est mise à '
                    'jour automatiquement toutes les 15 minutes lorsque l\'app est ouverte ; '
                    'vous pouvez aussi la rafraîchir manuellement ici.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(_error!,
                          style: const TextStyle(color: AppColors.errorRed)),
                    ),
                  if (_successMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(_successMessage!,
                          style:
                              const TextStyle(color: AppColors.successGreen)),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isRefreshing
                          ? null
                          : () => _refreshLocation(profileProvider),
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.my_location_rounded),
                      label: Text(_isRefreshing
                          ? 'Actualisation...'
                          : 'Actualiser ma position'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshLocation(ProfileProvider profileProvider) async {
    setState(() {
      _isRefreshing = true;
      _error = null;
      _successMessage = null;
    });

    try {
      bool hasPermission = await LocationService.checkLocationPermission();
      if (!hasPermission) {
        hasPermission = await LocationService.requestLocationAccess();
      }
      if (!hasPermission) {
        setState(() {
          _isRefreshing = false;
          _error =
              'Autorisation de localisation refusée. Activez-la dans les paramètres de votre appareil.';
        });
        return;
      }

      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        setState(() {
          _isRefreshing = false;
          _error = 'Impossible de détecter votre position. Réessayez.';
        });
        return;
      }

      // Persist to the backend directly: setLocation() only updates
      // local onboarding state and never calls the API by itself.
      await ApiService.updateProfile({
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
      profileProvider.setLocation(
        location:
            'Position détectée (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})',
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Keep the background service in sync too.
      unawaited(LocationService().initialize());

      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _successMessage = 'Position mise à jour.';
        });
      }
    } catch (e) {
      setState(() {
        _isRefreshing = false;
        _error = 'Erreur lors de la mise à jour de la position.';
      });
    }
  }
}

