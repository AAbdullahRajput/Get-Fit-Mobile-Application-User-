import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:get_fit/Services/notification_service.dart';

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

  static Future<Map<String, dynamic>?> getTrainerById(String trainerId) async {
    try {
      debugPrint('\x1B[33m[API] GET /rest/v1/fitness_trainers | id: $trainerId\x1B[0m');
      final data = await client
          .from('fitness_trainers')
          .select()
          .eq('id', trainerId)
          .maybeSingle();
      debugPrint('\x1B[32m[API] 200 OK | Trainer: ${data != null ? 'found' : 'not found'}\x1B[0m');
      return data;
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getTrainerById | $e\x1B[0m');
      return null;
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

      await updateStreak();

    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | markExerciseDone | $e\x1B[0m');
      rethrow;
    }
  }


// ─────────────────────────────────────────────
// STREAK TRACKING
// ─────────────────────────────────────────────

static Future<void> updateStreak() async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final todayStr = todayDate.toIso8601String().substring(0, 10);

    final setup = await client
        .from('user_setup')
        .select('current_streak, longest_streak, last_active_date')
        .eq('id', userId)
        .maybeSingle();

    final lastActiveStr = setup?['last_active_date'] as String?;
    int currentStreak = (setup?['current_streak'] as int?) ?? 0;
    int longestStreak = (setup?['longest_streak'] as int?) ?? 0;

    if (lastActiveStr == null) {
      currentStreak = 1;
    } else {
      final lastActive = DateTime.parse(lastActiveStr);
      final daysDiff = todayDate.difference(lastActive).inDays;

      if (daysDiff == 0) {
        debugPrint('\x1B[33m[STREAK] Already logged today — no change\x1B[0m');
        return;
      } else if (daysDiff == 1) {
        currentStreak += 1;
      } else {
        currentStreak = 1;
      }
    }

    if (currentStreak > longestStreak) longestStreak = currentStreak;

    await client.from('user_setup').update({
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_active_date': todayStr,
    }).eq('id', userId);

    debugPrint('\x1B[32m[STREAK] Updated | current: $currentStreak | longest: $longestStreak\x1B[0m');
  } catch (e) {
    debugPrint('\x1B[31m[STREAK] ERROR | updateStreak | $e\x1B[0m');
  }
}

