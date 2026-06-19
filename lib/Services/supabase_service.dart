import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  // AUTH

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    required String mobileNo,
  }) async {
    try {
      debugPrint('\x1B[33m[API] POST /auth/v1/signup\x1B[0m');
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'mobile_no': mobileNo,
        },
      );
      debugPrint('\x1B[32m[API] 200 OK | User: ${response.user?.email}\x1B[0m');
      return response;
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | signup | ${e.toString().replaceAll('AuthException: ', '')}\x1B[0m');
      rethrow;
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('\x1B[33m[API] POST /auth/v1/token\x1B[0m');
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('\x1B[32m[API] 200 OK | User: ${response.user?.email}\x1B[0m');
      return response;
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | signin | ${e.toString().replaceAll('AuthException: ', '')}\x1B[0m');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      debugPrint('\x1B[33m[API] POST /auth/v1/logout\x1B[0m');
      await client.auth.signOut();
      debugPrint('\x1B[32m[API] 200 OK | Signed out\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | signout | ${e.toString()}\x1B[0m');
      rethrow;
    }
  }

  static Future<void> resetPassword(String email) async {
    try {
      debugPrint('\x1B[33m[API] POST /auth/v1/recover | email: $email\x1B[0m');
      await client.auth.resetPasswordForEmail(email);
      debugPrint('\x1B[32m[API] 200 OK | Reset email sent\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | resetPassword | ${e.toString().replaceAll('AuthException: ', '')}\x1B[0m');
      rethrow;
    }
  }

  static Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    try {
      debugPrint('\x1B[33m[API] POST /auth/v1/verify | email: $email\x1B[0m');
      final response = await client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );
      debugPrint('\x1B[32m[API] 200 OK | OTP verified\x1B[0m');
      return response;
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | verifyOtp | ${e.toString().replaceAll('AuthException: ', '')}\x1B[0m');
      rethrow;
    }
  }

  static Future<void> updatePassword(String newPassword) async {
    try {
      debugPrint('\x1B[33m[API] PUT /auth/v1/user | updatePassword\x1B[0m');
      await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      debugPrint('\x1B[32m[API] 200 OK | Password updated\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | updatePassword | ${e.toString().replaceAll('AuthException: ', '')}\x1B[0m');
      rethrow;
    }
  }

  // USER SETUP

  static Future<void> saveUserSetup({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      debugPrint('\x1B[33m[API] POST /rest/v1/user_setup | userId: $userId\x1B[0m');
      await client.from('user_setup').upsert({'id': userId, ...data});
      debugPrint('\x1B[32m[API] 200 OK | Setup saved\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | saveUserSetup | ${e.toString()}\x1B[0m');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserSetup(String userId) async {
    try {
      debugPrint('\x1B[33m[API] GET /rest/v1/user_setup | userId: $userId\x1B[0m');
      final data = await client
          .from('user_setup')
          .select()
          .eq('id', userId)
          .maybeSingle();
      debugPrint('\x1B[32m[API] 200 OK | Setup: ${data != null ? 'found' : 'not found'}\x1B[0m');
      return data;
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getUserSetup | ${e.toString()}\x1B[0m');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return null;
    debugPrint('\x1B[33m[API] GET /rest/v1/users+user_setup | userId: $userId\x1B[0m');
    final profile = await client
        .from('users')
        .select('username, email')
        .eq('id', userId)
        .maybeSingle();
    final setup = await client
        .from('user_setup')
        .select('weight, age, height')
        .eq('id', userId)
        .maybeSingle();
    debugPrint('\x1B[32m[API] 200 OK | Profile fetched\x1B[0m');
    return {
      ...?profile,
      ...?setup,
    };
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getUserProfile | ${e.toString()}\x1B[0m');
    return null;
  }
}


static Future<String?> uploadAvatar(String userId, List<int> fileBytes, String fileName) async {
  try {
    debugPrint('\x1B[33m[API] POST /storage/v1/object/avatars\x1B[0m');
    final path = '$userId/$fileName';
    await client.storage.from('avatars').uploadBinary(
      path,
      Uint8List.fromList(fileBytes),
      fileOptions: const FileOptions(upsert: true),
    );
    final url = client.storage.from('avatars').getPublicUrl(path);
    debugPrint('\x1B[32m[API] 200 OK | Avatar uploaded: $url\x1B[0m');
    return url;
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | uploadAvatar | ${e.toString()}\x1B[0m');
    return null;
  }
}

static Future<void> updateUserProfile({
  required String userId,
  required Map<String, dynamic> data,
}) async {
  try {
    debugPrint('\x1B[33m[API] PATCH /rest/v1/users | userId: $userId\x1B[0m');
    await client.from('users').update(data).eq('id', userId);
    debugPrint('\x1B[32m[API] 200 OK | Profile updated\x1B[0m');
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | updateUserProfile | ${e.toString()}\x1B[0m');
    rethrow;
  }
}


}