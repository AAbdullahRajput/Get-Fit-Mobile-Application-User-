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
      if (data.containsKey('avatar_url')) {
        await client
            .from('trainer_reviews')
            .update({'avatar_url': data['avatar_url']})
            .eq('user_id', userId);
      }
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
      final data = await client
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('exercise_id', exerciseId)
          .maybeSingle();
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
      final existing = await client
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('exercise_id', exerciseId)
          .maybeSingle();
      if (existing != null) {
        await client
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('exercise_id', exerciseId);
        debugPrint('\x1B[32m[FAV] Removed favorite: $exerciseId\x1B[0m');
      } else {
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
      try {
        await client.storage.from('avatars').remove(['$userId/avatar.jpg']);
        debugPrint('\x1B[32m[API] Avatar deleted\x1B[0m');
      } catch (_) {
        debugPrint('\x1B[33m[API] No avatar found\x1B[0m');
      }
      await client.rpc('delete_user_account');
      await client.auth.signOut();
      debugPrint('\x1B[32m[API] Account deleted\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | deleteAccountNoPassword | $e\x1B[0m');
      rethrow;
    }
  }

  // GYM EXERCISES

  static Future<List<Map<String, dynamic>>> getGymExercises({String? category, int page = 0, int pageSize = 7}) async {
    try {
      debugPrint('\x1B[33m[API] GET /rest/v1/gym_exercises | category: $category | page: $page\x1B[0m');
      var query = client.from('gym_exercises').select();
      if (category != null && category != 'All') {
        query = query.eq('category', category);
      }
      final data = await query
          .order('created_at', ascending: true)
          .range(page * pageSize, (page + 1) * pageSize - 1);
      debugPrint('\x1B[32m[API] 200 OK | Exercises: ${data.length}\x1B[0m');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getGymExercises | $e\x1B[0m');
      return [];
    }
  }

  // TRAINERS

  static Future<List<Map<String, dynamic>>> getTrainers({int page = 0, int pageSize = 9}) async {
    try {
      debugPrint('\x1B[33m[API] GET /rest/v1/fitness_trainers | page: $page\x1B[0m');
      final data = await client
          .from('fitness_trainers')
          .select()
          .order('rating', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);
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
          .select('*, fitness_trainers(id, name, image_url, training_type)')
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
      debugPrint('\x1B[32m[API] 200 OK | Review deleted\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | deleteReview | $e\x1B[0m');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getTrainerSlots(String trainerId) async {
    try {
      final res = await client
          .from('trainer_slots')
          .select('slot_time, price')
          .eq('trainer_id', trainerId)
          .order('created_at');
      debugPrint('\x1B[32m[API] 200 OK | getTrainerSlots | ${res.length} slots\x1B[0m');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getTrainerSlots | $e\x1B[0m');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getUserCards() async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return [];
      final res = await client
          .from('user_cards')
          .select()
          .eq('user_id', userId)
          .order('created_at');
      debugPrint('\x1B[32m[API] 200 OK | getUserCards | ${res.length} cards\x1B[0m');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getUserCards | $e\x1B[0m');
      return [];
    }
  }

  static Future<void> addUserCard({
    required String holderName,
    required String last4,
    required String expiry,
    required String cardNetwork,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');
    await client.from('user_cards').insert({
      'user_id': userId,
      'holder_name': holderName,
      'last4': last4,
      'expiry': expiry,
      'card_network': cardNetwork,
    });
  }

  static Future<void> deleteUserCard(String cardId) async {
    await client.from('user_cards').delete().eq('id', cardId);
  }

  static Future<void> updateUserCard({
    required String cardId,
    required String holderName,
    required String expiry,
  }) async {
    await client.from('user_cards').update({
      'holder_name': holderName,
      'expiry': expiry,
    }).eq('id', cardId);
  }

  static Future<Map<String, dynamic>?> getNextAppointment() async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return null;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final res = await client
          .from('trainer_appointments')
          .select('*, fitness_trainers(id, name, training_type, image_url)')

          .eq('user_id', userId)
          .gte('appointment_date', today)
          .order('appointment_date')
          .order('appointment_time')
          .limit(1)
          .maybeSingle();
      return res;
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getNextAppointment | $e\x1B[0m');
      return null;
    }
  }

  // YOGA INSTRUCTORS

  static Future<List<Map<String, dynamic>>> getYogaInstructors({int page = 0, int pageSize = 10}) async {
    try {
      debugPrint('\x1B[33m[API] GET /rest/v1/yoga_instructors | page: $page\x1B[0m');
      final data = await client
          .from('yoga_instructors')
          .select()
          .order('rating', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);
      debugPrint('\x1B[32m[API] 200 OK | YogaInstructors: ${data.length}\x1B[0m');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getYogaInstructors | $e\x1B[0m');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getYogaInstructorReviews(String instructorId) async {
    try {
      debugPrint('\x1B[33m[API] GET /rest/v1/yoga_instructor_reviews | instructorId: $instructorId\x1B[0m');
      final data = await client
          .from('yoga_instructor_reviews')
          .select()
          .eq('instructor_id', instructorId)
          .order('created_at', ascending: false);
      debugPrint('\x1B[32m[API] 200 OK | YogaReviews: ${data.length}\x1B[0m');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getYogaInstructorReviews | $e\x1B[0m');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getMyYogaReview(String instructorId) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;
      final data = await client
          .from('yoga_instructor_reviews')
          .select()
          .eq('instructor_id', instructorId)
          .eq('user_id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getMyYogaReview | $e\x1B[0m');
      return null;
    }
  }

  static Future<void> submitYogaReview({
  required String instructorId,
  required double rating,
  required String reviewText,
}) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return;
    final profile = await getUserProfile();
    debugPrint('\x1B[33m[API] POST /rest/v1/yoga_instructor_reviews\x1B[0m');
    await client.from('yoga_instructor_reviews').upsert({
      'instructor_id': instructorId,
      'user_id': userId,
      'username': profile?['username'] ?? 'User',
      'avatar_url': profile?['avatar_url'] ?? '',
      'rating': rating,
      'review_text': reviewText,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'instructor_id,user_id');
    debugPrint('\x1B[32m[API] 200 OK | Yoga review submitted\x1B[0m');
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | submitYogaReview | $e\x1B[0m');
    rethrow;
  }
}

  static Future<void> deleteYogaReview({required String instructorId}) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return;
    debugPrint('\x1B[33m[API] DELETE /rest/v1/yoga_instructor_reviews\x1B[0m');
    await client
        .from('yoga_instructor_reviews')
        .delete()
        .eq('instructor_id', instructorId)
        .eq('user_id', userId);
    debugPrint('\x1B[32m[API] 200 OK | Yoga review deleted\x1B[0m');
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | deleteYogaReview | $e\x1B[0m');
    rethrow;
  }
}

  // YOGA SESSION BOOKINGS

  static Future<void> bookYogaSession({
    required String instructorId,
    required String startDate,
    required int numSessions,
    required double totalPrice,
    String notes = '',
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;
      debugPrint('\x1B[33m[API] POST /rest/v1/yoga_session_bookings\x1B[0m');
      await client.from('yoga_session_bookings').insert({
        'instructor_id': instructorId,
        'user_id': userId,
        'start_date': startDate,
        'num_sessions': numSessions,
        'total_price': totalPrice,
        'notes': notes,
        'status': 'pending',
      });
      debugPrint('\x1B[32m[API] 200 OK | Yoga session booked\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | bookYogaSession | $e\x1B[0m');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getMyYogaBookings() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];
      debugPrint('\x1B[33m[API] GET /rest/v1/yoga_session_bookings\x1B[0m');
      final data = await client
          .from('yoga_session_bookings')
          .select('*, yoga_instructors(name, image_url, specialty)')
          .eq('user_id', userId)
          .order('start_date', ascending: true);
      debugPrint('\x1B[32m[API] 200 OK | YogaBookings: ${data.length}\x1B[0m');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getMyYogaBookings | $e\x1B[0m');
      return [];
    }
  }

  static Future<bool> hasExistingYogaBooking({
    required String instructorId,
    required String startDate,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return false;
      final data = await client
          .from('yoga_session_bookings')
          .select('id')
          .eq('user_id', userId)
          .eq('instructor_id', instructorId)
          .eq('start_date', startDate)
          .maybeSingle();
      return data != null;
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | hasExistingYogaBooking | $e\x1B[0m');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getMyYogaBookingsForInstructor(String instructorId) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];
      final data = await client
          .from('yoga_session_bookings')
          .select()
          .eq('user_id', userId)
          .eq('instructor_id', instructorId)
          .order('start_date', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getMyYogaBookingsForInstructor | $e\x1B[0m');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getYogaClasses(String timeSlot) async {
    try {
      debugPrint('\x1B[36m[API] GET /rest/v1/yoga_classes | timeSlot: $timeSlot\x1B[0m');
      final data = await client
          .from('yoga_classes')
          .select()
          .eq('time_slot', timeSlot)
          .eq('is_active', true)
          .order('created_at', ascending: true);
      debugPrint('\x1B[32m[API] 200 OK | YogaClasses: ${data.length}\x1B[0m');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getYogaClasses | $e\x1B[0m');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getYogaClassSteps(String classId) async {
    try {
      debugPrint('\x1B[36m[API] GET /rest/v1/yoga_class_steps | classId: $classId\x1B[0m');
      final data = await client
          .from('yoga_class_steps')
          .select()
          .eq('class_id', classId)
          .order('step_number', ascending: true);
      debugPrint('\x1B[32m[API] 200 OK | YogaClassSteps: ${data.length}\x1B[0m');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getYogaClassSteps | $e\x1B[0m');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchYogaClasses(String query) async {
    try {
      final data = await client
          .from('yoga_classes')
          .select()
          .ilike('title', '%$query%')
          .eq('is_active', true)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | searchYogaClasses | $e\x1B[0m');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // WEEKLY CHALLENGE
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getActiveChallengeForUser() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;
      final setup = await client
          .from('user_setup')
          .select('goal')
          .eq('id', userId)
          .maybeSingle();
      final goal = setup?['goal'] ?? 'Stay Fit';
      debugPrint('\x1B[33m[API] GET weekly_challenges | goal: $goal\x1B[0m');
      final data = await client
          .from('weekly_challenges')
          .select()
          .eq('target_goal', goal)
          .eq('is_active', true)
          .maybeSingle();
      debugPrint('\x1B[32m[API] 200 OK | Challenge: ${data?['title']}\x1B[0m');
      return data;
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getActiveChallengeForUser | $e\x1B[0m');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getTodayChallengeDayForUser(String challengeId) async {
    try {
      final todayWeekday = DateTime.now().weekday;
      debugPrint('\x1B[33m[API] GET challenge_days | day: $todayWeekday\x1B[0m');
      final data = await client
          .from('challenge_days')
          .select()
          .eq('challenge_id', challengeId)
          .eq('day_number', todayWeekday)
          .maybeSingle();
      debugPrint('\x1B[32m[API] 200 OK | Day: ${data?['day_name']}\x1B[0m');
      return data;
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getTodayChallengeDayForUser | $e\x1B[0m');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getRoundsForDay(String dayId) async {
    try {
      debugPrint('\x1B[33m[API] GET challenge_rounds | dayId: $dayId\x1B[0m');
      final data = await client
          .from('challenge_rounds')
          .select()
          .eq('day_id', dayId)
          .order('round_number', ascending: true);
      debugPrint('\x1B[32m[API] 200 OK | Rounds: ${data.length}\x1B[0m');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getRoundsForDay | $e\x1B[0m');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getExercisesForRound(String roundId) async {
    try {
      debugPrint('\x1B[33m[API] GET challenge_exercises | roundId: $roundId\x1B[0m');
      final data = await client
          .from('challenge_exercises')
          .select()
          .eq('round_id', roundId)
          .order('order_number', ascending: true);
      debugPrint('\x1B[32m[API] 200 OK | Exercises: ${data.length}\x1B[0m');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getExercisesForRound | $e\x1B[0m');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getUserExerciseProgress({
    required String exerciseId,
    required String challengeId,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;
      final data = await client
          .from('challenge_user_progress')
          .select()
          .eq('user_id', userId)
          .eq('exercise_id', exerciseId)
          .eq('challenge_id', challengeId)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getUserExerciseProgress | $e\x1B[0m');
      return null;
    }
  }

  static Future<void> markExerciseDone({
    required String exerciseId,
    required String challengeId,
    required int dayNumber,
    required int timeSpentSeconds,
    required int caloriesFull,
    required int durationSeconds,
    required bool markedEarly,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;
      final ratio = durationSeconds > 0
          ? (timeSpentSeconds / durationSeconds).clamp(0.0, 1.0)
          : 1.0;
      final caloriesBurned = (caloriesFull * ratio).round();
      debugPrint('\x1B[33m[API] UPSERT challenge_user_progress | exercise: $exerciseId\x1B[0m');
      await client.from('challenge_user_progress').upsert({
        'user_id': userId,
        'exercise_id': exerciseId,
        'challenge_id': challengeId,
        'day_number': dayNumber,
        'is_completed': true,
        'marked_done_early': markedEarly,
        'time_spent_seconds': timeSpentSeconds,
        'calories_burned': caloriesBurned,
        'completed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,exercise_id,challenge_id');
      debugPrint('\x1B[32m[API] 200 OK | Marked done | calories: $caloriesBurned\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | markExerciseDone | $e\x1B[0m');
      rethrow;
    }
  }

  static Future<List<String>> getCompletedExerciseIds({
    required String challengeId,
    required int dayNumber,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];
      final data = await client
          .from('challenge_user_progress')
          .select('exercise_id')
          .eq('user_id', userId)
          .eq('challenge_id', challengeId)
          .eq('day_number', dayNumber)
          .eq('is_completed', true);
      return List<String>.from(data.map((r) => r['exercise_id']));
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getCompletedExerciseIds | $e\x1B[0m');
      return [];
    }
  }

  static Future<int> getDayTotalCalories({
    required String challengeId,
    required int dayNumber,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return 0;
      final data = await client
          .from('challenge_user_progress')
          .select('calories_burned')
          .eq('user_id', userId)
          .eq('challenge_id', challengeId)
          .eq('day_number', dayNumber);
      return List<Map<String, dynamic>>.from(data)
          .fold<int>(0, (sum, r) => sum + ((r['calories_burned'] as num?)?.toInt() ?? 0));
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getDayTotalCalories | $e\x1B[0m');
      return 0;
    }
  }

  // ─────────────────────────────────────────────
  // ACTIVITY STATS
  // Returns List<Map> — converted to _DayStat inside runner_page.dart
  // Keys: label, date, challengeKcal, gymKcal, yogaKcal, challengeSec, gymSec
  // ─────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getActivityStats({int days = 7}) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));

    debugPrint('\x1B[33m[API] getActivityStats | days: $days | from: $start\x1B[0m');

    final challengeRows = await client
        .from('challenge_user_progress')
        .select('calories_burned, time_spent_seconds, completed_at')
        .eq('user_id', userId)
        .eq('is_completed', true)
        .gte('completed_at', start.toIso8601String());

    List<dynamic> gymRows = [];
    try {
      gymRows = await client
          .from('gym_workout_logs')
          .select('calories_burned, duration_seconds, completed_at')
          .eq('user_id', userId)
          .gte('completed_at', start.toIso8601String());
    } catch (_) {
      debugPrint('\x1B[33m[API] gym_workout_logs not found — skipping\x1B[0m');
    }

    // ── Yoga: instructor_class_logs ──
    List<dynamic> yogaRows = [];
    try {
      yogaRows = await client
          .from('instructor_class_logs')
          .select('session_duration_minutes, scheduled_date')
          .eq('user_id', userId)
          .eq('is_done', true)
          .gte('scheduled_date', start.toIso8601String().substring(0, 10));
    } catch (_) {
      debugPrint('\x1B[33m[API] instructor_class_logs yoga fetch failed — skipping\x1B[0m');
    }

    final Map<String, Map<String, int>> buckets = {};
    for (int i = 0; i < days; i++) {
      final d = start.add(Duration(days: i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      buckets[key] = {
        'challengeKcal': 0,
        'gymKcal': 0,
        'yogaKcal': 0,
        'challengeSec': 0,
        'gymSec': 0,
      };
    }

    for (final row in challengeRows) {
      final dt = DateTime.tryParse(row['completed_at'] ?? '');
      if (dt == null) continue;
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      if (buckets.containsKey(key)) {
        buckets[key]!['challengeKcal'] =
            buckets[key]!['challengeKcal']! + (row['calories_burned'] as num? ?? 0).toInt();
        buckets[key]!['challengeSec'] =
            buckets[key]!['challengeSec']! + (row['time_spent_seconds'] as num? ?? 0).toInt();
      }
    }

    for (final row in gymRows) {
      final dt = DateTime.tryParse(row['completed_at'] ?? '');
      if (dt == null) continue;
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      if (buckets.containsKey(key)) {
        buckets[key]!['gymKcal'] =
            buckets[key]!['gymKcal']! + (row['calories_burned'] as num? ?? 0).toInt();
        buckets[key]!['gymSec'] =
            buckets[key]!['gymSec']! + (row['duration_seconds'] as num? ?? 0).toInt();
      }
    }

    // yoga kcal estimate: 5 kcal per minute
    for (final row in yogaRows) {
      final dateStr = row['scheduled_date'] as String?;
      if (dateStr == null) continue;
      final key = dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr;
      if (buckets.containsKey(key)) {
        final mins = (row['session_duration_minutes'] as num? ?? 0).toInt();
        buckets[key]!['yogaKcal'] =
            buckets[key]!['yogaKcal']! + (mins * 5);
      }
    }

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final result = buckets.entries.map((e) {
      final dt = DateTime.parse(e.key);
      String label;
      if (days <= 7) {
        label = dayNames[dt.weekday - 1];
      } else if (days <= 31) {
        label = '${dt.day}/${dt.month}';
      } else {
        label = '${dt.month}/${dt.day}';
      }
      return <String, dynamic>{
        'label': label,
        'date': e.key,
        'challengeKcal': e.value['challengeKcal']!,
        'gymKcal': e.value['gymKcal']!,
        'yogaKcal': e.value['yogaKcal']!,
        'challengeSec': e.value['challengeSec']!,
        'gymSec': e.value['gymSec']!,
      };
    }).toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    debugPrint('\x1B[32m[API] 200 OK | activityStats: ${result.length} days\x1B[0m');
    return result;
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getActivityStats | $e\x1B[0m');
    return [];
  }
}

  // ─────────────────────────────────────────────
  // GYM WORKOUT SESSIONS
  // ─────────────────────────────────────────────

  static Future<void> logWorkoutSession({
    required String exerciseId,
    required String exerciseTitle,
    required int caloriesBurned,
    required int durationSeconds,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;
      debugPrint('\x1B[33m[API] POST /rest/v1/workout_sessions | exercise: $exerciseTitle\x1B[0m');
      await client.from('workout_sessions').insert({
        'user_id': userId,
        'exercise_id': exerciseId,
        'exercise_title': exerciseTitle,
        'calories_burned': caloriesBurned,
        'duration_seconds': durationSeconds,
        'completed_at': DateTime.now().toIso8601String(),
      });
      debugPrint('\x1B[32m[API] 200 OK | Workout session logged\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | logWorkoutSession | $e\x1B[0m');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
// Add these methods to SupabaseService
// ─────────────────────────────────────────────

  /// Returns full daily detail for the history page.
  /// Each entry: date, challengeKcal, gymKcal, yogaKcal,
  ///             totalSecs, challengeRounds (list), gymSessions (list)
  static Future<List<Map<String, dynamic>>> getFullActivityHistory({int days = 90}) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final now   = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));

    final challengeRows = await client
        .from('challenge_user_progress')
        .select('calories_burned, time_spent_seconds, completed_at, exercise_id, day_number')
        .eq('user_id', userId)
        .eq('is_completed', true)
        .gte('completed_at', start.toIso8601String())
        .order('completed_at', ascending: false);

    List<dynamic> gymRows = [];
    try {
      gymRows = await client
          .from('gym_workout_logs')
          .select('calories_burned, duration_seconds, completed_at, exercise_title, exercise_id, set_number, reps_completed, category')
          .eq('user_id', userId)
          .gte('completed_at', start.toIso8601String())
          .order('completed_at', ascending: true);
    } catch (_) {}

    // ── Yoga: instructor_class_logs + class title ──
    List<dynamic> yogaRows = [];
    try {
      yogaRows = await client
          .from('instructor_class_logs')
          .select('session_duration_minutes, scheduled_date, class_id, instructor_paid_classes(title, image_url)')
          .eq('user_id', userId)
          .eq('is_done', true)
          .gte('scheduled_date', start.toIso8601String().substring(0, 10))
          .order('scheduled_date', ascending: true);
    } catch (_) {
      debugPrint('\x1B[33m[API] yoga history fetch failed — skipping\x1B[0m');
    }

    // Build buckets
    final Map<String, Map<String, dynamic>> buckets = {};
    for (int i = 0; i < days; i++) {
      final d   = start.add(Duration(days: i));
      final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      buckets[key] = {
        'date': key,
        'challengeKcal': 0,
        'gymKcal': 0,
        'yogaKcal': 0,
        'totalSecs': 0,
        'challengeRounds': <Map<String,dynamic>>[],
        'gymSessions': <Map<String,dynamic>>[],
        'yogaSessions': <Map<String,dynamic>>[],
      };
    }

    for (final row in challengeRows) {
      final dt  = DateTime.tryParse(row['completed_at'] ?? ''); if (dt == null) continue;
      final key = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
      if (!buckets.containsKey(key)) continue;
      final kcal = (row['calories_burned'] as num? ?? 0).toInt();
      final secs = (row['time_spent_seconds'] as num? ?? 0).toInt();
      buckets[key]!['challengeKcal'] = (buckets[key]!['challengeKcal'] as int) + kcal;
      buckets[key]!['totalSecs']     = (buckets[key]!['totalSecs'] as int) + secs;
      (buckets[key]!['challengeRounds'] as List).add({
        'exerciseId': row['exercise_id'],
        'dayNumber':  row['day_number'],
        'kcal':       kcal,
        'secs':       secs,
      });
    }

    final Map<String, Map<String, Map<String, dynamic>>> gymGrouped = {};
    for (final row in gymRows) {
      final dt  = DateTime.tryParse(row['completed_at'] ?? ''); if (dt == null) continue;
      final key = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
      if (!buckets.containsKey(key)) continue;
      final exId    = row['exercise_id'] as String? ?? 'unknown';
      final exTitle = row['exercise_title'] as String? ?? 'Gym Exercise';
      final kcal    = (row['calories_burned'] as num? ?? 0).toInt();
      final secs    = (row['duration_seconds'] as num? ?? 0).toInt();
      final setNum  = (row['set_number'] as num? ?? 0).toInt();
      final reps    = (row['reps_completed'] as num? ?? 0).toInt();

      gymGrouped.putIfAbsent(key, () => {});
      if (!gymGrouped[key]!.containsKey(exId)) {
        gymGrouped[key]![exId] = {
          'title': exTitle,
          'category': row['category'] as String? ?? 'Gym',
          'totalKcal': 0,
          'totalSecs': 0,
          'sets': <Map<String, dynamic>>[],
        };
      }
      gymGrouped[key]![exId]!['totalKcal'] = (gymGrouped[key]![exId]!['totalKcal'] as int) + kcal;
      gymGrouped[key]![exId]!['totalSecs'] = (gymGrouped[key]![exId]!['totalSecs'] as int) + secs;
      (gymGrouped[key]![exId]!['sets'] as List).add({
        'setNumber': setNum,
        'reps': reps,
        'kcal': kcal,
        'secs': secs,
      });
    }

    for (final key in gymGrouped.keys) {
      if (!buckets.containsKey(key)) continue;
      for (final ex in gymGrouped[key]!.values) {
        final kcal = ex['totalKcal'] as int;
        final secs = ex['totalSecs'] as int;
        buckets[key]!['gymKcal']   = (buckets[key]!['gymKcal'] as int) + kcal;
        buckets[key]!['totalSecs'] = (buckets[key]!['totalSecs'] as int) + secs;
        (buckets[key]!['gymSessions'] as List).add({
          'title':    ex['title'],
          'category': ex['category'],
          'kcal':     kcal,
          'secs':     secs,
          'sets':     ex['sets'],
        });
      }
    }

    // ── Yoga buckets ──
    for (final row in yogaRows) {
      final dateStr = row['scheduled_date'] as String?;
      if (dateStr == null) continue;
      final key = dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr;
      if (!buckets.containsKey(key)) continue;
      final mins  = (row['session_duration_minutes'] as num? ?? 0).toInt();
      final kcal  = mins * 5;
      final secs  = mins * 60;
      final cls   = row['instructor_paid_classes'] as Map<String, dynamic>?;
      final title = cls?['title'] as String? ?? 'Yoga Class';
      final image = cls?['image_url'] as String? ?? '';
      buckets[key]!['yogaKcal']  = (buckets[key]!['yogaKcal'] as int) + kcal;
      buckets[key]!['totalSecs'] = (buckets[key]!['totalSecs'] as int) + secs;
      (buckets[key]!['yogaSessions'] as List).add({
        'title': title,
        'image': image,
        'kcal':  kcal,
        'secs':  secs,
        'mins':  mins,
      });
    }

    final result = buckets.values.toList()
      ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

    return result;
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getFullActivityHistory | $e\x1B[0m');
    return [];
  }
}

  // ─────────────────────────────────────────────
  // GYM WORKOUT LOGS (per-set tracking)
  // ─────────────────────────────────────────────

  static Future<bool> isGymExerciseDoneToday(String exerciseId) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return false;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final start = '${today}T00:00:00.000Z';
      final end   = '${today}T23:59:59.999Z';
      final data  = await client
          .from('gym_workout_logs')
          .select('id')
          .eq('user_id', userId)
          .eq('exercise_id', exerciseId)
          .gte('completed_at', start)
          .lte('completed_at', end)
          .limit(1)
          .maybeSingle();
      return data != null;
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | isGymExerciseDoneToday | $e\x1B[0m');
      return false;
    }
  }

  static Future<void> logGymSet({
    required String exerciseId,
    required String exerciseTitle,
    required String category,
    required int setNumber,
    required int repsCompleted,
    required int durationSeconds,
    required int caloriesBurned,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;
      debugPrint('\x1B[33m[API] POST /rest/v1/gym_workout_logs | $exerciseTitle set $setNumber\x1B[0m');
      await client.from('gym_workout_logs').insert({
        'user_id': userId,
        'exercise_id': exerciseId,
        'exercise_title': exerciseTitle,
        'category': category,
        'set_number': setNumber,
        'reps_completed': repsCompleted,
        'duration_seconds': durationSeconds,
        'calories_burned': caloriesBurned,
        'completed_at': DateTime.now().toIso8601String(),
      });
      debugPrint('\x1B[32m[API] 200 OK | Set logged\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | logGymSet | $e\x1B[0m');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getGymExerciseSteps(String exerciseId) async {
    try {
      debugPrint('\x1B[33m[API] GET /rest/v1/gym_exercise_steps | exercise: $exerciseId\x1B[0m');
      final data = await client
          .from('gym_exercise_steps')
          .select()
          .eq('exercise_id', exerciseId)
          .order('step_number', ascending: true);
      debugPrint('\x1B[32m[API] 200 OK | Steps: ${data.length}\x1B[0m');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getGymExerciseSteps | $e\x1B[0m');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getGymLogsForDate(String date) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];
      final start = '${date}T00:00:00.000Z';
      final end   = '${date}T23:59:59.999Z';
      final data  = await client
          .from('gym_workout_logs')
          .select()
          .eq('user_id', userId)
          .gte('completed_at', start)
          .lte('completed_at', end)
          .order('completed_at', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getGymLogsForDate | $e\x1B[0m');
      return [];
    }
  }

  /// Delete activity history older than 2 months
  static Future<void> clearOldActivityHistory() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;
      final cutoff = DateTime.now().subtract(const Duration(days: 10)).toIso8601String();
      final cutoffDate = cutoff.substring(0, 10);

      await client
          .from('challenge_user_progress')
          .delete()
          .eq('user_id', userId)
          .lt('completed_at', cutoff);

      try {
        await client
            .from('gym_workout_logs')
            .delete()
            .eq('user_id', userId)
            .lt('completed_at', cutoff);
      } catch (_) {}

      try {
        await client
            .from('instructor_class_logs')
            .delete()
            .eq('user_id', userId)
            .lt('scheduled_date', cutoffDate);
      } catch (_) {}

      try {
        await client
            .from('workout_sessions')
            .delete()
            .eq('user_id', userId)
            .lt('completed_at', cutoff);
      } catch (_) {}

      debugPrint('\x1B[32m[API] clearOldActivityHistory done (10 days)\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | clearOldActivityHistory | $e\x1B[0m');
    }
  }

// ─────────────────────────────────────────────
  // INSTRUCTOR PAID CLASSES
  // ─────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getInstructorPaidClasses(
    String instructorId, {int? limit}) async {
  try {
    debugPrint(
        '\x1B[33m[API] GET /rest/v1/instructor_paid_classes | instructor: $instructorId | limit: $limit\x1B[0m');
    var query = client
        .from('instructor_paid_classes')
        .select()
        .eq('instructor_id', instructorId)
        .eq('is_active', true)
        .order('created_at', ascending: true);
    final data = limit != null ? await query.limit(limit) : await query;
    debugPrint(
        '\x1B[32m[API] 200 OK | PaidClasses: ${data.length}\x1B[0m');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint(
        '\x1B[31m[API] ERROR | getInstructorPaidClasses | $e\x1B[0m');
    return [];
  }
}

  static Future<bool> hasActiveBookingWithInstructor(
    String instructorId) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return false;
    final data = await client
        .from('yoga_session_bookings')
        .select('id')
        .eq('user_id', userId)
        .eq('instructor_id', instructorId)
        .limit(1);
    return (data as List).isNotEmpty;
  } catch (e) {
    debugPrint(
        '\x1B[31m[API] ERROR | hasActiveBookingWithInstructor | $e\x1B[0m');
    return false;
  }
}

  // ─────────────────────────────────────────────
  // USER FEED CLASSES
  // ─────────────────────────────────────────────

  static Future<void> addClassToFeed({
    required String classId,
    required String instructorId,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;
      debugPrint('\x1B[33m[API] POST /rest/v1/user_feed_classes\x1B[0m');
      await client.from('user_feed_classes').insert({
        'user_id': userId,
        'class_id': classId,
        'instructor_id': instructorId,
      });
      debugPrint('\x1B[32m[API] 200 OK | Class added to feed\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | addClassToFeed | $e\x1B[0m');
      rethrow;
    }
  }

  static Future<void> removeClassFromFeed(String classId) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;
      debugPrint('\x1B[33m[API] DELETE /rest/v1/user_feed_classes\x1B[0m');
      await client
          .from('user_feed_classes')
          .delete()
          .eq('user_id', userId)
          .eq('class_id', classId);
      debugPrint('\x1B[32m[API] 200 OK | Class removed from feed\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | removeClassFromFeed | $e\x1B[0m');
      rethrow;
    }
  }

  static Future<bool> isClassInFeed(String classId) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return false;
      final data = await client
          .from('user_feed_classes')
          .select('id')
          .eq('user_id', userId)
          .eq('class_id', classId)
          .maybeSingle();
      return data != null;
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | isClassInFeed | $e\x1B[0m');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserFeedClasses() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];
      debugPrint('\x1B[33m[API] GET /rest/v1/user_feed_classes\x1B[0m');
      final data = await client
          .from('user_feed_classes')
          .select('id, class_id, added_at, content_type, trainer_id, booking_id, instructor_id')
          .eq('user_id', userId)
          .eq('content_type', 'yoga')
          .order('added_at', ascending: false);
      debugPrint(
          '\x1B[32m[API] 200 OK | UserFeedClasses: ${data.length}\x1B[0m');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getUserFeedClasses | $e\x1B[0m');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // INSTRUCTOR CLASS STEPS & LOGS
  // ─────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getInstructorClassSteps(String classId) async {
    try {
      debugPrint('\x1B[33m[API] GET instructor_class_steps | class: $classId\x1B[0m');
      final data = await client
          .from('instructor_class_steps')
          .select()
          .eq('class_id', classId)
          .order('step_number', ascending: true);
      debugPrint('\x1B[32m[API] 200 OK | Steps: ${data.length}\x1B[0m');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getInstructorClassSteps | $e\x1B[0m');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getInstructorClassLog({
    required String classId,
    required String date, // 'YYYY-MM-DD'
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;
      final data = await client
          .from('instructor_class_logs')
          .select()
          .eq('user_id', userId)
          .eq('class_id', classId)
          .eq('scheduled_date', date)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getInstructorClassLog | $e\x1B[0m');
      return null;
    }
  }

  static Future<void> upsertInstructorClassLog({
    required String classId,
    required String instructorId,
    required String date, // 'YYYY-MM-DD'
    required bool isDone,
    required int sessionDurationMinutes,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;
      debugPrint('\x1B[33m[API] UPSERT instructor_class_logs | class: $classId | done: $isDone\x1B[0m');
      await client.from('instructor_class_logs').upsert({
        'user_id': userId,
        'class_id': classId,
        'instructor_id': instructorId,
        'scheduled_date': date,
        'is_done': isDone,
        'completed_at': isDone ? DateTime.now().toIso8601String() : null,
        'session_duration_minutes': sessionDurationMinutes,
      }, onConflict: 'user_id,class_id,scheduled_date');
      debugPrint('\x1B[32m[API] 200 OK | Class log upserted\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | upsertInstructorClassLog | $e\x1B[0m');
      rethrow;
    }
  }

  /// Returns all logs for the current user across all instructor classes.
  /// Used for history page and stats.
  static Future<List<Map<String, dynamic>>> getInstructorClassLogs({int days = 90}) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];
      final start = DateTime.now()
          .subtract(Duration(days: days))
          .toIso8601String()
          .substring(0, 10);
      final data = await client
          .from('instructor_class_logs')
          .select('*, instructor_paid_classes(title, duration_minutes, image_url, instructor_id), yoga_instructors(name)')
          .eq('user_id', userId)
          .eq('is_done', true)
          .gte('scheduled_date', start)
          .order('scheduled_date', ascending: false);
      debugPrint('\x1B[32m[API] 200 OK | InstructorClassLogs: ${data.length}\x1B[0m');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getInstructorClassLogs | $e\x1B[0m');
      return [];
    }
  }

  /// Returns the next upcoming class for a given instructor
  /// based on scheduled_date ordering from today.
  static Future<Map<String, dynamic>?> getNextInstructorClass(String instructorId) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      // Get all paid classes for instructor
      final classes = await client
          .from('instructor_paid_classes')
          .select('id, title, duration_minutes, scheduled_time')
          .eq('instructor_id', instructorId)
          .eq('is_active', true);
      if (classes.isEmpty) return null;
      final classIds = (classes as List).map((c) => c['id'] as String).toList();
      // Find first not done today or upcoming
      for (final cls in classes) {
        final log = await client
            .from('instructor_class_logs')
            .select()
            .eq('user_id', userId)
            .eq('class_id', cls['id'])
            .eq('scheduled_date', today)
            .maybeSingle();
        if (log == null || log['is_done'] == false) {
          return {
            ...cls,
            'scheduled_date': today,
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getNextInstructorClass | $e\x1B[0m');
      return null;
    }
  }

  static Future<void> deleteInstructorClassLog({
    required String classId,
    required String date,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;
      debugPrint('\x1B[33m[API] DELETE instructor_class_logs | class: $classId | date: $date\x1B[0m');
      await client
          .from('instructor_class_logs')
          .delete()
          .eq('user_id', userId)
          .eq('class_id', classId)
          .eq('scheduled_date', date);
      debugPrint('\x1B[32m[API] 200 OK | Class log deleted\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | deleteInstructorClassLog | $e\x1B[0m');
      rethrow;
    }
  }

// ─────────────────────────────────────────────
// INSTRUCTOR SESSIONS (new system)
// ─────────────────────────────────────────────

/// Get all sessions for an instructor
static Future<List<Map<String, dynamic>>> getInstructorSessions(
    String instructorId) async {
  try {
    debugPrint('\x1B[33m[API] GET instructor_sessions | instructor: $instructorId\x1B[0m');
    final data = await client
        .from('instructor_sessions')
        .select()
        .eq('instructor_id', instructorId)
        .eq('is_active', true)
        .order('session_start', ascending: true);
    debugPrint('\x1B[32m[API] 200 OK | Sessions: ${data.length}\x1B[0m');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getInstructorSessions | $e\x1B[0m');
    return [];
  }
}

/// Get classes for a specific session
static Future<List<Map<String, dynamic>>> getSessionClasses(
    String sessionId) async {
  try {
    debugPrint('\x1B[33m[API] GET instructor_session_classes | session: $sessionId\x1B[0m');
    final data = await client
        .from('instructor_session_classes')
        .select('*, instructor_paid_classes(*)')
        .eq('session_id', sessionId)
        .order('order_number', ascending: true);
    debugPrint('\x1B[32m[API] 200 OK | SessionClasses: ${data.length}\x1B[0m');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getSessionClasses | $e\x1B[0m');
    return [];
  }
}

/// Get time slots for a class
static Future<List<Map<String, dynamic>>> getClassSlots(
    String classId) async {
  try {
    debugPrint('\x1B[33m[API] GET instructor_class_slots | class: $classId\x1B[0m');
    final data = await client
        .from('instructor_class_slots')
        .select()
        .eq('class_id', classId)
        .order('start_time', ascending: true);
    debugPrint('\x1B[32m[API] 200 OK | Slots: ${data.length}\x1B[0m');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getClassSlots | $e\x1B[0m');
    return [];
  }
}

/// Book sessions — replaces old bookYogaSession for new flow
static Future<void> bookInstructorSessions({
  required String instructorId,
  required List<String> sessionIds, // sessions user selected
  required int sessionCount,
  required double totalPrice,
  String notes = '',
}) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return;
    debugPrint('\x1B[33m[API] POST yoga_session_bookings (new) | sessions: $sessionCount\x1B[0m');

    // Calculate expires_at from the last session's end date
    final lastSession = await client
        .from('instructor_sessions')
        .select('session_end')
        .eq('id', sessionIds.last)
        .single();
    final expiresAt = lastSession['session_end'] as String;

    for (final sessionId in sessionIds) {
      await client.from('yoga_session_bookings').insert({
        'user_id': userId,
        'instructor_id': instructorId,
        'session_id': sessionId,
        'start_date': (await client
                .from('instructor_sessions')
                .select('session_start')
                .eq('id', sessionId)
                .single())['session_start'],
        'num_sessions': 1,
        'total_price': totalPrice / sessionIds.length,
        'notes': notes,
        'status': 'active',
        'expires_at': expiresAt,
        'payment_status': 'paid',
      });
    }
    debugPrint('\x1B[32m[API] 200 OK | Sessions booked: ${sessionIds.length}\x1B[0m');
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | bookInstructorSessions | $e\x1B[0m');
    rethrow;
  }
}

/// Get user's booked sessions for an instructor (active only, not expired)
static Future<List<Map<String, dynamic>>> getUserBookedSessions(
    String instructorId) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final data = await client
        .from('yoga_session_bookings')
        .select('*, instructor_sessions(*)')
        .eq('user_id', userId)
        .eq('instructor_id', instructorId)
        .not('session_id', 'is', null)
        .order('start_date', ascending: true);
    debugPrint('\x1B[32m[API] 200 OK | UserBookedSessions: ${data.length}\x1B[0m');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getUserBookedSessions | $e\x1B[0m');
    return [];
  }
}

/// Get ALL booked sessions across all instructors for home/overview
static Future<List<Map<String, dynamic>>> getAllUserBookedSessions() async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final data = await client
        .from('yoga_session_bookings')
        .select('*, instructor_sessions(*), yoga_instructors(name, image_url, specialty)')
        .eq('user_id', userId)
        .eq('status', 'active')
        .gte('expires_at', today)
        .order('start_date', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getAllUserBookedSessions | $e\x1B[0m');
    return [];
  }
}

/// Mark attendance for a class slot
static Future<void> markClassAttendance({
  required String bookingId,
  required String sessionId,
  required String classId,
  required String slotId,
  required bool isDone,
}) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return;
    debugPrint('\x1B[33m[API] UPSERT user_class_attendance | class: $classId | done: $isDone\x1B[0m');
    await client.from('user_class_attendance').upsert({
      'user_id': userId,
      'booking_id': bookingId,
      'session_id': sessionId,
      'class_id': classId,
      'slot_id': slotId,
      'status': isDone ? 'done' : 'joined',
      'marked_done_at': isDone ? DateTime.now().toIso8601String() : null,
      'is_expired': false,
    }, onConflict: 'user_id,class_id,slot_id');
    debugPrint('\x1B[32m[API] 200 OK | Attendance marked\x1B[0m');
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | markClassAttendance | $e\x1B[0m');
    rethrow;
  }
}

/// Get attendance records for a session
static Future<List<Map<String, dynamic>>> getSessionAttendance(
    String sessionId) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final data = await client
        .from('user_class_attendance')
        .select()
        .eq('user_id', userId)
        .eq('session_id', sessionId);
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getSessionAttendance | $e\x1B[0m');
    return [];
  }
}

/// Check if user already booked a specific session
static Future<bool> hasBookedSession(String sessionId) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return false;
    final data = await client
        .from('yoga_session_bookings')
        .select('id')
        .eq('user_id', userId)
        .eq('session_id', sessionId)
        .maybeSingle();
    return data != null;
  } catch (e) {
    return false;
  }
}
// ─────────────────────────────────────────────
// TRAINER WEEKLY SLOTS (new system)
// ─────────────────────────────────────────────

/// Get all weekly slots for a trainer
static Future<List<Map<String, dynamic>>> getTrainerWeeklySlots(
    String trainerId) async {
  try {
    debugPrint('\x1B[33m[API] GET trainer_weekly_slots | trainer: $trainerId\x1B[0m');
    final data = await client
        .from('trainer_weekly_slots')
        .select()
        .eq('trainer_id', trainerId)
        .eq('is_active', true)
        .order('day_of_week', ascending: true)
        .order('start_time', ascending: true);
    debugPrint('\x1B[32m[API] 200 OK | WeeklySlots: ${data.length}\x1B[0m');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getTrainerWeeklySlots | $e\x1B[0m');
    return [];
  }
}

/// Get booking count for a specific slot on a specific date
static Future<int> getSlotBookingCount({
  required String weeklySlotId,
  required String date,
}) async {
  try {
    final result = await client.rpc('get_slot_booking_count', params: {
      'p_weekly_slot_id': weeklySlotId,
      'p_date': date,
    });
    return (result as int?) ?? 0;
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getSlotBookingCount | $e\x1B[0m');
    return 0;
  }
}

/// Check if current user already booked this slot on this date
static Future<bool> hasBookedSlot({
  required String weeklySlotId,
  required String date,
}) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return false;
    final data = await client
        .from('trainer_slot_bookings')
        .select('id')
        .eq('user_id', userId)
        .eq('weekly_slot_id', weeklySlotId)
        .eq('booking_date', date)
        .neq('status', 'cancelled')
        .maybeSingle();
    return data != null;
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | hasBookedSlot | $e\x1B[0m');
    return false;
  }
}

/// Book a trainer slot
static Future<Map<String, dynamic>> bookTrainerSlot({
  required String trainerId,
  required String weeklySlotId,
  required String bookingDate,
  required String startTime,
  required String endTime,
  required double price,
  required String paymentCardLast4,
  String notes = '',
}) async {
  final userId = currentUser?.id;
  if (userId == null) throw Exception('Not logged in');

  // Duplicate check
  final alreadyBooked = await hasBookedSlot(
    weeklySlotId: weeklySlotId,
    date: bookingDate,
  );
  if (alreadyBooked) throw Exception('already_booked');

  // Capacity check
  final slotData = await client
      .from('trainer_weekly_slots')
      .select('max_capacity')
      .eq('id', weeklySlotId)
      .single();
  final maxCapacity = (slotData['max_capacity'] as int?) ?? 20;
  final currentCount = await getSlotBookingCount(
    weeklySlotId: weeklySlotId,
    date: bookingDate,
  );
  if (currentCount >= maxCapacity) throw Exception('slot_full');

  debugPrint('\x1B[33m[API] POST trainer_slot_bookings | slot: $weeklySlotId | date: $bookingDate\x1B[0m');
  final result = await client
      .from('trainer_slot_bookings')
      .insert({
        'user_id': userId,
        'trainer_id': trainerId,
        'weekly_slot_id': weeklySlotId,
        'booking_date': bookingDate,
        'start_time': startTime,
        'end_time': endTime,
        'price': price,
        'status': 'confirmed',
        'payment_card_last4': paymentCardLast4,
        'notes': notes,
      })
      .select()
      .single();
  debugPrint('\x1B[32m[API] 200 OK | Slot booked\x1B[0m');
  return Map<String, dynamic>.from(result);
}

/// Get all bookings for current user
static Future<List<Map<String, dynamic>>> getMyTrainerSlotBookings() async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final data = await client
        .from('trainer_slot_bookings')
        .select('*, fitness_trainers(id, name, image_url, training_type), trainer_weekly_slots(day_of_week, duration_minutes)')
.eq('user_id', userId)
.order('booking_date', ascending: true);
    debugPrint('\x1B[32m[API] 200 OK | MySlotBookings: ${data.length}\x1B[0m');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getMyTrainerSlotBookings | $e\x1B[0m');
    return [];
  }
}

/// Get upcoming bookings for current user (today and future)
static Future<List<Map<String, dynamic>>> getUpcomingTrainerBookings() async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final data = await client
        .from('trainer_slot_bookings')
.select('*, fitness_trainers(id, name, image_url, training_type, rating, experience, phone_number)')
.eq('user_id', userId)
.eq('status', 'confirmed')
        .gte('booking_date', today)
        .order('booking_date', ascending: true)
        .order('start_time', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getUpcomingTrainerBookings | $e\x1B[0m');
    return [];
  }
}

/// Mark attendance for a booked slot
static Future<void> markTrainerSlotAttendance({
  required String bookingId,
  required String trainerId,
  required String weeklySlotId,
  required String bookingDate,
  required bool isDone,
}) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return;
    debugPrint('\x1B[33m[API] UPSERT trainer_slot_attendance | booking: $bookingId | done: $isDone\x1B[0m');
    await client.from('trainer_slot_attendance').upsert({
      'user_id': userId,
      'booking_id': bookingId,
      'trainer_id': trainerId,
      'weekly_slot_id': weeklySlotId,
      'booking_date': bookingDate,
      'status': isDone ? 'done' : 'joined',
      'marked_done_at': isDone ? DateTime.now().toIso8601String() : null,
    }, onConflict: 'user_id,booking_id');
    // Also update booking status
    await client
        .from('trainer_slot_bookings')
        .update({'status': isDone ? 'attended' : 'confirmed'})
        .eq('id', bookingId);
    debugPrint('\x1B[32m[API] 200 OK | Attendance marked\x1B[0m');
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | markTrainerSlotAttendance | $e\x1B[0m');
    rethrow;
  }
}

/// Get attendance for a booking
static Future<Map<String, dynamic>?> getTrainerSlotAttendance(
    String bookingId) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return null;
    final data = await client
        .from('trainer_slot_attendance')
        .select()
        .eq('user_id', userId)
        .eq('booking_id', bookingId)
        .maybeSingle();
    return data;
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getTrainerSlotAttendance | $e\x1B[0m');
    return null;
  }
}

/// Cancel a booking
static Future<void> cancelTrainerSlotBooking(String bookingId) async {
  try {
    debugPrint('\x1B[33m[API] PATCH trainer_slot_bookings | cancel: $bookingId\x1B[0m');
    await client
        .from('trainer_slot_bookings')
        .update({'status': 'cancelled'})
        .eq('id', bookingId);
    debugPrint('\x1B[32m[API] 200 OK | Booking cancelled\x1B[0m');
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | cancelTrainerSlotBooking | $e\x1B[0m');
    rethrow;
  }
}

// ─────────────────────────────────────────────
// TRAINER CONTENT PAGE
// ─────────────────────────────────────────────

static Future<List<Map<String, dynamic>>> getTrainerVideos(String trainerId) async {
  try {
    debugPrint('\x1B[33m[API] GET trainer_content_videos | trainer: $trainerId\x1B[0m');
    final data = await client
        .from('trainer_content_videos')
        .select()
        .eq('trainer_id', trainerId)
        .eq('is_active', true)
        .order('order_number', ascending: true);
    debugPrint('\x1B[32m[API] 200 OK | Videos: ${data.length}\x1B[0m');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getTrainerVideos | $e\x1B[0m');
    return [];
  }
}

static Future<List<Map<String, dynamic>>> getTrainerImages(String trainerId) async {
  try {
    debugPrint('\x1B[33m[API] GET trainer_content_images | trainer: $trainerId\x1B[0m');
    final data = await client
        .from('trainer_content_images')
        .select()
        .eq('trainer_id', trainerId)
        .eq('is_active', true)
        .order('order_number', ascending: true);
    debugPrint('\x1B[32m[API] 200 OK | Images: ${data.length}\x1B[0m');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getTrainerImages | $e\x1B[0m');
    return [];
  }
}

static Future<List<Map<String, dynamic>>> getTrainerDietPlans(String trainerId) async {
  try {
    debugPrint('\x1B[33m[API] GET trainer_diet_plans | trainer: $trainerId\x1B[0m');
    final data = await client
        .from('trainer_diet_plans')
        .select()
        .eq('trainer_id', trainerId)
        .eq('is_active', true)
        .order('order_number', ascending: true);
    debugPrint('\x1B[32m[API] 200 OK | DietPlans: ${data.length}\x1B[0m');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getTrainerDietPlans | $e\x1B[0m');
    return [];
  }
}

static Future<List<Map<String, dynamic>>> getTrainerDietItems(String planId) async {
  try {
    debugPrint('\x1B[33m[API] GET trainer_diet_items | plan: $planId\x1B[0m');
    final data = await client
        .from('trainer_diet_items')
        .select()
        .eq('plan_id', planId)
        .order('order_number', ascending: true);
    debugPrint('\x1B[32m[API] 200 OK | DietItems: ${data.length}\x1B[0m');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getTrainerDietItems | $e\x1B[0m');
    return [];
  }
}

static Future<List<Map<String, dynamic>>> getTrainerGuideSteps(String trainerId) async {
  try {
    debugPrint('\x1B[33m[API] GET trainer_guide_steps | trainer: $trainerId\x1B[0m');
    final data = await client
        .from('trainer_guide_steps')
        .select()
        .eq('trainer_id', trainerId)
        .eq('is_active', true)
        .order('step_number', ascending: true);
    debugPrint('\x1B[32m[API] 200 OK | GuideSteps: ${data.length}\x1B[0m');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getTrainerGuideSteps | $e\x1B[0m');
    return [];
  }
}

static Future<Map<String, dynamic>?> getTrainerGuideLog({
  required String stepId,
  required String date,
}) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return null;
    final data = await client
        .from('trainer_guide_logs')
        .select()
        .eq('user_id', userId)
        .eq('step_id', stepId)
        .eq('scheduled_date', date)
        .maybeSingle();
    return data;
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getTrainerGuideLog | $e\x1B[0m');
    return null;
  }
}

static Future<List<Map<String, dynamic>>> getTrainerGuideLogsForDate({
  required String trainerId,
  required String date,
}) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final data = await client
        .from('trainer_guide_logs')
        .select()
        .eq('user_id', userId)
        .eq('trainer_id', trainerId)
        .eq('scheduled_date', date);
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getTrainerGuideLogsForDate | $e\x1B[0m');
    return [];
  }
}

static Future<void> upsertTrainerGuideLog({
  required String stepId,
  required String trainerId,
  required String bookingId,
  required String date,
  required bool isDone,
}) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return;
    debugPrint('\x1B[33m[API] UPSERT trainer_guide_logs | step: $stepId | done: $isDone\x1B[0m');
    await client.from('trainer_guide_logs').upsert({
      'user_id': userId,
      'trainer_id': trainerId,
      'step_id': stepId,
      'booking_id': bookingId,
      'scheduled_date': date,
      'is_done': isDone,
      'completed_at': isDone ? DateTime.now().toIso8601String() : null,
    }, onConflict: 'user_id,step_id,scheduled_date');
    debugPrint('\x1B[32m[API] 200 OK | Guide log upserted\x1B[0m');
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | upsertTrainerGuideLog | $e\x1B[0m');
    rethrow;
  }
}

// ─────────────────────────────────────────────
// BOOKINGS PAGE — all bookings combined
// ─────────────────────────────────────────────

static Future<Map<String, dynamic>> getAllMyBookings() async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return {};

    // Trainer slot bookings
    final trainerBookings = await client
        .from('trainer_slot_bookings')
        .select('*, fitness_trainers(id, name, image_url, training_type, rating, experience, phone_number)')
.eq('user_id', userId)
.order('booking_date', ascending: true);

    // Yoga session bookings
    final yogaBookings = await client
        .from('yoga_session_bookings')
        .select('*, yoga_instructors(name, image_url, specialty)')
        .eq('user_id', userId)
        .order('start_date', ascending: false);

    debugPrint('\x1B[32m[API] 200 OK | AllBookings | trainer: ${trainerBookings.length} yoga: ${yogaBookings.length}\x1B[0m');

    return {
      'trainer': List<Map<String, dynamic>>.from(trainerBookings),
      'yoga': List<Map<String, dynamic>>.from(yogaBookings),
    };
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getAllMyBookings | $e\x1B[0m');
    return {'trainer': [], 'yoga': []};
  }
}

// Add trainer content to feed
static Future<void> addTrainerContentToFeed({
  required String trainerId,
  required String bookingId,
}) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return;
    debugPrint('\x1B[33m[API] ADD trainer content to feed | booking: $bookingId\x1B[0m');
    await client.from('user_feed_classes').upsert({
      'user_id': userId,
      'class_id': bookingId,
      'instructor_id': trainerId,
      'content_type': 'trainer',
      'trainer_id': trainerId,
      'booking_id': bookingId,
    }, onConflict: 'user_id,class_id');
    debugPrint('\x1B[32m[API] 200 OK | Trainer content added to feed\x1B[0m');
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | addTrainerContentToFeed | $e\x1B[0m');
    rethrow;
  }
}

static Future<void> removeTrainerContentFromFeed({
  required String bookingId,
}) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return;
    await client
        .from('user_feed_classes')
        .delete()
        .eq('user_id', userId)
        .eq('class_id', bookingId)
        .eq('content_type', 'trainer');
    debugPrint('\x1B[32m[API] 200 OK | Trainer content removed from feed\x1B[0m');
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | removeTrainerContentFromFeed | $e\x1B[0m');
    rethrow;
  }
}

static Future<bool> isTrainerContentInFeed(String bookingId) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return false;
    final data = await client
        .from('user_feed_classes')
        .select('id')
        .eq('user_id', userId)
        .eq('class_id', bookingId)
        .eq('content_type', 'trainer')
        .maybeSingle();
    return data != null;
  } catch (e) {
    return false;
  }
}

static Future<void> markAllStepsCompleted({
  required String bookingId,
}) async {
  try {
    debugPrint('\x1B[33m[API] MARK all steps completed | booking: $bookingId\x1B[0m');
    await client.from('trainer_slot_bookings').update({
      'all_steps_completed': true,
      'steps_completed_at': DateTime.now().toIso8601String(),
    }).eq('id', bookingId);
    debugPrint('\x1B[32m[API] 200 OK | All steps marked completed\x1B[0m');
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | markAllStepsCompleted | $e\x1B[0m');
    rethrow;
  }
}

static Future<List<Map<String, dynamic>>> getTrainerFeedItems() async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final data = await client
        .from('user_feed_classes')
        .select('*, fitness_trainers(name, image_url, training_type)')
        .eq('user_id', userId)
        .eq('content_type', 'trainer')
        .order('added_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getTrainerFeedItems | $e\x1B[0m');
    return [];
  }
}

}