static Future<Map<String, dynamic>> getStreakInfo() async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return {'current_streak': 0, 'longest_streak': 0};
    final data = await client
        .from('user_setup')
        .select('current_streak, longest_streak, last_active_date')
        .eq('id', userId)
        .maybeSingle();
    return {
      'current_streak': data?['current_streak'] ?? 0,
      'longest_streak': data?['longest_streak'] ?? 0,
      'last_active_date': data?['last_active_date'],
    };
  } catch (e) {
    debugPrint('\x1B[31m[STREAK] ERROR | getStreakInfo | $e\x1B[0m');
    return {'current_streak': 0, 'longest_streak': 0};
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

    // ── Yoga sessions (no calories — course/guide content only) ──
    for (final row in yogaRows) {
      final dateStr = row['scheduled_date'] as String?;
      if (dateStr == null) continue;
      final key = dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr;
      if (!buckets.containsKey(key)) continue;
      final mins  = (row['session_duration_minutes'] as num? ?? 0).toInt();
      final secs  = mins * 60;
      final cls   = row['instructor_paid_classes'] as Map<String, dynamic>?;
      final title = cls?['title'] as String? ?? 'Yoga Class';
      final image = cls?['image_url'] as String? ?? '';
      buckets[key]!['totalSecs'] = (buckets[key]!['totalSecs'] as int) + secs;
      (buckets[key]!['yogaSessions'] as List).add({
        'title': title,
        'image': image,
        'kcal':  0,
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
// TRAINER SLOTS (calendar/inventory) & APPOINTMENTS
// ─────────────────────────────────────────────

static Future<List<Map<String, dynamic>>> getTrainerAvailableSlots(
    String trainerId) async {
  try {
    final now = DateTime.now();
    final today = now.toIso8601String().substring(0, 10);
    debugPrint('\x1B[33m[API] GET trainer_slots | trainer: $trainerId\x1B[0m');
    final data = await client
        .from('trainer_slots')
        .select()
        .eq('trainer_id', trainerId)
        .eq('is_active', true)
        .eq('status', 'available')
        .gte('slot_date', today)
        .order('slot_date', ascending: true)
        .order('start_time', ascending: true);

    // Filter out slots that are today but whose start_time has already passed.
    final filtered = List<Map<String, dynamic>>.from(data).where((slot) {
      final slotDate = slot['slot_date'] as String;
      if (slotDate != today) return true; // future date — always keep
      final startStr = slot['start_time'] as String;
      final parts = startStr.split(':');
      final slotStart = DateTime(
          now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      return slotStart.isAfter(now); // only keep if it hasn't started yet
    }).toList();

    debugPrint('\x1B[32m[API] 200 OK | AvailableSlots: ${filtered.length} (raw: ${data.length})\x1B[0m');
    return filtered;
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getTrainerAvailableSlots | $e\x1B[0m');
    return [];
  }
}
/// so users can see what's taken vs open — instead of booked slots
/// silently disappearing.
static Future<List<Map<String, dynamic>>> getTrainerCalendarSlots(
    String trainerId) async {
  try {
    final now = DateTime.now();
    final today = now.toIso8601String().substring(0, 10);
    debugPrint('\x1B[33m[API] GET trainer_slots (calendar) | trainer: $trainerId\x1B[0m');
    final data = await client
        .from('trainer_slots')
        .select()
        .eq('trainer_id', trainerId)
        .or('status.eq.available,status.eq.booked')
        .gte('slot_date', today)
        .order('slot_date', ascending: true)
        .order('start_time', ascending: true);

    final filtered = List<Map<String, dynamic>>.from(data).where((slot) {
      final slotDate = slot['slot_date'] as String;
      final status = slot['status'] as String? ?? 'available';
      if (slotDate != today) return true;
      if (status != 'available') return true; // show past-today booked slots too
      final startStr = slot['start_time'] as String;
      final parts = startStr.split(':');
      final slotStart = DateTime(
          now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      return slotStart.isAfter(now); // hide only expired *available* slots
    }).toList();

    debugPrint('\x1B[32m[API] 200 OK | CalendarSlots: ${filtered.length}\x1B[0m');
    return filtered;
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getTrainerCalendarSlots | $e\x1B[0m');
    return [];
  }
}

/// Get ALL slots for a trainer (available + booked), useful for a
/// trainer-facing schedule view if you build one later.
static Future<List<Map<String, dynamic>>> getTrainerAllSlots(
    String trainerId) async {
  try {
    final data = await client
        .from('trainer_slots')
        .select()
        .eq('trainer_id', trainerId)
        .order('slot_date', ascending: true)
        .order('start_time', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getTrainerAllSlots | $e\x1B[0m');
    return [];
  }
}

/// Book a specific slot: locks the slot (is_active=false, status='booked')
/// and creates the appointment record.
static Future<Map<String, dynamic>> bookTrainerSlot({
  required String slotId,
  required String trainerId,
  required String slotDate,
  required String startTime,
  required String endTime,
  required double price,
  String notes = '',
}) async {
  final userId = currentUser?.id;
  if (userId == null) throw Exception('Not logged in');

  // Re-check the slot is still open (avoid race condition with another buyer)
  final slot = await client
      .from('trainer_slots')
      .select('is_active, status')
      .eq('id', slotId)
      .single();
  if (slot['is_active'] != true || slot['status'] != 'available') {
    throw Exception('slot_unavailable');
  }

  final profile = await getUserProfile();
  final userName = profile?['username'] as String? ?? 'User';
  final userEmail = currentUser?.email ?? '';

  debugPrint('\x1B[33m[API] Booking slot: $slotId\x1B[0m');

  // 1. Lock the slot
  await client.from('trainer_slots').update({
    'is_active': false,
    'status': 'booked',
    'booked_by_user_id': userId,
    'booked_by_name': userName,
    'booked_by_email': userEmail,
  }).eq('id', slotId);

  // 2. Create the appointment record
  final result = await client
      .from('trainer_appointments')
      .insert({
        'slot_id': slotId,
        'trainer_id': trainerId,
        'user_id': userId,
        'appointment_date': slotDate,
        'start_time': startTime,
        'end_time': endTime,
        'user_name': userName,
        'user_email': userEmail,
        'price': price,
        'status': 'confirmed',
        'notes': notes,
      })
      .select()
      .single();

  debugPrint('\x1B[32m[API] 200 OK | Slot booked, appointment created\x1B[0m');

  // Schedule 1-day / 2-hour / 5-minute reminders for this appointment.
  try {
    final appointmentId = result['id'] as String;
    final trainerData = await client
        .from('fitness_trainers')
        .select('name')
        .eq('id', trainerId)
        .maybeSingle();
    final trainerName = trainerData?['name'] as String? ?? 'your trainer';
    final startParts = startTime.split(':');
    final d = DateTime.parse(slotDate);
    final startDateTime = DateTime(
        d.year, d.month, d.day, int.parse(startParts[0]), int.parse(startParts[1]));
    await NotificationService.scheduleAppointmentReminders(
      appointmentId: appointmentId,
      trainerName: trainerName,
      startDateTime: startDateTime,
    );
  } catch (e) {
    debugPrint('\x1B[31m[NOTIF] ERROR | scheduling appointment reminders | $e\x1B[0m');
  }

  return Map<String, dynamic>.from(result);
}

/// Cancel an appointment — reopens the slot for others to book.
static Future<void> cancelAppointment(String appointmentId) async {
  try {
    await NotificationService.cancelAppointmentReminders(appointmentId);
    final appt = await client
        .from('trainer_appointments')
        .select('slot_id')
        .eq('id', appointmentId)
        .single();

    await client
        .from('trainer_appointments')
        .update({'status': 'cancelled'})
        .eq('id', appointmentId);

    final slotId = appt['slot_id'] as String?;
    if (slotId != null) {
      await client.from('trainer_slots').update({
        'is_active': true,
        'status': 'available',
        'booked_by_user_id': null,
        'booked_by_name': null,
        'booked_by_email': null,
      }).eq('id', slotId);
    }
    debugPrint('\x1B[32m[API] 200 OK | Appointment cancelled, slot reopened\x1B[0m');
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | cancelAppointment | $e\x1B[0m');
    rethrow;
  }
}

/// Mark an appointment as attended (also flips the slot's status).
static Future<void> markAppointmentAttended(String appointmentId) async {
  try {
    await NotificationService.cancelAppointmentReminders(appointmentId);
    final appt = await client
        .from('trainer_appointments')
        .select('slot_id')
        .eq('id', appointmentId)
        .single();

    await client
        .from('trainer_appointments')
        .update({'status': 'attended'})
        .eq('id', appointmentId);

    final slotId = appt['slot_id'] as String?;
    if (slotId != null) {
      await client
          .from('trainer_slots')
          .update({'status': 'attended'})
          .eq('id', slotId);
    }
    debugPrint('\x1B[32m[API] 200 OK | Appointment marked attended\x1B[0m');
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | markAppointmentAttended | $e\x1B[0m');
    rethrow;
  }
}

/// Get all appointments for current user
static Future<List<Map<String, dynamic>>> getMyTrainerAppointments() async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final data = await client
        .from('trainer_appointments')
        .select(
            '*, fitness_trainers(id, name, image_url, training_type, rating, experience, phone_number)')
        .eq('user_id', userId)
        .order('appointment_date', ascending: true)
        .order('start_time', ascending: true);
    debugPrint('\x1B[32m[API] 200 OK | MyAppointments: ${data.length}\x1B[0m');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getMyTrainerAppointments | $e\x1B[0m');
    return [];
  }
}

/// Get upcoming (today + future, confirmed) appointments for current user
static Future<List<Map<String, dynamic>>> getUpcomingTrainerAppointments() async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final data = await client
        .from('trainer_appointments')
        .select(
            '*, fitness_trainers(id, name, image_url, training_type, rating, experience, phone_number)')
        .eq('user_id', userId)
        .eq('status', 'confirmed')
        .gte('appointment_date', today)
        .order('appointment_date', ascending: true)
        .order('start_time', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getUpcomingTrainerAppointments | $e\x1B[0m');
    return [];
  }
}


// ─────────────────────────────────────────────
// BOOKINGS PAGE — all bookings combined
// ─────────────────────────────────────────────

static Future<Map<String, dynamic>> getAllMyBookings() async {
  try {
    final trainerBookings = await getMyTrainerAppointments();
    debugPrint('\x1B[32m[API] 200 OK | AllBookings | trainer: ${trainerBookings.length}\x1B[0m');
    return {'trainer': trainerBookings};
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getAllMyBookings | $e\x1B[0m');
    return {'trainer': []};
  }
}




static Future<String> createPaymentIntent(double amount) async {
  try {
    final response = await client.functions.invoke(
      'create-payment-intent',
      body: {'amount': amount, 'currency': 'usd'},
    );
    final clientSecret = response.data['clientSecret'] as String;
    return clientSecret;
  } catch (e) {
    debugPrint('\x1B[31m[STRIPE] ERROR | createPaymentIntent | $e\x1B[0m');
    rethrow;
  }
}

static Future<List<Map<String, dynamic>>> getAllYogaClasses({int page = 0, int pageSize = 100}) async {
  try {
    debugPrint('\x1B[36m[API] GET /rest/v1/yoga_classes (all, unfiltered)\x1B[0m');
    final data = await client
        .from('yoga_classes')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: true)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    debugPrint('\x1B[32m[API] 200 OK | AllYogaClasses: ${data.length}\x1B[0m');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getAllYogaClasses | $e\x1B[0m');
    return [];
  }
}
static Future<List<Map<String, dynamic>>> getAllPaidClasses({int page = 0, int pageSize = 100}) async {
  try {
    final data = await client
        .from('instructor_paid_classes')
        .select('*, yoga_instructors(name)')
        .eq('is_active', true)
        .order('created_at', ascending: true)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getAllPaidClasses | $e\x1B[0m');
    return [];
  }
}

static Future<bool> hasPurchasedClass(String classId) async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return false;
    final data = await client
        .from('user_class_purchases')
        .select('id')
        .eq('user_id', userId)
        .eq('class_id', classId)
        .maybeSingle();
    return data != null;
  } catch (e) {
    return false;
  }
}

static Future<Set<String>> getPurchasedClassIds() async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return {};
    final data = await client
        .from('user_class_purchases')
        .select('class_id')
        .eq('user_id', userId);
    return Set<String>.from(data.map((r) => r['class_id']));
  } catch (e) {
    return {};
  }
}

static Future<void> purchaseClass({
  required String classId,
  required String instructorId,
  required double price,
}) async {
  final userId = currentUser?.id;
  if (userId == null) throw Exception('Not logged in');
  await client.from('user_class_purchases').insert({
    'user_id': userId,
    'class_id': classId,
    'instructor_id': instructorId,
    'price_paid': price,
  });
}

// ─────────────────────────────────────────────
  // NEWSFEED
  // ─────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getNewsfeedItems({
    String? category,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      debugPrint('\x1B[33m[API] GET /rest/v1/newsfeed_items | category: $category\x1B[0m');
      var query = client.from('newsfeed_items').select();
      if (category != null) {
        query = query.eq('category', category);
      }
      final data = await query
          .order('published_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);
      debugPrint('\x1B[32m[API] 200 OK | NewsfeedItems: ${data.length}\x1B[0m');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getNewsfeedItems | $e\x1B[0m');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchNewsfeedItems(String query) async {
    try {
      final data = await client
          .from('newsfeed_items')
          .select()
          .ilike('title', '%$query%')
          .order('published_at', ascending: false)
          .limit(30);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | searchNewsfeedItems | $e\x1B[0m');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // SAVED NEWSFEED ITEMS (Added Feed)
  // ─────────────────────────────────────────────

  static Future<void> saveNewsfeedItem(String newsfeedItemId) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;
      debugPrint('\x1B[33m[API] POST /rest/v1/saved_newsfeed_items | item: $newsfeedItemId\x1B[0m');
      await client.from('saved_newsfeed_items').upsert({
        'user_id': userId,
        'newsfeed_item_id': newsfeedItemId,
      }, onConflict: 'user_id,newsfeed_item_id');
      debugPrint('\x1B[32m[API] 200 OK | Saved to feed\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | saveNewsfeedItem | $e\x1B[0m');
      rethrow;
    }
  }

  static Future<void> unsaveNewsfeedItem(String newsfeedItemId) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;
      debugPrint('\x1B[33m[API] DELETE /rest/v1/saved_newsfeed_items | item: $newsfeedItemId\x1B[0m');
      await client
          .from('saved_newsfeed_items')
          .delete()
          .eq('user_id', userId)
          .eq('newsfeed_item_id', newsfeedItemId);
      debugPrint('\x1B[32m[API] 200 OK | Removed from feed\x1B[0m');
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | unsaveNewsfeedItem | $e\x1B[0m');
      rethrow;
    }
  }

  static Future<Set<String>> getSavedNewsfeedItemIds() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return {};
      final data = await client
          .from('saved_newsfeed_items')
          .select('newsfeed_item_id')
          .eq('user_id', userId);
      return Set<String>.from(data.map((r) => r['newsfeed_item_id'].toString()));
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getSavedNewsfeedItemIds | $e\x1B[0m');
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> getSavedNewsfeedItems() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];
      debugPrint('\x1B[33m[API] GET /rest/v1/saved_newsfeed_items (with items)\x1B[0m');
      final data = await client
          .from('saved_newsfeed_items')
          .select('added_at, newsfeed_items(*)')
          .eq('user_id', userId)
          .order('added_at', ascending: false);
      debugPrint('\x1B[32m[API] 200 OK | SavedNewsfeedItems: ${data.length}\x1B[0m');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('\x1B[31m[API] ERROR | getSavedNewsfeedItems | $e\x1B[0m');
      return [];
    }
  }

static Future<List<Map<String, dynamic>>> getMyPurchasedCourses() async {
  try {
    final userId = currentUser?.id;
    if (userId == null) return [];
    debugPrint('\x1B[33m[API] GET user_class_purchases (with course details)\x1B[0m');
    final data = await client
        .from('user_class_purchases')
        .select('*, instructor_paid_classes(*, yoga_instructors(name, specialty, image_url))')
        .eq('user_id', userId)
        .order('purchased_at', ascending: false);
    debugPrint('\x1B[32m[API] 200 OK | PurchasedCourses: ${data.length}\x1B[0m');
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('\x1B[31m[API] ERROR | getMyPurchasedCourses | $e\x1B[0m');
    return [];
  }
}

}