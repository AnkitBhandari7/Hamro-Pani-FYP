import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Handles all Firebase Storage operations for profile images.
/// Images are stored at: profile_images/{userId}/profile.jpg
/// This replaces the previous Render-local-disk approach which caused 404s
/// after server restarts (ephemeral storage).
class FirebaseStorageService {
  static FirebaseStorage get _storage => FirebaseStorage.instance;

  static Reference _profileRef(String userId) =>
      _storage.ref().child('profile_images').child(userId).child('profile.jpg');

  /// Upload [imageFile] for [userId] and return the HTTPS download URL.
  static Future<String> uploadProfileImage(
    String userId,
    File imageFile,
  ) async {
    final ref = _profileRef(userId);

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'uploadedBy': userId},
    );

    final task = await ref.putFile(imageFile, metadata);
    final url = await task.ref.getDownloadURL();

    debugPrint('[FirebaseStorage] Uploaded profile image for $userId → $url');
    return url;
  }

  /// Delete the stored profile image for [userId].
  /// Silently ignores errors if the file does not exist.
  static Future<void> deleteProfileImage(String userId) async {
    try {
      await _profileRef(userId).delete();
      debugPrint('[FirebaseStorage] Deleted profile image for $userId');
    } on FirebaseException catch (e) {
      // object-not-found is fine – nothing to delete
      if (e.code != 'object-not-found') {
        debugPrint('[FirebaseStorage] Delete error for $userId: ${e.message}');
      }
    }
  }

  /// Returns the current HTTPS download URL for [userId]'s profile image,
  /// or null if no image has been uploaded.
  static Future<String?> getProfileImageUrl(String userId) async {
    try {
      return await _profileRef(userId).getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return null;
      debugPrint('[FirebaseStorage] getDownloadURL error: ${e.message}');
      return null;
    }
  }
}
