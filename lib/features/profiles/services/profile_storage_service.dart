import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/child_profile.dart';
import '../../../core/services/supabase_service.dart';

class ProfileStorageService {
  static const String _profilesKey = 'child_profiles';
  static final SupabaseClient _supabase = SupabaseService.client;

  // SharedPreferences methods for offline storage
  static Future<List<ChildProfile>> getLocalProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getStringList(_profilesKey) ?? [];
      print('Loading local profiles: ${profilesJson.length} profiles found');
      
      final profiles = profilesJson.map((json) {
        final data = jsonDecode(json);
        return ChildProfile.fromJson(data);
      }).toList();
      
      print('Loaded profiles: ${profiles.map((p) => '${p.childName} (${p.avatarUrl})').join(', ')}');
      return profiles;
    } catch (e) {
      print('Error loading local profiles: $e');
      return [];
    }
  }

  static Future<void> saveLocalProfiles(List<ChildProfile> profiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = profiles.map((profile) => jsonEncode(profile.toJson())).toList();
      await prefs.setStringList(_profilesKey, profilesJson);
    } catch (e) {
      print('Error saving local profiles: $e');
    }
  }

  static Future<void> addLocalProfile(ChildProfile profile) async {
    try {
      print('Adding local profile: ${profile.childName} with avatar: ${profile.avatarUrl}');
      final profiles = await getLocalProfiles();
      profiles.add(profile);
      await saveLocalProfiles(profiles);
      print('Local profile added successfully');
    } catch (e) {
      print('Error adding local profile: $e');
    }
  }

  static Future<void> updateLocalProfile(ChildProfile profile) async {
    try {
      final profiles = await getLocalProfiles();
      final index = profiles.indexWhere((p) => p.id == profile.id);
      if (index != -1) {
        profiles[index] = profile;
        await saveLocalProfiles(profiles);
      }
    } catch (e) {
      print('Error updating local profile: $e');
    }
  }

  static Future<void> deleteLocalProfile(String profileId) async {
    try {
      final profiles = await getLocalProfiles();
      profiles.removeWhere((p) => p.id == profileId);
      await saveLocalProfiles(profiles);
    } catch (e) {
      print('Error deleting local profile: $e');
    }
  }

  // Supabase methods for cloud storage
  static Future<List<ChildProfile>> getCloudProfiles() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((data) => ChildProfile.fromJson(data)).toList();
    } catch (e) {
      print('Error loading cloud profiles: $e');
      return [];
    }
  }

  static Future<ChildProfile?> addCloudProfile(ChildProfile profile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final profileData = profile.toJson();
      profileData['user_id'] = userId;

      final response = await _supabase
          .from('profiles')
          .insert(profileData)
          .select()
          .single();

      return ChildProfile.fromJson(response);
    } catch (e) {
      print('Error adding cloud profile: $e');
      return null;
    }
  }

  static Future<ChildProfile?> updateCloudProfile(ChildProfile profile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final profileData = profile.toJson();
      profileData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('profiles')
          .update(profileData)
          .eq('id', profile.id)
          .eq('user_id', userId)
          .select()
          .single();

      return ChildProfile.fromJson(response);
    } catch (e) {
      print('Error updating cloud profile: $e');
      return null;
    }
  }

  static Future<bool> deleteCloudProfile(String profileId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('profiles')
          .delete()
          .eq('id', profileId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error deleting cloud profile: $e');
      return false;
    }
  }

  // Sync methods to keep local and cloud storage in sync
  static Future<List<ChildProfile>> syncProfiles() async {
    try {
      // Get profiles from both sources
      final localProfiles = await getLocalProfiles();
      final cloudProfiles = await getCloudProfiles();

      // If no cloud profiles, return local profiles
      if (cloudProfiles.isEmpty) {
        return localProfiles;
      }

      // If no local profiles, sync from cloud
      if (localProfiles.isEmpty) {
        await saveLocalProfiles(cloudProfiles);
        return cloudProfiles;
      }

      // Merge profiles (cloud takes precedence for conflicts)
      final Map<String, ChildProfile> profileMap = {};
      
      // Add local profiles first
      for (final profile in localProfiles) {
        profileMap[profile.id] = profile;
      }
      
      // Override with cloud profiles
      for (final profile in cloudProfiles) {
        profileMap[profile.id] = profile;
      }

      final syncedProfiles = profileMap.values.toList();
      await saveLocalProfiles(syncedProfiles);
      
      return syncedProfiles;
    } catch (e) {
      print('Error syncing profiles: $e');
      // Fallback to local profiles
      return await getLocalProfiles();
    }
  }

  // Upload avatar to Supabase Storage
  static Future<String?> uploadAvatar(String profileId, String filePath) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final fileName = 'avatar_${profileId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileExtension = filePath.split('.').last.toLowerCase();
      
      // Validate file type
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(fileExtension)) {
        throw Exception('Invalid file type. Please use JPG, PNG, or WebP.');
      }

      // Upload to Supabase Storage
      final file = File(filePath);
      final response = await _supabase.storage
          .from('avatars')
          .upload('$userId/$fileName', file);

      // Get public URL
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl('$userId/$fileName');

      return publicUrl;
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }

  // Delete avatar from Supabase Storage
  static Future<bool> deleteAvatar(String profileId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Find and delete avatar file
      final files = await _supabase.storage
          .from('avatars')
          .list(path: userId);

      for (final file in files) {
        if (file.name.contains(profileId)) {
          await _supabase.storage
              .from('avatars')
              .remove(['$userId/${file.name}']);
          break;
        }
      }

      return true;
    } catch (e) {
      print('Error deleting avatar: $e');
      return false;
    }
  }
}
