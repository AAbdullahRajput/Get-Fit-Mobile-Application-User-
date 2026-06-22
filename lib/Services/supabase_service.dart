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
        .select('username, email, mobile_no, avatar_url, terms_accepted')
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
    // Add cache buster so Flutter reloads the image
    final cacheBustedUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('\x1B[32m[API] 200 OK | Avatar uploaded: $cacheBustedUrl\x1B[0m');
    return cacheBustedUrl;
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


// FAVORITES

static Future<List<Map<String, dynamic>>> getFavorites() async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return [];
    debugPrint('\x1B[33m[API] GET /rest/v1/favorites | userId: $userId\x1B[0m');
    final data = await client
        .from('favorites')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    debugPrint('\x1B[32m[API] 200 OK | Favorites: ${data.length}\x1B[0m');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getFavorites | ${e.toString()}\x1B[0m');
    return [];
  }
}

static Future<bool> isFavorite(String exerciseId) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return false;
    debugPrint('\x1B[33m[FAV] isFavorite check: $exerciseId\x1B[0m');
    final data = await client
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('exercise_id', exerciseId)
        .maybeSingle();
    debugPrint('\x1B[33m[FAV] isFavorite result: $data\x1B[0m');
    return data != null;
  } catch (e, stack) {
    debugPrint('\x1B[31m[FAV] isFavorite ERROR: $e\x1B[0m');
    debugPrint('\x1B[31m[FAV] stack: $stack\x1B[0m');
    return false;
  }
}

static Future<void> toggleFavorite({
  required String exerciseId,
  required String title,
  required String image,
  required String category,
  required String level,
  required String sets,
  required String reps,
  required String rest,
  required String description,
}) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return;
    debugPrint('\x1B[33m[FAV] toggleFavorite called: $exerciseId\x1B[0m');
    
    final existing = await client
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('exercise_id', exerciseId)
        .maybeSingle();
    
    debugPrint('\x1B[33m[FAV] existing: $existing\x1B[0m');
    
    if (existing != null) {
      await client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('exercise_id', exerciseId);
      debugPrint('\x1B[32m[FAV] Removed favorite: $exerciseId\x1B[0m');
    } else {
      debugPrint('\x1B[33m[FAV] inserting: id=$exerciseId title=$title\x1B[0m');
      await client.from('favorites').insert(<String, dynamic>{
        'user_id': userId,
        'exercise_id': exerciseId,
        'exercise_title': title,
        'exercise_image': image,
        'exercise_category': category,
        'exercise_level': level,
        'exercise_sets': sets,
        'exercise_reps': reps,
        'exercise_rest': rest,
        'exercise_description': description,
      });
      debugPrint('\x1B[32m[FAV] Added favorite: $exerciseId\x1B[0m');
    }
  } catch (e, stack) {
    debugPrint('\x1B[31m[FAV] toggleFavorite ERROR: $e\x1B[0m');
    debugPrint('\x1B[31m[FAV] stack: $stack\x1B[0m');
    rethrow;
  }
}

static Future<void> acceptTerms() async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return;
    await client.from('users').update({'terms_accepted': true}).eq('id', userId);
    debugPrint('\x1B[32m[API] Terms accepted\x1B[0m');
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | acceptTerms | $e\x1B[0m');
  }
}

static Future<void> deleteAccountNoPassword() async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return;
    debugPrint('\x1B[33m[API] DELETE account (no password) | userId: $userId\x1B[0m');

    // Delete avatar from storage
    try {
      await client.storage.from('avatars').remove(['$userId/avatar.jpg']);
      debugPrint('\x1B[32m[API] Avatar deleted\x1B[0m');
    } catch (_) {
      debugPrint('\x1B[33m[API] No avatar found\x1B[0m');
    }

    // Call secure DB function
    await client.rpc('delete_user_account');

    // Sign out locally
    await client.auth.signOut();
    debugPrint('\x1B[32m[API] Account deleted\x1B[0m');
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | deleteAccountNoPassword | $e\x1B[0m');
    rethrow;
  }
}

// TRAINERS

