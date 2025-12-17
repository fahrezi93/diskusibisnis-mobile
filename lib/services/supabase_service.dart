import 'dart:io';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase service for image uploads
/// Mirrors the website's image-upload.ts functionality
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  // Supabase configuration - same as website
  // TODO: Move these to environment config
  static const String _supabaseUrl = 'https://dgeyqbolujxynsyctoju.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRnZXlxYm9sdWp4eW5zeWN0b2p1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NTI3NzIsImV4cCI6MjA3ODUyODc3Mn0.2iQ9MC5VYO9NuadwYYTi-A4-9rexNUL_3Ww9Vr4IWYE';
  static const String _bucketName = 'question-images';

  // Allowed image types
  static const List<String> allowedTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp'
  ];

  static const int maxFileSize = 5 * 1024 * 1024; // 5MB

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  /// Initialize Supabase client
  static Future<void> initialize() async {
    if (_client != null) return;

    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
    _client = Supabase.instance.client;
    print('[Supabase] Initialized successfully');
  }

  /// Get Supabase client
  SupabaseClient get client {
    if (_client == null) {
      throw Exception(
          'Supabase not initialized. Call SupabaseService.initialize() first.');
    }
    return _client!;
  }

  /// Generate unique filename with timestamp and random string
  String _generateFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = List.generate(15,
            (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'[Random().nextInt(36)])
        .join();

    // Extract extension
    final parts = originalName.split('.');
    final extension = parts.length > 1 ? parts.last : 'jpg';

    return '$timestamp-$random.$extension';
  }

  /// Upload avatar to Supabase Storage
  /// Returns the public URL of the uploaded avatar
  Future<String> uploadAvatar(File imageFile, String userId) async {
    try {
      // Initialize if not already
      await initialize();

      // Generate unique filename
      final fileName = _generateFileName(imageFile.path.split('/').last);
      final filePath = 'avatars/$userId/$fileName';

      print('[Supabase] Uploading avatar to: $filePath');

      // Read file bytes
      final bytes = await imageFile.readAsBytes();

      // Check file size
      if (bytes.length > maxFileSize) {
        throw Exception('File terlalu besar. Maksimal 5MB.');
      }

      // Upload to Supabase Storage
      await client.storage.from(_bucketName).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true, // Overwrite if exists
            ),
          );

      // Get public URL
      final publicUrl = client.storage.from(_bucketName).getPublicUrl(filePath);

      print('[Supabase] Avatar uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('[Supabase] Upload error: $e');
      rethrow;
    }
  }

  /// Delete avatar from Supabase Storage
  Future<bool> deleteAvatar(String avatarUrl) async {
    try {
      // Initialize if not already
      await initialize();

      // Extract path from URL
      // URL format: https://xxx.supabase.co/storage/v1/object/public/bucket-name/path
      final uri = Uri.parse(avatarUrl);
      final pathSegments = uri.pathSegments;

      // Find index of bucket name and get the path after it
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        print('[Supabase] Invalid avatar URL format');
        return false;
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      print('[Supabase] Deleting avatar: $filePath');

      await client.storage.from(_bucketName).remove([filePath]);

      print('[Supabase] Avatar deleted successfully');
      return true;
    } catch (e) {
      print('[Supabase] Delete error: $e');
      return false;
    }
  }

  /// Upload question image to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String> uploadQuestionImage(File imageFile, String userId) async {
    try {
      // Initialize if not already
      await initialize();

      // Generate unique filename - same format as website
      final fileName = _generateFileName(imageFile.path.split('/').last);
      final filePath = '$userId/$fileName'; // Same as website: userId/filename

      print('[Supabase] Uploading question image to: $filePath');

      // Read file bytes
      final bytes = await imageFile.readAsBytes();

      // Check file size
      if (bytes.length > maxFileSize) {
        throw Exception('File terlalu besar. Maksimal 5MB.');
      }

      print(
          '[Supabase] File size: ${(bytes.length / 1024).toStringAsFixed(2)} KB');

      // Upload to Supabase Storage
      await client.storage.from(_bucketName).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl = client.storage.from(_bucketName).getPublicUrl(filePath);

      print('[Supabase] Question image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('[Supabase] Upload question image error: $e');
      rethrow;
    }
  }

  // Upload community icon to Supabase Storage
  Future<String> uploadCommunityIcon(File imageFile, String userId) async {
    try {
      // Initialize if not already
      await initialize();

      // Generate unique filename
      final fileName = _generateFileName(imageFile.path.split('/').last);
      final filePath = 'communities/$userId/$fileName';

      print('[Supabase] Uploading community icon to: $filePath');

      // Read file bytes
      final bytes = await imageFile.readAsBytes();

      // Check file size
      if (bytes.length > maxFileSize) {
        throw Exception('File terlalu besar. Maksimal 5MB.');
      }

      // Upload to Supabase Storage
      await client.storage.from(_bucketName).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl = client.storage.from(_bucketName).getPublicUrl(filePath);

      print('[Supabase] Community icon uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('[Supabase] Upload community icon error: $e');
      rethrow;
    }
  }
}
