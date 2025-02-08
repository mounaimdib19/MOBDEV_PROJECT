// cache_manager.dart
import 'package:flutter/material.dart';

class CacheManager {
  static void clearCache(BuildContext context) {
    try {
      debugPrint('🔵 Starting cache clear');
      
      debugPrint('🔵 Clearing image cache');
      imageCache.clear();
      imageCache.clearLiveImages();
      
      debugPrint('🔵 Clearing painting binding cache');
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      debugPrint('🔵 Cache cleared successfully');
    } catch (e) {
      debugPrint('🔴 Error clearing cache: $e');
      throw Exception('Failed to clear cache: $e');
    }
  }
}