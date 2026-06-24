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
          .select('*, fitness_trainers(name, training_type, image_url)')
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
      final reviews = await getYogaInstructorReviews(instructorId);
      if (reviews.isNotEmpty) {
        final avg = reviews
                .map((r) => (r['rating'] as num).toDouble())
                .reduce((a, b) => a + b) /
            reviews.length;
        await client
            .from('yoga_instructors')
            .update({'rating': double.parse(avg.toStringAsFixed(1))})
            .eq('id', instructorId);
      }
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
      final reviews = await getYogaInstructorReviews(instructorId);
      if (reviews.isEmpty) {
        await client.from('yoga_instructors').update({'rating': 0.0}).eq('id', instructorId);
      } else {
        final avg = reviews
                .map((r) => (r['rating'] as num).toDouble())
                .reduce((a, b) => a + b) /
            reviews.length;
        await client
            .from('yoga_instructors')
            .update({'rating': double.parse(avg.toStringAsFixed(1))})
            .eq('id', instructorId);
      }
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

      // 1. Challenge progress
      final challengeRows = await client
          .from('challenge_user_progress')
          .select('calories_burned, time_spent_seconds, completed_at')
          .eq('user_id', userId)
          .eq('is_completed', true)
          .gte('completed_at', start.toIso8601String());

      // 2. Gym workout sessions (graceful if table missing)
      List<dynamic> gymRows = [];
      try {
        gymRows = await client
            .from('workout_sessions')
            .select('calories_burned, duration_seconds, completed_at')
            .eq('user_id', userId)
            .gte('completed_at', start.toIso8601String());
      } catch (_) {
        debugPrint('\x1B[33m[API] workout_sessions not found — skipping\x1B[0m');
      }

      // Build day buckets
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

      // Convert to list of maps
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
}