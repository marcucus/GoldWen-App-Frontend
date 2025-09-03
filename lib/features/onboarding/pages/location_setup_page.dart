import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/providers/profile_provider.dart';
import 'preferences_setup_page.dart';

class LocationSetupPage extends StatefulWidget {
  const LocationSetupPage({super.key});

  @override
  State<LocationSetupPage> createState() => _LocationSetupPageState();
}

class _LocationSetupPageState extends State<LocationSetupPage> {
  final _locationController = TextEditingController();
  bool _isLoadingLocation = false;
  String? _detectedCity;
  double? _latitude;
  double? _longitude;
  String? _errorMessage;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              const SizedBox(height: AppSpacing.xl),
              
              // Title and subtitle
              Text(
                'Où habitez-vous ?',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Text(
                'Nous utilisons votre localisation pour vous proposer des profils à proximité.',
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
                      'Détection automatique',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryGold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Utilisez votre position actuelle',
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
                        label: Text(_isLoadingLocation ? 'Détection...' : 'Détecter ma position'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Or divider
              Row(
                children: [
                  const Expanded(
                    child: Divider(color: AppColors.dividerLight),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      'ou',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(color: AppColors.dividerLight),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Manual location input
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  hintText: 'Paris, Lyon, Marseille...',
                  prefixIcon: Icon(Icons.location_city),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (value) {
                  setState(() {
                    _errorMessage = null;
                  });
                },
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Show detected location if available
              if (_detectedCity != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
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
              
              const Spacer(),
              
              // Continue button
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
    return _locationController.text.isNotEmpty || _detectedCity != null;
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      // Check and request permission
      PermissionStatus permission = await Permission.location.request();
      
      if (permission != PermissionStatus.granted) {
        setState(() {
          _errorMessage = 'Permission de localisation refusée. Veuillez entrer votre ville manuellement.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Les services de localisation sont désactivés. Veuillez les activer ou entrer votre ville manuellement.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _detectedCity = 'Position détectée (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        _locationController.clear();
        _isLoadingLocation = false;
      });

      // In a real app, you would reverse geocode to get the city name
      // For now, we'll use a placeholder
      // TODO: Implement reverse geocoding to get actual city name
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de détecter votre position. Veuillez entrer votre ville manuellement.';
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
    } else if (_locationController.text.isNotEmpty) {
      // Use manually entered location
      profileProvider.setLocation(
        location: _locationController.text.trim(),
        latitude: null, // Will be geocoded later if needed
        longitude: null,
      );
    }
    
    // Navigate to preferences setup page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PreferencesSetupPage(),
      ),
    );
  }
}