static Future<List<Map<String, dynamic>>> getTrainers() async {
  try {
    debugPrint('\x1B[33m[API] GET /rest/v1/fitness_trainers\x1B[0m');
    final data = await client
        .from('fitness_trainers')
        .select()
        .order('created_at', ascending: true);
    debugPrint('\x1B[32m[API] 200 OK | Trainers: ${data.length}\x1B[0m');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getTrainers | $e\x1B[0m');
    return [];
  }
}

static Future<List<Map<String, dynamic>>> getTrainerReviews(String trainerId) async {
  try {
    debugPrint('\x1B[33m[API] GET /rest/v1/trainer_reviews | trainerId: $trainerId\x1B[0m');
    final data = await client
        .from('trainer_reviews')
        .select()
        .eq('trainer_id', trainerId)
        .order('created_at', ascending: false);
    debugPrint('\x1B[32m[API] 200 OK | Reviews: ${data.length}\x1B[0m');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getTrainerReviews | $e\x1B[0m');
    return [];
  }
}

static Future<Map<String, dynamic>?> getMyReview(String trainerId) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return null;
    final data = await client
        .from('trainer_reviews')
        .select()
        .eq('trainer_id', trainerId)
        .eq('user_id', userId)
        .maybeSingle();
    return data;
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getMyReview | $e\x1B[0m');
    return null;
  }
}

static Future<void> submitReview({
  required String trainerId,
  required double rating,
  required String reviewText,
}) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return;
    final profile = await getUserProfile();
    debugPrint('\x1B[33m[API] POST /rest/v1/trainer_reviews\x1B[0m');
    await client.from('trainer_reviews').upsert({
      'trainer_id': trainerId,
      'user_id': userId,
      'username': profile?['username'] ?? 'User',
      'avatar_url': profile?['avatar_url'] ?? '',
      'rating': rating,
      'review_text': reviewText,
    }, onConflict: 'trainer_id,user_id');
    // Update trainer average rating
    final reviews = await getTrainerReviews(trainerId);
    if (reviews.isNotEmpty) {
      final avg = reviews.map((r) => (r['rating'] as num).toDouble()).reduce((a, b) => a + b) / reviews.length;
      await client.from('fitness_trainers').update({'rating': double.parse(avg.toStringAsFixed(1))}).eq('id', trainerId);
    }
    debugPrint('\x1B[32m[API] 200 OK | Review submitted\x1B[0m');
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | submitReview | $e\x1B[0m');
    rethrow;
  }
}

static Future<void> bookAppointment({
  required String trainerId,
  required String date,
  required String time,
  String notes = '',
}) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return;
    debugPrint('\x1B[33m[API] POST /rest/v1/trainer_appointments\x1B[0m');
    await client.from('trainer_appointments').insert({
      'trainer_id': trainerId,
      'user_id': userId,
      'appointment_date': date,
      'appointment_time': time,
      'notes': notes,
      'status': 'pending',
    });
    debugPrint('\x1B[32m[API] 200 OK | Appointment booked\x1B[0m');
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | bookAppointment | $e\x1B[0m');
    rethrow;
  }
}

static Future<List<Map<String, dynamic>>> getMyAppointments() async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return [];
    debugPrint('\x1B[33m[API] GET /rest/v1/trainer_appointments\x1B[0m');
    final data = await client
        .from('trainer_appointments')
        .select('*, fitness_trainers(name, image_url, training_type)')
        .eq('user_id', userId)
        .order('appointment_date', ascending: true);
    debugPrint('\x1B[32m[API] 200 OK | Appointments: ${data.length}\x1B[0m');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getMyAppointments | $e\x1B[0m');
    return [];
  }
}

static Future<List<String>> getBookedSlots({
  required String trainerId,
  required String date,
}) async {
  try {
    final data = await client.rpc('get_booked_slots', params: {
      'p_trainer_id': trainerId,
      'p_date': date,
    });
    return List<String>.from(data.map((r) => r['appointment_time']));
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getBookedSlots | $e\x1B[0m');
    return [];
  }
}

static Future<void> deleteReview({required String trainerId}) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return;
    debugPrint('\x1B[33m[API] DELETE /rest/v1/trainer_reviews | trainerId: $trainerId\x1B[0m');
    await client
        .from('trainer_reviews')
        .delete()
        .eq('trainer_id', trainerId)
        .eq('user_id', userId);
    // Recalculate avg
    final reviews = await getTrainerReviews(trainerId);
    if (reviews.isEmpty) {
      await client.from('fitness_trainers').update({'rating': 0.0}).eq('id', trainerId);
    } else {
      final avg = reviews.map((r) => (r['rating'] as num).toDouble()).reduce((a, b) => a + b) / reviews.length;
      await client.from('fitness_trainers').update({'rating': double.parse(avg.toStringAsFixed(1))}).eq('id', trainerId);
    }
    debugPrint('\x1B[32m[API] 200 OK | Review deleted\x1B[0m');
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | deleteReview | $e\x1B[0m');
    rethrow;
  }
}
}