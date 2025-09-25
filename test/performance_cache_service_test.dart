import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/services/performance_cache_service.dart';

void main() {
  group('PerformanceCacheService', () {
    late PerformanceCacheService service;

    setUp(() {
      service = PerformanceCacheService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should initialize correctly', () {
      expect(service.isInitialized, false);
    });

    test('should cache and retrieve data correctly', () async {
      await service.initialize();
      
      const key = 'test_key';
      const data = {'name': 'John', 'age': 30};
      
      await service.cacheData(key, data);
      final retrievedData = service.getCachedData<Map<String, dynamic>>(key);
      
      expect(retrievedData, data);
    });

    test('should handle cached data expiry', () async {
      await service.initialize();
      
      const key = 'test_key';
      const data = {'name': 'John', 'age': 30};
      const shortExpiry = Duration(milliseconds: 100);
      
      await service.cacheData(key, data, expiry: shortExpiry);
      
      // Should be available immediately
      expect(service.getCachedData<Map<String, dynamic>>(key), data);
      
      // Wait for expiry
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Should be null after expiry
      expect(service.getCachedData<Map<String, dynamic>>(key), null);
    });

    test('should cache and retrieve image data correctly', () async {
      await service.initialize();
      
      const url = 'https://example.com/image.jpg';
      final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      await service.cacheImage(url, imageData);
      final retrievedData = service.getCachedImage(url);
      
      expect(retrievedData, imageData);
    });

    test('should cache and retrieve profile data correctly', () async {
      await service.initialize();
      
      const profileId = 'user123';
      const profileData = {
        'id': 'user123',
        'name': 'John Doe',
        'age': 30,
        'bio': 'Software developer',
      };
      
      await service.cacheProfile(profileId, profileData);
      final retrievedData = service.getCachedProfile(profileId);
      
      expect(retrievedData, profileData);
    });

    test('should return null for non-existent cached data', () async {
      await service.initialize();
      
      final data = service.getCachedData<String>('non_existent_key');
      expect(data, null);
      
      final image = service.getCachedImage('non_existent_url');
      expect(image, null);
      
      final profile = service.getCachedProfile('non_existent_id');
      expect(profile, null);
    });

    test('should clear all caches', () async {
      await service.initialize();
      
      // Add some test data
      await service.cacheData('key1', 'data1');
      await service.cacheImage('url1', Uint8List.fromList([1, 2, 3]));
      await service.cacheProfile('profile1', {'id': 'profile1'});
      
      // Verify data exists
      expect(service.getCachedData('key1'), 'data1');
      expect(service.getCachedImage('url1'), isNotNull);
      expect(service.getCachedProfile('profile1'), isNotNull);
      
      // Clear all caches
      await service.clearAllCaches();
      
      // Verify data is gone
      expect(service.getCachedData('key1'), null);
      expect(service.getCachedImage('url1'), null);
      expect(service.getCachedProfile('profile1'), null);
    });

    test('should provide cache statistics', () async {
      await service.initialize();
      
      // Add some test data
      await service.cacheData('key1', 'data1');
      await service.cacheImage('url1', Uint8List.fromList([1, 2, 3, 4, 5]));
      await service.cacheProfile('profile1', {'id': 'profile1'});
      
      final stats = service.getCacheStats();
      
      expect(stats['initialized'], true);
      expect(stats['cacheEntries'], greaterThanOrEqualTo(1));
      expect(stats['imageEntries'], greaterThanOrEqualTo(1));
      expect(stats['profileEntries'], greaterThanOrEqualTo(1));
      expect(stats['imageCacheSize'], greaterThanOrEqualTo(5));
      expect(stats['pendingImageLoads'], 0);
      expect(stats['pendingProfileLoads'], 0);
    });

    test('should handle preloading profiles', () async {
      await service.initialize();
      
      final profileIds = ['profile1', 'profile2', 'profile3'];
      
      Future<Map<String, dynamic>?> mockLoadFunction(String id) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return {'id': id, 'name': 'User $id'};
      }
      
      await service.preloadProfiles(profileIds, loadFunction: mockLoadFunction);
      
      // Wait a bit for the loading to complete
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Check if profiles were cached
      final profile1 = service.getCachedProfile('profile1');
      expect(profile1, isNotNull);
      expect(profile1?['id'], 'profile1');
    });

    test('should not reload already cached profiles during preloading', () async {
      await service.initialize();
      
      // Pre-cache a profile
      await service.cacheProfile('profile1', {'id': 'profile1', 'cached': true});
      
      final profileIds = ['profile1', 'profile2'];
      int loadCallCount = 0;
      
      Future<Map<String, dynamic>?> mockLoadFunction(String id) async {
        loadCallCount++;
        return {'id': id, 'loaded': true};
      }
      
      await service.preloadProfiles(profileIds, loadFunction: mockLoadFunction);
      
      // Wait for loading
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Should only load profile2 since profile1 is already cached
      expect(loadCallCount, 1);
      
      final profile1 = service.getCachedProfile('profile1');
      expect(profile1?['cached'], true); // Original cached version
      
      final profile2 = service.getCachedProfile('profile2');
      expect(profile2?['loaded'], true); // Newly loaded version
    });

    test('should generate consistent cache keys for images', () async {
      await service.initialize();
      
      const url1 = 'https://example.com/image1.jpg';
      const url2 = 'https://example.com/image1.jpg'; // Same URL
      const url3 = 'https://example.com/image2.jpg'; // Different URL
      
      final data1 = Uint8List.fromList([1, 2, 3]);
      final data2 = Uint8List.fromList([4, 5, 6]);
      
      // Cache with first URL
      await service.cacheImage(url1, data1);
      
      // Retrieve with same URL (should get same data)
      expect(service.getCachedImage(url2), data1);
      
      // Cache with different URL
      await service.cacheImage(url3, data2);
      expect(service.getCachedImage(url3), data2);
      
      // Original should still be there
      expect(service.getCachedImage(url1), data1);
    });
  });
}