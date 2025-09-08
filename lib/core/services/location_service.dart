import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';
import 'package:flutter/widgets.dart';

class LocationService extends ChangeNotifier with WidgetsBindingObserver {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Timer? _locationTimer;
  Position? _currentPosition;
  bool _hasPermission = false;
  bool _isServiceEnabled = false;
  StreamSubscription<Position>? _positionStream;
  bool _isAppInForeground = true;

  // Location update interval (15 minutes)
  static const Duration _updateInterval = Duration(minutes: 15);

  Position? get currentPosition => _currentPosition;
  bool get hasPermission => _hasPermission;
  bool get isServiceEnabled => _isServiceEnabled;

  /// Initialize the location service and request permissions
  Future<bool> initialize() async {
    try {
      // Register for app lifecycle changes
      WidgetsBinding.instance.addObserver(this);

      // Check if location services are enabled
      _isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_isServiceEnabled) {
        debugPrint('LocationService: Location services are disabled');
        return false;
      }

      // Check current permission status
      PermissionStatus permission = await Permission.location.status;

      if (permission != PermissionStatus.granted) {
        // Request location permission
        permission = await Permission.location.request();
      }

      _hasPermission = permission == PermissionStatus.granted;

      if (!_hasPermission) {
        debugPrint('LocationService: Location permission denied');
        return false;
      }

      // Get initial position
      await _updateCurrentPosition();

      // Start periodic location updates
      _startPeriodicUpdates();

      debugPrint('LocationService: Initialized successfully');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('LocationService: Initialization failed: $e');
      return false;
    }
  }

  /// Start periodic location updates
  void _startPeriodicUpdates() {
    _locationTimer?.cancel();

    _locationTimer = Timer.periodic(_updateInterval, (timer) async {
      await _updateCurrentPosition();
    });

    debugPrint('LocationService: Started periodic location updates');
  }

  /// Update current position and send to backend
  Future<void> _updateCurrentPosition() async {
    try {
      if (!_hasPermission || !_isServiceEnabled || !_isAppInForeground) {
        debugPrint(
            'LocationService: Cannot update position - no permission, service disabled, or app in background');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentPosition = position;

      // Send location update to backend
      await _sendLocationToBackend(position.latitude, position.longitude);

      debugPrint(
          'LocationService: Position updated - Lat: ${position.latitude}, Lng: ${position.longitude}');
      notifyListeners();
    } catch (e) {
      debugPrint('LocationService: Failed to update position: $e');
    }
  }

  /// Send location data to backend
  Future<void> _sendLocationToBackend(double latitude, double longitude) async {
    try {
      await ApiService.updateProfile({
        'latitude': latitude,
        'longitude': longitude,
      });
      debugPrint('LocationService: Location sent to backend successfully');
    } catch (e) {
      debugPrint('LocationService: Failed to send location to backend: $e');
      // Don't throw the error to avoid breaking the location service
    }
  }

  /// Check if location permission is granted
  static Future<bool> checkLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // Check permission status
      PermissionStatus permission = await Permission.location.status;
      return permission == PermissionStatus.granted;
    } catch (e) {
      debugPrint('LocationService: Error checking permission: $e');
      return false;
    }
  }

  /// Request location permission and services
  static Future<bool> requestLocationAccess() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Try to open location settings
        await Geolocator.openLocationSettings();

        // Check again after potential user action
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          return false;
        }
      }

      // Request location permission
      PermissionStatus permission = await Permission.location.request();

      if (permission == PermissionStatus.denied) {
        // Try again if denied
        permission = await Permission.location.request();
      }

      if (permission == PermissionStatus.permanentlyDenied) {
        // Open app settings for user to manually grant permission
        await openAppSettings();
        return false;
      }

      return permission == PermissionStatus.granted;
    } catch (e) {
      debugPrint('LocationService: Error requesting location access: $e');
      return false;
    }
  }

  /// Get current position immediately (for initial setup)
  static Future<Position?> getCurrentPosition() async {
    try {
      bool hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('LocationService: Error getting current position: $e');
      return null;
    }
  }

  /// Stop the location service
  void stop() {
    _locationTimer?.cancel();
    _positionStream?.cancel();
    _locationTimer = null;
    _positionStream = null;
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('LocationService: Stopped');
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        debugPrint('LocationService: App resumed, continuing location updates');
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _isAppInForeground = false;
        debugPrint(
            'LocationService: App backgrounded, pausing location updates');
        break;
      case AppLifecycleState.hidden:
        _isAppInForeground = false;
        break;
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
