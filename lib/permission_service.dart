import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PermissionService {
  
  // ── GALLERY ─────────────────────────────────────────────
  static Future<File?> pickImageFromGallery() async {
    // Minta izin sesuai versi Android
    PermissionStatus status;
    if (Platform.isAndroid) {
      // Android 13+ gunakan READ_MEDIA_IMAGES
      status = await Permission.photos.request();
    } else {
      status = await Permission.photos.request();
    }

    if (status.isGranted) {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) return File(picked.path);
    } else if (status.isPermanentlyDenied) {
      openAppSettings(); // Arahkan ke Settings
    }
    return null;
  }

  // ── GEOLOKASI AKURAT ────────────────────────────────────
  static Future<Position?> getCurrentLocation() async {
    // 1. Cek apakah location service aktif
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location service disabled');
      return null;
    }

    // 2. Cek & minta permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) {
      openAppSettings();
      return null;
    }

    // 3. Ambil posisi dengan akurasi tinggi
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }
}