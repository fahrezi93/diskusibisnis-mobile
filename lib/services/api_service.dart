import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/question.dart';
import '../models/user_profile.dart';
import '../models/answer.dart';
import '../models/notification.dart' as notif;
import '../models/community.dart';
import '../models/ticket.dart';
import '../models/tag.dart' as tag_model;
import '../models/reputation_activity.dart';
import 'cache_service.dart';

class ApiService {
  // URL is now configured in AppConfig - toggle isProduction to switch
  static String get baseUrl => AppConfig.apiUrl;

  // Cache service for instant data loading
  final CacheService _cache = CacheService();

  // Reusable HTTP client for better performance (connection pooling)
  static final http.Client _client = http.Client();

  // Timeout duration for API calls
  static const Duration _timeout = Duration(seconds: 15);

  // Reset password with token
  Future<bool> resetPassword(String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal me-reset password');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Question>> getQuestions(
      {String search = '',
      String tag = '',
      String sort = 'newest',
      int limit = 10,
      int page = 1,
      bool useCache = true}) async {
    final cacheKey =
        CacheService.questionsKey(sort: sort, tag: tag, search: search);

    // Return cached data if available and caching is enabled
    if (useCache) {
      final cached = _cache.get<List<Question>>(cacheKey);
      if (cached != null) {
        // Trigger background refresh
        _refreshQuestionsInBackground(
            search: search, tag: tag, sort: sort, limit: limit, page: page);
        return cached;
      }
    }

    try {
      final queryParameters = {
        'search': search,
        'tag': tag,
        'sort': sort,
        'limit': limit.toString(),
        'page': page.toString(),
      };

      final uri = Uri.parse('$baseUrl/questions')
          .replace(queryParameters: queryParameters);
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> list = [];

        if (data is Map && data.containsKey('data')) {
          if (data['data'] is Map && data['data'].containsKey('questions')) {
            list = data['data']['questions'];
          } else if (data['data'] is List) {
            list = data['data'];
          }
        } else if (data is List) {
          list = data;
        }

        final questions = list.map((json) => Question.fromJson(json)).toList();

        // Cache the results
        _cache.set(cacheKey, questions);

        return questions;
      } else {
        throw Exception('Gagal mengambil data: ${response.statusCode}');
      }
    } catch (e) {
      // If network fails, try to return stale cache
      final staleCache = _cache.get<List<Question>>(cacheKey);
      if (staleCache != null) return staleCache;
      throw Exception('Error koneksi: $e');
    }
  }

  // Background refresh for questions (non-blocking)
  void _refreshQuestionsInBackground({
    String search = '',
    String tag = '',
    String sort = 'newest',
    int limit = 10,
    int page = 1,
  }) {
    getQuestions(
        search: search,
        tag: tag,
        sort: sort,
        limit: limit,
        page: page,
        useCache: false);
  }

  Future<Map<String, dynamic>> getQuestionById(String id,
      {String? token, String? userId, bool useCache = true}) async {
    // Generate cache key specific to user if provided
    final cacheKey = CacheService.questionDetailKey(id, userId: userId);

    // Return cached data instantly if available
    if (useCache) {
      final cached = _cache.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) {
        print(
            '[ApiService] Returned cached question detail for $id (User: $userId)');
        // Trigger background refresh to get latest data
        _refreshQuestionDetailInBackground(id, token: token, userId: userId);
        return cached;
      }
    }

    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      print('[ApiService] Fetching question $id (Has Token: ${token != null})');

      final response = await _client
          .get(
            Uri.parse('$baseUrl/questions/$id'),
            headers: headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Map<String, dynamic> questionData;
        if (data is Map && data.containsKey('data')) {
          questionData = data['data'] as Map<String, dynamic>;
        } else {
          questionData = data as Map<String, dynamic>;
        }

        // Debug vote status
        print(
            '[ApiService] Question loaded. User Vote: ${questionData['user_vote']}');

        // Cache the question detail
        _cache.set(cacheKey, questionData,
            duration: CacheService.shortCacheDuration);

        return questionData;
      } else if (response.statusCode == 404) {
        throw Exception('Pertanyaan tidak ditemukan');
      } else {
        throw Exception('Gagal mengambil data: ${response.statusCode}');
      }
    } catch (e) {
      print('[ApiService] Error fetching question: $e');
      // If network fails, try to return stale cache
      final staleCache = _cache.get<Map<String, dynamic>>(cacheKey);
      if (staleCache != null) return staleCache;
      throw Exception('Error koneksi: $e');
    }
  }

  // Background refresh for question detail
  void _refreshQuestionDetailInBackground(String id,
      {String? token, String? userId}) {
    getQuestionById(id, token: token, userId: userId, useCache: false);
  }

  // Vote on question or answer
  Future<Map<String, dynamic>?> vote({
    required String token,
    String? questionId,
    String? answerId,
    required String voteType, // 'upvote' or 'downvote'
  }) async {
    try {
      // Backend expects targetType and targetId
      final String targetType = answerId != null ? 'answer' : 'question';
      final String targetId = answerId ?? questionId ?? '';

      print('[ApiService] Voting: $voteType on $targetType $targetId');

      final response = await http.post(
        Uri.parse('$baseUrl/votes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'targetType': targetType,
          'targetId': targetId,
          'voteType': voteType,
        }),
      );

      print('[ApiService] Vote response status: ${response.statusCode}');
      print('[ApiService] Vote response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>?;
      } else if (response.statusCode == 401) {
        throw Exception('Login diperlukan untuk vote');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal vote');
      }
    } catch (e) {
      print('[ApiService] Vote error: $e');
      rethrow;
    }
  }

  // Get user bookmarks
  Future<List<Map<String, dynamic>>> getBookmarks(
      {required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookmarks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('data')) {
          final dataObj = data['data'];
          if (dataObj is Map && dataObj.containsKey('bookmarks')) {
            return (dataObj['bookmarks'] as List?)
                    ?.map((e) => e as Map<String, dynamic>)
                    .toList() ??
                [];
          }
        }
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Login diperlukan');
      } else {
        throw Exception('Gagal mengambil data');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Create bookmark
  Future<bool> createBookmark({
    required String token,
    required String questionId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookmarks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'questionId': questionId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Login diperlukan untuk menyimpan');
      } else if (response.statusCode == 400) {
        // Already bookmarked, consider success or throw specific error
        return true;
      } else {
        return false;
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete bookmark
  Future<bool> deleteBookmark({
    required String token,
    required String questionId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/bookmarks?questionId=$questionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Login diperlukan');
      } else {
        return false;
      }
    } catch (e) {
      rethrow;
    }
  }

  // Create comment
  Future<bool> createComment({
    required String token,
    required String content,
    required String commentableType,
    required String commentableId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'content': content,
          'commentableType': commentableType,
          'commentableId': commentableId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Login diperlukan untuk berkomentar');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengirim komentar');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Post an answer to a question
  Future<Map<String, dynamic>?> postAnswer({
    required String token,
    required String questionId,
    required String content,
  }) async {
    try {
      // Backend expects POST /api/answers with questionId in body
      final response = await http.post(
        Uri.parse('$baseUrl/answers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'questionId': questionId,
          'content': content,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>?;
      } else if (response.statusCode == 401) {
        throw Exception('Login diperlukan untuk menjawab');
      } else {
        final error = json.decode(response.body);
        String errorMessage = error['message'] ?? 'Gagal mengirim jawaban';

        // Handle validation errors check
        if (error['errors'] != null &&
            error['errors'] is List &&
            (error['errors'] as List).isNotEmpty) {
          final firstError = (error['errors'] as List).first;
          if (firstError is Map && firstError['msg'] != null) {
            errorMessage = firstError['msg'];
          }
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Accept an answer (for question owner)
  Future<bool> acceptAnswer({
    required String token,
    required String answerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/answers/$answerId/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Login diperlukan');
      } else if (response.statusCode == 403) {
        throw Exception('Hanya pemilik pertanyaan yang bisa menerima jawaban');
      } else {
        return false;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserProfile?> getProfile(String id, {bool useCache = true}) async {
    final cacheKey = CacheService.profileKey(id);

    // Return cached profile instantly
    if (useCache) {
      final cached = _cache.get<UserProfile>(cacheKey);
      if (cached != null) {
        _refreshProfileInBackground(id);
        return cached;
      }
    }

    try {
      final response =
          await _client.get(Uri.parse('$baseUrl/users/$id')).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        var userData = data['data'];
        if (userData != null && userData is Map && userData['user'] != null) {
          userData = userData['user'];
        }
        // Handle case where data is directly the user object
        if (userData == null && data['user'] != null) {
          userData = data['user'];
        }

        final profile = UserProfile.fromJson(userData ?? {});
        _cache.set(cacheKey, profile);
        return profile;
      } else {
        throw Exception('Gagal mengambil profil: ${response.statusCode}');
      }
    } catch (e) {
      final staleCache = _cache.get<UserProfile>(cacheKey);
      if (staleCache != null) return staleCache;
      throw Exception('Error koneksi: $e');
    }
  }

  void _refreshProfileInBackground(String id) {
    getProfile(id, useCache: false);
  }

  Future<List<Question>> getUserQuestions(String userId) async {
    print('[ApiService] getUserQuestions called for userId: $userId');
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/users/$userId/questions'))
          .timeout(_timeout);

      print(
          '[ApiService] getUserQuestions response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> list = [];
        if (data is Map && data.containsKey('data')) {
          final innerData = data['data'];
          if (innerData is Map && innerData.containsKey('questions')) {
            list = innerData['questions'];
          } else if (innerData is List) {
            list = innerData;
          }
        } else if (data is Map && data.containsKey('questions')) {
          list = data['questions'];
        }
        print('[ApiService] getUserQuestions found ${list.length} questions');
        return list.map((json) => Question.fromJson(json)).toList();
      } else {
        print(
            '[ApiService] getUserQuestions failed with status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[ApiService] getUserQuestions error: $e');
      return [];
    }
  }

  Future<List<Answer>> getUserAnswers(String userId) async {
    print('[ApiService] getUserAnswers called for userId: $userId');
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/users/$userId/answers'))
          .timeout(_timeout);

      print(
          '[ApiService] getUserAnswers response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> list = [];
        if (data is Map && data.containsKey('data')) {
          final innerData = data['data'];
          if (innerData is Map && innerData.containsKey('answers')) {
            list = innerData['answers'];
          } else if (innerData is List) {
            list = innerData;
          }
        } else if (data is Map && data.containsKey('answers')) {
          list = data['answers'];
        }
        print('[ApiService] getUserAnswers found ${list.length} answers');
        return list.map((json) => Answer.fromJson(json)).toList();
      } else {
        print(
            '[ApiService] getUserAnswers failed with status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[ApiService] getUserAnswers error: $e');
      return [];
    }
  }

  Future<List<notif.Notification>> getNotifications({String? token}) async {
    print('[ApiService] getNotifications called');

    try {
      if (token == null) {
        print(
            '[ApiService] getNotifications: Token is NULL, returning empty list');
        return [];
      }

      print(
          '[ApiService] getNotifications: Making request to $baseUrl/notifications');
      print('[ApiService] getNotifications: Token length: ${token.length}');

      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
          '[ApiService] getNotifications: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> list = [];

        print('[ApiService] getNotifications: Parsing response data...');

        if (data is Map && data.containsKey('data')) {
          final innerData = data['data'];
          if (innerData is Map && innerData.containsKey('notifications')) {
            list = innerData['notifications'];
            print(
                '[ApiService] getNotifications: Found ${list.length} notifications in data.notifications');
          } else if (innerData is List) {
            list = innerData;
            print(
                '[ApiService] getNotifications: Found ${list.length} notifications in data (list)');
          } else {
            print(
                '[ApiService] getNotifications: data is Map but no notifications key. Keys: ${innerData is Map ? innerData.keys.toList() : "N/A"}');
          }
        } else if (data is Map && data.containsKey('notifications')) {
          list = data['notifications'];
          print(
              '[ApiService] getNotifications: Found ${list.length} notifications in root.notifications');
        } else if (data is List) {
          list = data;
          print(
              '[ApiService] getNotifications: Found ${list.length} notifications in root (list)');
        } else {
          print(
              '[ApiService] getNotifications: Unexpected response format. Type: ${data.runtimeType}');
          if (data is Map) {
            print(
                '[ApiService] getNotifications: Root keys: ${data.keys.toList()}');
          }
        }

        final notifications =
            list.map((json) => notif.Notification.fromJson(json)).toList();
        print(
            '[ApiService] getNotifications: Successfully parsed ${notifications.length} notifications');
        return notifications;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Token expired or invalid
        print(
            '[ApiService] getNotifications: Auth error ${response.statusCode}, token may be expired');
        return [];
      } else {
        print(
            '[ApiService] getNotifications: Error response ${response.statusCode}: ${response.body}');
        throw Exception('Gagal mengambil notifikasi: ${response.statusCode}');
      }
    } catch (e) {
      print('[ApiService] getNotifications ERROR: $e');
      return [];
    }
  }

  Future<bool> markNotificationAsRead(String notificationId,
      {String? token}) async {
    try {
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error markNotificationAsRead: $e');
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead({String? token}) async {
    try {
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error markAllNotificationsAsRead: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId,
      {String? token}) async {
    try {
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleteNotification: $e');
      return false;
    }
  }

  Future<List<Community>> getCommunities({bool useCache = true}) async {
    final cacheKey = CacheService.communitiesKey();

    if (useCache) {
      final cached = _cache.get<List<Community>>(cacheKey);
      if (cached != null) {
        _refreshCommunitiesInBackground();
        return cached;
      }
    }

    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/communities'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json['data'] != null && json['data']['communities'] != null) {
          final List<dynamic> data = json['data']['communities'];
          final communities = data.map((e) => Community.fromJson(e)).toList();
          _cache.set(cacheKey, communities,
              duration: CacheService.longCacheDuration);
          return communities;
        }
      }
      return _cache.get<List<Community>>(cacheKey) ?? [];
    } catch (e) {
      print('Error getCommunities: $e');
      return _cache.get<List<Community>>(cacheKey) ?? [];
    }
  }

  void _refreshCommunitiesInBackground() {
    getCommunities(useCache: false);
  }

  Future<List<tag_model.TopicTag>> getTags(
      {String search = '', bool useCache = true}) async {
    final cacheKey = CacheService.tagsKey();

    if (useCache && search.isEmpty) {
      final cached = _cache.get<List<tag_model.TopicTag>>(cacheKey);
      if (cached != null) {
        _refreshTagsInBackground();
        return cached;
      }
    }

    try {
      final uri = Uri.parse('$baseUrl/tags').replace(queryParameters: {
        if (search.isNotEmpty) 'search': search,
      });
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json['data'] != null && json['data']['tags'] != null) {
          final List<dynamic> data = json['data']['tags'];
          final tags = data.map((e) => tag_model.TopicTag.fromJson(e)).toList();
          if (search.isEmpty) {
            _cache.set(cacheKey, tags,
                duration: CacheService.longCacheDuration);
          }
          return tags;
        }
      }
      return search.isEmpty
          ? (_cache.get<List<tag_model.TopicTag>>(cacheKey) ?? [])
          : [];
    } catch (e) {
      print('Error getTags: $e');
      return search.isEmpty
          ? (_cache.get<List<tag_model.TopicTag>>(cacheKey) ?? [])
          : [];
    }
  }

  void _refreshTagsInBackground() {
    getTags(useCache: false);
  }

  Future<List<UserProfile>> getUsers(
      {String search = '', bool useCache = true}) async {
    final cacheKey = CacheService.usersKey();

    if (useCache && search.isEmpty) {
      final cached = _cache.get<List<UserProfile>>(cacheKey);
      if (cached != null) {
        _refreshUsersInBackground();
        return cached;
      }
    }

    try {
      final uri = Uri.parse('$baseUrl/users').replace(queryParameters: {
        'sort': 'reputation',
        if (search.isNotEmpty) 'search': search,
      });

      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json['data'] != null && json['data']['users'] != null) {
          final List<dynamic> data = json['data']['users'];
          final users = data.map((e) => UserProfile.fromJson(e)).toList();
          if (search.isEmpty) {
            _cache.set(cacheKey, users);
          }
          return users;
        }
      }
      return search.isEmpty
          ? (_cache.get<List<UserProfile>>(cacheKey) ?? [])
          : [];
    } catch (e) {
      print('Error getUsers: $e');
      return search.isEmpty
          ? (_cache.get<List<UserProfile>>(cacheKey) ?? [])
          : [];
    }
  }

  void _refreshUsersInBackground() {
    getUsers(useCache: false);
  }

  Future<List<ReputationActivity>> getReputationActivities(
      String userId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/users/$userId/activities'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json['data'] != null && json['data']['activities'] != null) {
          final List<dynamic> data = json['data']['activities'];
          return data.map((e) => ReputationActivity.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getReputationActivities: $e');
      return [];
    }
  }

  Future<int> getUserRank(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId/rank'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json['data'] != null && json['data']['rank'] != null) {
          return json['data']['rank'] is int
              ? json['data']['rank']
              : int.tryParse(json['data']['rank'].toString()) ?? 0;
        }
      }
      return 0;
    } catch (e) {
      print('Error getUserRank: $e');
      return 0;
    }
  }

  Future<Community?> getCommunity(String slug, {String? token}) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/communities/$slug'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json['data'] != null && json['data']['community'] != null) {
          return Community.fromJson(json['data']['community']);
        }
      }
      return null;
    } catch (e) {
      print('Error getCommunity: $e');
      return null;
    }
  }

  Future<List<Question>> getCommunityQuestions(String slug) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/communities/$slug/questions'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> list = [];
        if (data is Map && data.containsKey('data')) {
          if (data['data'] is Map && data['data'].containsKey('questions')) {
            list = data['data']['questions'];
          } else if (data['data'] is List) {
            list = data['data'];
          }
        }
        return list.map((json) => Question.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getCommunityQuestions: $e');
      return [];
    }
  }

  // Create a new question
  Future<Map<String, dynamic>> createQuestion({
    required String token,
    required String title,
    required String content,
    List<String> tags = const [],
    List<String> images = const [],
    String? communitySlug,
  }) async {
    try {
      final body = {
        'title': title,
        'content': content,
        'tags': tags,
        'images': images,
        if (communitySlug != null) 'community_slug': communitySlug,
      };

      print('[ApiService] createQuestion payload: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/questions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      print(
          '[ApiService] createQuestion response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Login diperlukan untuk membuat pertanyaan');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal membuat pertanyaan');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> createSupportTicket({
    required String token,
    required String subject,
    required String message,
    required String name,
    required String email,
    String category = 'General',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/support'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'subject': subject,
          'message': message,
          'name': name,
          'email': email,
          'category': category,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal membuat tiket bantuan');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get my tickets
  Future<List<dynamic>> getMySupportTickets({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/support/my-tickets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['tickets'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Update question
  Future<Map<String, dynamic>> updateQuestion({
    required String id,
    required String token,
    String? title,
    String? content,
    List<String>? tags,
    List<String>? images,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/questions/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          if (title != null) 'title': title,
          if (content != null) 'content': content,
          if (tags != null) 'tags': tags,
          if (images != null) 'images': images,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Login diperlukan untuk mengedit pertanyaan');
      } else if (response.statusCode == 403) {
        throw Exception('Tidak memiliki izin untuk mengedit pertanyaan ini');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengedit pertanyaan');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete question
  Future<bool> deleteQuestion(String id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/questions/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Login diperlukan untuk menghapus pertanyaan');
      } else if (response.statusCode == 403) {
        throw Exception('Tidak memiliki izin untuk menghapus pertanyaan ini');
      } else {
        throw Exception('Gagal menghapus pertanyaan');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Create a new community
  Future<Map<String, dynamic>> createCommunity({
    required String token,
    required String name,
    required String description,
    required String category,
    String? location,
    String? avatarUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/communities'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'category': category,
          if (location != null && location.isNotEmpty) 'location': location,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Login diperlukan untuk membuat komunitas');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal membuat komunitas');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update community
  Future<Map<String, dynamic>> updateCommunity({
    required String token,
    required String slug,
    required String name,
    required String description,
    required String category,
    String? location,
    String? avatarUrl,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/communities/$slug'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'category': category,
          if (location != null) 'location': location,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Login diperlukan untuk mengedit komunitas');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengedit komunitas');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Join community
  Future<Map<String, dynamic>> joinCommunity(String slug, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/communities/$slug/join'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Login diperlukan untuk bergabung');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal bergabung dengan komunitas');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Leave community
  Future<Map<String, dynamic>> leaveCommunity(String slug, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/communities/$slug/leave'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Login diperlukan');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal keluar dari komunitas');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get community members (new method)
  Future<List<dynamic>> getCommunityMembers(String slug) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/communities/$slug/members'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data']['members'] != null) {
          return data['data']['members'] as List<dynamic>;
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Request password reset (send email with link)
  Future<void> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        // Success - email sent
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Email tidak ditemukan');
      } else {
        final error = json.decode(response.body);
        throw Exception(
            error['message'] ?? 'Gagal mengirim link reset password');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Search users for mention autocomplete
  Future<List<UserProfile>> searchUsersForMention(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mentions/search?q=$query'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> list = [];

        // Backend returns { success: true, users: [...] }
        if (data is Map && data.containsKey('users')) {
          list = data['users'];
        } else if (data is Map && data.containsKey('data')) {
          if (data['data'] is Map && data['data'].containsKey('users')) {
            list = data['data']['users'];
          } else if (data['data'] is List) {
            list = data['data'];
          }
        } else if (data is List) {
          list = data;
        }

        return list.map((json) => UserProfile.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error searchUsersForMention: $e');
      return [];
    }
  }

  // Upload image for question
  Future<String?> uploadImage({
    required String token,
    required String imagePath,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/upload/image');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('image', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        // Handle different response formats
        if (data is Map) {
          if (data.containsKey('data') && data['data'] is Map) {
            return data['data']['url'] ?? data['data']['imageUrl'];
          }
          return data['url'] ?? data['imageUrl'];
        }
        return null;
      } else {
        print('Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploadImage: $e');
      return null;
    }
  }

  // Update Answer
  Future<void> updateAnswer({
    required String id,
    required String token,
    required String content,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/answers/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'content': content}),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengupdate jawaban');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete Answer
  Future<void> deleteAnswer({
    required String id,
    required String token,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/answers/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal menghapus jawaban');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Create Ticket (for Reporting)
  Future<void> createTicket({
    required String name,
    required String email,
    required String subject,
    required String message,
    String category = 'general',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/support'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'subject': subject,
          'message': message,
          'category': category,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengirim laporan');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get My Tickets
  Future<List<Ticket>> getMyTickets(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/support/my-tickets?email=$email'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['data'] as List;
        return list.map((json) => Ticket.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error getMyTickets: $e');
      return [];
    }
  }

  // Get Ticket Detail
  Future<Ticket> getTicketByNumber(String ticketNumber, String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/support/ticket/$ticketNumber?email=$email'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Ticket.fromJson(data['data']);
      } else {
        throw Exception('Gagal memuat detail tiket');
      }
    } catch (e) {
      throw Exception('Error loading ticket: $e');
    }
  }

  // Reply to Ticket
  Future<void> replyTicket({
    required String ticketNumber,
    required String email,
    required String message,
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/support/ticket/$ticketNumber/reply'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'message': message,
          'name': name,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengirim balasan');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getUnreadNotificationCount(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications?limit=1'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        return int.tryParse(data['unreadCount']?.toString() ?? '0') ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
