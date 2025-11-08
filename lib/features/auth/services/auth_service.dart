import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/services/supabase_service.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseService.client;
  
  User? get currentUser => _supabase.auth.currentUser;
  
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  Future<UserModel?> signUp(String email, String password, String name) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
        },
      );
      
      if (response.user != null) {
        // Store user name in user metadata
        await _supabase.auth.updateUser(
          UserAttributes(
            data: {'full_name': name},
          ),
        );
        return UserModel.fromJson(response.user!.toJson());
      }
      return null;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }
  
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        return UserModel.fromJson(response.user!.toJson());
      }
      return null;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }
  
  Future<UserModel?> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.storyhug://login-callback/',
      );
      
      // OAuth sign-in is handled differently - user will be available after redirect
      return null;
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }
  
  Future<UserModel?> signInWithApple() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.storyhug://login-callback/',
      );
      
      // OAuth sign-in is handled differently - user will be available after redirect
      return null;
    } catch (e) {
      throw Exception('Apple sign in failed: $e');
    }
  }
  
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }
  
  bool get isSignedIn => currentUser != null;
}
