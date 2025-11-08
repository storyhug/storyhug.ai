import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/child_profile.dart';
import '../../../core/services/supabase_service.dart';

class ProfileService {
  final SupabaseClient _supabase = SupabaseService.client;

  Future<List<ChildProfile>> getChildProfiles(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ChildProfile.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch profiles: $e');
    }
  }

  Future<ChildProfile> createChildProfile({
    required String userId,
    required String childName,
    required int ageBucket,
    String? nickname,
    String? avatarUrl,
  }) async {
    try {
      final response = await _supabase
          .from('profiles')
          .insert({
            'user_id': userId,
            'child_name': childName,
            'age_bucket': ageBucket,
            'nickname': nickname,
            'avatar_url': avatarUrl,
          })
          .select()
          .single();

      return ChildProfile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create profile: $e');
    }
  }

  Future<void> updateChildProfile(ChildProfile profile) async {
    try {
      await _supabase
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> deleteChildProfile(String profileId) async {
    try {
      await _supabase
          .from('profiles')
          .delete()
          .eq('id', profileId);
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }

  Future<ChildProfile?> getChildProfileById(String profileId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', profileId)
          .single();

      return ChildProfile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  // Sample data for development/testing
  static List<ChildProfile> getSampleProfiles() {
    return [
      ChildProfile(
        id: '1',
        userId: 'sample-user-1',
        childName: 'Emma',
        ageBucket: 5,
        nickname: 'Emmy',
        avatarUrl: 'https://via.placeholder.com/100x100/7B3FE4/FFFFFF?text=E',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ChildProfile(
        id: '2',
        userId: 'sample-user-1',
        childName: 'Liam',
        ageBucket: 7,
        nickname: 'Li',
        avatarUrl: 'https://via.placeholder.com/100x100/FFD700/000000?text=L',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}
