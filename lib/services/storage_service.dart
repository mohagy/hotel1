/// Firebase Storage Service
/// 
/// Handles file uploads to Firebase Storage

import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload image file
  Future<String> uploadImage({
    required File imageFile,
    required String path,
    String? fileName,
  }) async {
    try {
      final fileName = fileName ?? DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage.ref().child('$path/$fileName.jpg');
      
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload guest photo
  Future<String> uploadGuestPhoto(File imageFile, int guestId) async {
    return await uploadImage(
      imageFile: imageFile,
      path: 'guests/photos',
      fileName: 'guest_$guestId',
    );
  }

  /// Upload room image
  Future<String> uploadRoomImage(File imageFile, int roomId) async {
    return await uploadImage(
      imageFile: imageFile,
      path: 'rooms/images',
      fileName: 'room_$roomId',
    );
  }

  /// Upload document
  Future<String> uploadDocument({
    required File file,
    required String path,
    String? fileName,
  }) async {
    try {
      final fileName = fileName ?? DateTime.now().millisecondsSinceEpoch.toString();
      final extension = file.path.split('.').last;
      final ref = _storage.ref().child('$path/$fileName.$extension');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Delete file
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Get download URL
  Future<String> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }
}

