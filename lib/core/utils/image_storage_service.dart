import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Evcil hayvan ve kullanıcı fotoğraflarının yerel cihazda ve Firebase Storage'da depolanmasını yönetir.
class ImageStorageService {
  static const String _folderName = 'pawcare_pets';

  /// Fotoğrafı hem yerel cihaza kaydeder hem de Firebase Storage'a yükleyerek indirme URL'ini döner.
  static Future<String> uploadPetPhoto(
    XFile pickedFile, {
    String? userId,
    String? petId,
  }) async {
    // 1. Önce yerel diske kopyala (çevrimdışı ve hızlı önbellek için)
    final localPath = await persistPetPhoto(pickedFile);

    // 2. Firebase Storage'a yükle (Firebase bağlıysa)
    try {
      if (Firebase.apps.isNotEmpty) {
        final storage = FirebaseStorage.instance;
        final folder = userId ?? 'default';
        final fileName = '${petId ?? 'pet'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = storage.ref().child('pets/$folder/$fileName');

        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
        );

        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          await storageRef.putData(bytes, metadata);
        } else {
          await storageRef.putFile(File(localPath), metadata);
        }

        final downloadUrl = await storageRef.getDownloadURL();
        return downloadUrl;
      }
    } catch (e) {
      debugPrint('Firebase Storage upload failed, using local path: $e');
    }

    // Çevrimdışı veya hata durumunda yerel yolu kullan
    return localPath;
  }

  /// Seçilen evcil hayvan fotoğrafını yerel cihaz depolamasına kalıcı olarak kopyalar.
  static Future<String> persistPetPhoto(XFile pickedFile) async {
    if (kIsWeb) {
      return pickedFile.path;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final petDir = Directory('${appDir.path}/$_folderName');

      if (!await petDir.exists()) {
        await petDir.create(recursive: true);
      }

      final fileName =
          'dog_${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      final permanentPath = '${petDir.path}/$fileName';

      final savedFile = await File(pickedFile.path).copy(permanentPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('Error saving pet photo permanently: $e');
      return pickedFile.path;
    }
  }

  /// Dosya yolunun bir web/uzak URL (http/https) olup olmadığını kontrol eder.
  static bool isNetworkUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  /// Dosya yolunun assets kaynağı olup olmadığını belirler.
  static bool isAssetPath(String path) {
    return path.startsWith('assets/');
  }
}
