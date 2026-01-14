/// A simple in-memory cache service for API responses
/// This dramatically improves perceived performance by:
/// 1. Instantly showing cached data while fresh data loads in background
/// 2. Reducing redundant API calls
/// 3. Enabling offline-first experience for recently viewed content
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Cache storage with expiration
  final Map<String, _CacheEntry> _cache = {};

  // Default cache duration: 5 minutes (enough for most use cases)
  static const Duration defaultCacheDuration = Duration(minutes: 5);

  // Shorter cache for frequently changing data
  static const Duration shortCacheDuration = Duration(minutes: 1);

  // Longer cache for static data like tags, communities
  static const Duration longCacheDuration = Duration(minutes: 15);

  /// Get cached data if available and not expired
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T?;
  }

  /// Store data in cache with optional custom duration
  void set<T>(String key, T data, {Duration? duration}) {
    _cache[key] = _CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(duration ?? defaultCacheDuration),
    );
  }

  /// Check if cache has valid (non-expired) entry
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  /// Invalidate a specific cache entry
  void invalidate(String key) {
    _cache.remove(key);
  }

  /// Invalidate all cache entries matching a pattern
  void invalidatePattern(String pattern) {
    _cache.removeWhere((key, _) => key.contains(pattern));
  }

  /// Clear all cache
  void clearAll() {
    _cache.clear();
  }

  /// Clear expired entries (call periodically if needed)
  void clearExpired() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  // === Cache Keys ===
  // Centralized key generation for consistency

  static String questionsKey(
          {String sort = 'newest', String tag = '', String search = ''}) =>
      'questions_${sort}_${tag}_$search';

  static String questionDetailKey(String id, {String? userId}) =>
      'question_${id}_${userId ?? "anon"}';

  static String profileKey(String userId) => 'profile_$userId';

  static String userQuestionsKey(String userId) => 'user_questions_$userId';

  static String userAnswersKey(String userId) => 'user_answers_$userId';

  static String communitiesKey() => 'communities';

  static String communityDetailKey(String slug) => 'community_$slug';

  static String tagsKey() => 'tags';

  static String usersKey() => 'users';

  static String leaderboardKey() => 'leaderboard';

  static String bookmarksKey(String userId) => 'bookmarks_$userId';

  static String notificationsKey(String userId) => 'notifications_$userId';

  static String reputationKey(String userId) => 'reputation_$userId';
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  _CacheEntry({required this.data, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
