import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'profile_storage_service.dart';

class AvatarUploadService {
  static final ImagePicker _picker = ImagePicker();

  // Request camera permission
  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting camera permission: $e');
      return false;
    }
  }

  // Request storage permission
  static Future<bool> requestStoragePermission() async {
    try {
      // For Android 13+ (API 33+), use photos permission
      if (Platform.isAndroid) {
        final photosStatus = await Permission.photos.request();
        if (photosStatus == PermissionStatus.granted) {
          return true;
        }
      }
      
      // Fallback to storage permission for older Android versions
      final status = await Permission.storage.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting storage permission: $e');
      return false;
    }
  }

  // Pick image from camera
  static Future<File?> pickImageFromCamera() async {
    try {
      print('Requesting camera permission...');
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        print('Camera permission denied');
        throw Exception('Camera permission denied');
      }
      print('Camera permission granted');

      print('Opening camera...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        print('Image selected from camera: ${image.path}');
        return File(image.path);
      }
      print('No image selected from camera');
      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  // Pick image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      print('Requesting storage permission...');
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        print('Storage permission denied');
        throw Exception('Storage permission denied');
      }
      print('Storage permission granted');

      print('Opening gallery...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        print('Image selected from gallery: ${image.path}');
        return File(image.path);
      }
      print('No image selected from gallery');
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  // Show image source selection dialog
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    try {
      print('Showing image source dialog...');
      return await showModalBottomSheet<File?>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Avatar Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    context: context,
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () async {
                      try {
                        print('Camera option tapped');
                        final file = await pickImageFromCamera();
                        print('Camera result: $file');
                        if (context.mounted) {
                          Navigator.pop(context, file);
                        }
                      } catch (e) {
                        print('Camera error: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Camera error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          Navigator.pop(context, null);
                        }
                      }
                    },
                  ),
                  _buildSourceOption(
                    context: context,
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () async {
                      try {
                        print('Gallery option tapped');
                        final file = await pickImageFromGallery();
                        print('Gallery result: $file');
                        if (context.mounted) {
                          Navigator.pop(context, file);
                        }
                      } catch (e) {
                        print('Gallery error: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gallery error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          Navigator.pop(context, null);
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error showing image source dialog: $e');
      return null;
    }
  }

  static Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Upload avatar to cloud storage
  static Future<String?> uploadAvatar(String profileId, File imageFile) async {
    try {
      return await ProfileStorageService.uploadAvatar(profileId, imageFile.path);
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }

  // Delete avatar from cloud storage
  static Future<bool> deleteAvatar(String profileId) async {
    try {
      return await ProfileStorageService.deleteAvatar(profileId);
    } catch (e) {
      print('Error deleting avatar: $e');
      return false;
    }
  }

  // Save avatar locally
  static Future<String?> saveAvatarLocally(File imageFile, String profileId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${directory.path}/avatars');
      
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      final fileName = 'avatar_$profileId.jpg';
      final localPath = '${avatarDir.path}/$fileName';
      
      await imageFile.copy(localPath);
      return localPath;
    } catch (e) {
      print('Error saving avatar locally: $e');
      return null;
    }
  }

  // Get local avatar path
  static Future<String?> getLocalAvatarPath(String profileId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final avatarPath = '${directory.path}/avatars/avatar_$profileId.jpg';
      final file = File(avatarPath);
      
      if (await file.exists()) {
        return avatarPath;
      }
      return null;
    } catch (e) {
      print('Error getting local avatar path: $e');
      return null;
    }
  }

  // Delete local avatar
  static Future<bool> deleteLocalAvatar(String profileId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final avatarPath = '${directory.path}/avatars/avatar_$profileId.jpg';
      final file = File(avatarPath);
      
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting local avatar: $e');
      return false;
    }
  }

  // Compress image
  static Future<File?> compressImage(File imageFile) async {
    try {
      // For now, return the original file
      // In a real app, you might want to use a package like flutter_image_compress
      return imageFile;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  // Validate image file
  static bool isValidImageFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp'].contains(extension);
  }

  // Get image file size in MB
  static Future<double> getImageSizeInMB(File file) async {
    try {
      final bytes = await file.length();
      return bytes / (1024 * 1024);
    } catch (e) {
      print('Error getting image size: $e');
      return 0.0;
    }
  }

  // Check if image size is within limits
  static Future<bool> isImageSizeValid(File file, {double maxSizeMB = 5.0}) async {
    final sizeInMB = await getImageSizeInMB(file);
    return sizeInMB <= maxSizeMB;
  }
}
