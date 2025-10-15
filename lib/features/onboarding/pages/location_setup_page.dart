import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/location_service.dart';
import '../../profile/providers/profile_provider.dart';
import 'preferences_setup_page.dart';

class LocationSetupPage extends StatefulWidget {
  const LocationSetupPage({super.key});

  @override
  State<LocationSetupPage> createState() => _LocationSetupPageState();
}

class _LocationSetupPageState extends State<LocationSetupPage> {
  bool _isLoadingLocation = false;
  String? _detectedCity;
  double? _latitude;
  double? _longitude;
  String? _errorMessage;
  bool _permissionPermanentlyDenied = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Ma localisation'),
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
              // Scrollable content area
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Title and subtitle
                      Text(
                        'Localisation requise',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      Text(
                        'Pour vous proposer les meilleurs profils à proximité, nous avons besoin d\'accéder à votre position. Cette autorisation est obligatoire pour utiliser GoldWen.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: AppSpacing.xxl),
                      
                      // Auto-detect location button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.accentCream,
                          borderRadius: BorderRadius.circular(AppBorderRadius.large),
                          border: Border.all(color: AppColors.dividerLight),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.my_location,
                              color: AppColors.primaryGold,
                              size: 48,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Activer la localisation',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.primaryGold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Autorisez l\'accès à votre position pour continuer',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoadingLocation ? null : _detectLocation,
                                icon: _isLoadingLocation
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.location_on),
                                label: Text(_isLoadingLocation ? 'Activation...' : 'Activer la localisation'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Information about mandatory location
                      if (_permissionPermanentlyDenied)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(AppBorderRadius.large),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.settings,
                                color: Colors.orange.shade600,
                                size: 48,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Paramètres d\'application',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.orange.shade600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'La localisation a été définitivement refusée. Veuillez l\'activer dans les paramètres de votre téléphone pour continuer.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.orange.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _openAppSettings,
                                  icon: const Icon(Icons.settings),
                                  label: const Text('Ouvrir les paramètres'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.accentCream.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(AppBorderRadius.large),
                            border: Border.all(color: AppColors.dividerLight),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.textSecondary,
                                size: 48,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Pourquoi la localisation ?',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'GoldWen utilise votre position pour :\n• Vous proposer des profils à proximité\n• Améliorer la qualité des suggestions\n• Mettre à jour automatiquement votre zone de recherche',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      
                      // Show detected location if available
                      if (_detectedCity != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          margin: const EdgeInsets.only(top: AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade600),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Position détectée: $_detectedCity',
                                  style: TextStyle(color: Colors.green.shade600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Error message
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          margin: const EdgeInsets.only(top: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade600),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Add some bottom padding to ensure content doesn't stick to the button
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
              
              // Fixed Continue button at bottom
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canContinue() ? _continue : null,
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

  bool _canContinue() {
    return _detectedCity != null && _latitude != null && _longitude != null;
  }

Future<void> _detectLocation() async {
  setState(() {
    _isLoadingLocation = true;
    _errorMessage = null;
    _permissionPermanentlyDenied = false;
  });

  try {
    // Demande explicite de la permission
    final status = await Permission.location.request();

    if (status.isGranted) {
      // Get current position
      Position? position = await LocationService.getCurrentPosition();
      if (position == null) {
        setState(() {
          _errorMessage = 'Impossible de détecter votre position. Veuillez réessayer.';
          _isLoadingLocation = false;
        });
        return;
      }
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _detectedCity = 'Position détectée (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        _isLoadingLocation = false;
      });
      LocationService().initialize();
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _permissionPermanentlyDenied = true;
        _errorMessage = 'L\'autorisation de localisation a été définitivement refusée. Vous devez l\'activer dans les paramètres pour continuer.';
        _isLoadingLocation = false;
      });
    } else if (status.isDenied) {
      setState(() {
        _errorMessage = 'L\'autorisation de localisation est nécessaire pour utiliser GoldWen. Veuillez accepter l\'autorisation pour continuer.';
        _isLoadingLocation = false;
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Erreur lors de la détection de votre position. Veuillez réessayer.';
      _isLoadingLocation = false;
    });
  }
}

  void _continue() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    
    if (_detectedCity != null && _latitude != null && _longitude != null) {
      // Use detected location
      profileProvider.setLocation(
        location: _detectedCity!,
        latitude: _latitude,
        longitude: _longitude,
      );
      
      // Navigate to preferences setup page
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PreferencesSetupPage(),
        ),
      );
    }
  }

  void _openAppSettings() async {
    await openAppSettings();
    // After user returns from settings, check permission again
    await Future.delayed(const Duration(milliseconds: 500));
    bool hasPermission = await LocationService.checkLocationPermission();
    if (hasPermission) {
      setState(() {
        _permissionPermanentlyDenied = false;
        _errorMessage = null;
      });
    }
  }
}