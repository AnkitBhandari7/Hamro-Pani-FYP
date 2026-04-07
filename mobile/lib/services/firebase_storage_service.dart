import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Handles all profile image operations via Firebase Storage.
/// Images are stored at: profiles/user_{userId}.jpg
/// All returned URLs are guaranteed HTTPS (Firebase default).
class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload profile image, returns the HTTPS download URL.
  /// Replaces any existing image for the same user.
  static Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      final safeExt = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
      final ref = _storage.ref('profiles/user_$userId.$safeExt');

      final metadata = SettableMetadata(
        contentType: 'image/$safeExt',
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putFile(imageFile, metadata);
      final snapshot = await uploadTask;

      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('FirebaseStorage: uploaded → $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('FirebaseStorage upload error: $e');
      rethrow;
    }
  }

  /// Silently deletes a profile image from Firebase Storage.
  /// Ignores errors (e.g. file already deleted).
  static Future<void> deleteProfileImage(String userId) async {
    // Try both common extensions
    for (final ext in ['jpg', 'png', 'jpeg', 'webp']) {
      try {
        await _storage.ref('profiles/user_$userId.$ext').delete();
        debugPrint('FirebaseStorage: deleted profiles/user_$userId.$ext');
        return; // Stop at first successful delete
      } catch (_) {
        // Ignore — file with this ext probably doesn't exist
      }
    }
  }

  /// Gets current Firebase user's ID token for backend auth.
  static Future<String?> getIdToken() async {
    return await FirebaseAuth.instance.currentUser?.getIdToken(true);
  }
}
