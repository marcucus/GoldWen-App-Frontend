import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// Performance cache service for efficient data and image management
class PerformanceCacheService extends ChangeNotifier {
  static const String _cacheBoxName = 'performance_cache';
  static const String _imageBoxName = 'image_cache';
  static const String _profileBoxName = 'profile_cache';
  
  static const Duration _defaultCacheExpiry = Duration(hours: 24);
  static const Duration _imageCacheExpiry = Duration(days: 7);
  static const Duration _profileCacheExpiry = Duration(hours: 6);
  
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int _maxImageCacheEntries = 500;
  static const int _maxProfileCacheEntries = 1000;

  late Box _cacheBox;
  late Box _imageBox;
  late Box _profileBox;

  final Dio _dio = Dio();
  final Map<String, Future<Uint8List?>> _pendingImageLoads = {};
  final Map<String, Future<dynamic>> _pendingProfileLoads = {};

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _cacheBox = await Hive.openBox(_cacheBoxName);
      _imageBox = await Hive.openBox(_imageBoxName);
      _profileBox = await Hive.openBox(_profileBoxName);
      
      // Clean expired cache entries on startup
      await _cleanExpiredEntries();
      
      // Set up periodic cleanup
      _setupPeriodicCleanup();
      
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing performance cache: $e');
    }
  }

  /// Set up periodic cache cleanup
  void _setupPeriodicCleanup() {
    Timer.periodic(const Duration(hours: 6), (_) {
      _cleanExpiredEntries();
    });
  }

  /// Clean expired cache entries
  Future<void> _cleanExpiredEntries() async {
    try {
      await Future.wait([
        _cleanBox(_cacheBox, _defaultCacheExpiry),
        _cleanBox(_imageBox, _imageCacheExpiry),
        _cleanBox(_profileBox, _profileCacheExpiry),
      ]);
      
      // Enforce cache size limits
      await _enforceCacheLimits();
    } catch (e) {
      debugPrint('Error cleaning cache: $e');
    }
  }

  /// Clean expired entries from a specific box
  Future<void> _cleanBox(Box box, Duration maxAge) async {
    final now = DateTime.now();
    final keysToDelete = <String>[];
    
    for (final key in box.keys) {
      final entry = box.get(key) as Map<dynamic, dynamic>?;
      if (entry == null) {
        keysToDelete.add(key.toString());
        continue;
      }
      
      final timestampStr = entry['timestamp'] as String?;
      if (timestampStr == null) {
        keysToDelete.add(key.toString());
        continue;
      }
      
      final timestamp = DateTime.tryParse(timestampStr);
      if (timestamp == null || now.difference(timestamp) > maxAge) {
        keysToDelete.add(key.toString());
      }
    }
    
    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  /// Enforce cache size limits
  Future<void> _enforceCacheLimits() async {
    // Limit image cache entries
    if (_imageBox.keys.length > _maxImageCacheEntries) {
      final entries = _imageBox.keys
          .map((key) => MapEntry(key, _imageBox.get(key)))
          .where((entry) => entry.value != null)
          .toList();
      
      // Sort by timestamp (oldest first)
      entries.sort((a, b) {
        final aTime = DateTime.tryParse(a.value['timestamp'] ?? '') ?? DateTime(1970);
        final bTime = DateTime.tryParse(b.value['timestamp'] ?? '') ?? DateTime(1970);
        return aTime.compareTo(bTime);
      });
      
      // Remove oldest entries
      final toRemove = entries.take(entries.length - _maxImageCacheEntries);
      for (final entry in toRemove) {
        await _imageBox.delete(entry.key);
      }
    }
    
    // Limit profile cache entries
    if (_profileBox.keys.length > _maxProfileCacheEntries) {
      final entries = _profileBox.keys
          .map((key) => MapEntry(key, _profileBox.get(key)))
          .where((entry) => entry.value != null)
          .toList();
      
      entries.sort((a, b) {
        final aTime = DateTime.tryParse(a.value['timestamp'] ?? '') ?? DateTime(1970);
        final bTime = DateTime.tryParse(b.value['timestamp'] ?? '') ?? DateTime(1970);
        return aTime.compareTo(bTime);
      });
      
      final toRemove = entries.take(entries.length - _maxProfileCacheEntries);
      for (final entry in toRemove) {
        await _profileBox.delete(entry.key);
      }
    }
  }

  /// Cache generic data
  Future<void> cacheData(String key, dynamic data, {Duration? expiry}) async {
    if (!_initialized) await initialize();
    
    try {
      final entry = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'expiry': (expiry ?? _defaultCacheExpiry).inMilliseconds,
      };
      
      await _cacheBox.put(key, entry);
    } catch (e) {
      debugPrint('Error caching data for key $key: $e');
    }
  }

  /// Get cached data
  T? getCachedData<T>(String key) {
    if (!_initialized) return null;
    
    try {
      final entry = _cacheBox.get(key) as Map<dynamic, dynamic>?;
      if (entry == null) return null;
      
      final timestampStr = entry['timestamp'] as String?;
      final expiryMs = entry['expiry'] as int?;
      
      if (timestampStr == null || expiryMs == null) {
        _cacheBox.delete(key);
        return null;
      }
      
      final timestamp = DateTime.tryParse(timestampStr);
      if (timestamp == null) {
        _cacheBox.delete(key);
        return null;
      }
      
      if (DateTime.now().difference(timestamp).inMilliseconds > expiryMs) {
        _cacheBox.delete(key);
        return null;
      }
      
      return entry['data'] as T?;
    } catch (e) {
      debugPrint('Error getting cached data for key $key: $e');
      return null;
    }
  }

  /// Cache image data
  Future<void> cacheImage(String url, Uint8List imageData) async {
    if (!_initialized) await initialize();
    
    try {
      final key = _generateImageKey(url);
      final entry = {
        'data': imageData,
        'url': url,
        'timestamp': DateTime.now().toIso8601String(),
        'size': imageData.length,
      };
      
      await _imageBox.put(key, entry);
    } catch (e) {
      debugPrint('Error caching image for URL $url: $e');
    }
  }

  /// Get cached image data
  Uint8List? getCachedImage(String url) {
    if (!_initialized) return null;
    
    try {
      final key = _generateImageKey(url);
      final entry = _imageBox.get(key) as Map<dynamic, dynamic>?;
      
      if (entry == null) return null;
      
      final timestampStr = entry['timestamp'] as String?;
      if (timestampStr == null) {
        _imageBox.delete(key);
        return null;
      }
      
      final timestamp = DateTime.tryParse(timestampStr);
      if (timestamp == null || 
          DateTime.now().difference(timestamp) > _imageCacheExpiry) {
        _imageBox.delete(key);
        return null;
      }
      
      return entry['data'] as Uint8List?;
    } catch (e) {
      debugPrint('Error getting cached image for URL $url: $e');
      return null;
    }
  }

  /// Load image with caching and deduplication
  Future<Uint8List?> loadImageWithCache(String url, {
    Map<String, String>? headers,
    Function(int, int)? onProgress,
  }) async {
    if (!_initialized) await initialize();
    
    // Check cache first
    final cached = getCachedImage(url);
    if (cached != null) {
      return cached;
    }
    
    // Check if already loading
    if (_pendingImageLoads.containsKey(url)) {
      return await _pendingImageLoads[url]!;
    }
    
    // Start loading
    final future = _loadImageFromNetwork(url, headers: headers, onProgress: onProgress);
    _pendingImageLoads[url] = future;
    
    try {
      final result = await future;
      if (result != null) {
        await cacheImage(url, result);
      }
      return result;
    } finally {
      _pendingImageLoads.remove(url);
    }
  }

  /// Load image from network
  Future<Uint8List?> _loadImageFromNetwork(String url, {
    Map<String, String>? headers,
    Function(int, int)? onProgress,
  }) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: headers,
        ),
        onReceiveProgress: onProgress,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data);
      }
    } catch (e) {
      debugPrint('Error loading image from network: $e');
    }
    return null;
  }

  /// Cache profile data
  Future<void> cacheProfile(String profileId, Map<String, dynamic> profileData) async {
    if (!_initialized) await initialize();
    
    try {
      final entry = {
        'data': profileData,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _profileBox.put(profileId, entry);
    } catch (e) {
      debugPrint('Error caching profile $profileId: $e');
    }
  }

  /// Get cached profile data
  Map<String, dynamic>? getCachedProfile(String profileId) {
    if (!_initialized) return null;
    
    try {
      final entry = _profileBox.get(profileId) as Map<dynamic, dynamic>?;
      if (entry == null) return null;
      
      final timestampStr = entry['timestamp'] as String?;
      if (timestampStr == null) {
        _profileBox.delete(profileId);
        return null;
      }
      
      final timestamp = DateTime.tryParse(timestampStr);
      if (timestamp == null || 
          DateTime.now().difference(timestamp) > _profileCacheExpiry) {
        _profileBox.delete(profileId);
        return null;
      }
      
      return Map<String, dynamic>.from(entry['data'] as Map);
    } catch (e) {
      debugPrint('Error getting cached profile $profileId: $e');
      return null;
    }
  }

  /// Preload profiles in background
  Future<void> preloadProfiles(List<String> profileIds, {
    required Future<Map<String, dynamic>?> Function(String) loadFunction,
  }) async {
    if (!_initialized) await initialize();
    
    // Load profiles that aren't cached
    final uncachedIds = profileIds
        .where((id) => getCachedProfile(id) == null && !_pendingProfileLoads.containsKey(id))
        .toList();
    
    for (final profileId in uncachedIds) {
      final future = loadFunction(profileId);
      _pendingProfileLoads[profileId] = future;
      
      // Cache the result when it completes
      future.then((profileData) {
        if (profileData != null) {
          cacheProfile(profileId, profileData);
        }
      }).catchError((error) {
        debugPrint('Error preloading profile $profileId: $error');
      }).whenComplete(() {
        _pendingProfileLoads.remove(profileId);
      });
    }
  }

  /// Generate cache key for images
  String _generateImageKey(String url) {
    return sha256.convert(url.codeUnits).toString();
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    if (!_initialized) await initialize();
    
    try {
      await Future.wait([
        _cacheBox.clear(),
        _imageBox.clear(),
        _profileBox.clear(),
      ]);
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing caches: $e');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    if (!_initialized) return {};
    
    try {
      int imageCacheSize = 0;
      for (final entry in _imageBox.values) {
        if (entry is Map && entry.containsKey('size')) {
          imageCacheSize += entry['size'] as int;
        }
      }
      
      return {
        'initialized': _initialized,
        'cacheEntries': _cacheBox.keys.length,
        'imageEntries': _imageBox.keys.length,
        'profileEntries': _profileBox.keys.length,
        'imageCacheSize': imageCacheSize,
        'pendingImageLoads': _pendingImageLoads.length,
        'pendingProfileLoads': _pendingProfileLoads.length,
      };
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Dispose of resources
  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }
}