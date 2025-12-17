import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';
import '../models/user_profile.dart';

class AuthService {
  // URL is now configured in AppConfig - toggle isProduction to switch
  static String get baseUrl => AppConfig.authUrl;

  // Google Sign-In akan menggunakan access_token untuk autentikasi
  // karena Firebase project (diskusi-bisnis) dan Backend menggunakan Google Cloud project berbeda
  // Backend akan memverifikasi access_token via Google userinfo API
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    // Tidak menggunakan serverClientId karena project berbeda
  );

  // --- Auth State ---
  String? _token;
  UserProfile? _currentUser;

  String? get token => _token;
  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    if (_token != null) {
      final userData = prefs.getString('user_data');
      if (userData != null) {
        _currentUser = UserProfile.fromJson(jsonDecode(userData));
      } else {
        // Fallback or force logout if data missing?
        // For now, let's leave currentUser null or try to fetch it if we had a /me endpoint
      }
    }
  }

  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    print('Attempting login to: $url');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Login Response Status: ${response.statusCode}');
      // Removed verbose response body log

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['data']['token'];
        _currentUser = UserProfile.fromJson(data['data']['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', jsonEncode(data['data']['user']));
        return true;
      } else {
        throw Exception(jsonDecode(response.body)['message'] ??
            'Login gagal: ${response.statusCode}');
      }
    } catch (e) {
      print('Login Error: $e');
      rethrow;
    }
  }

  Future<bool> requestRegisterOTP(String displayName, String username,
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'displayName': displayName,
          'username': username,
          'email': email,
          'password': password
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
            jsonDecode(response.body)['message'] ?? 'Gagal meminta OTP');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyRegisterOTP(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['data']['token'];
        _currentUser = UserProfile.fromJson(data['data']['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', jsonEncode(data['data']['user']));
        return true;
      } else {
        throw Exception(
            jsonDecode(response.body)['message'] ?? 'Verifikasi OTP gagal');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> register(
      String displayName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'displayName': displayName, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['data']['token'];
        _currentUser = UserProfile.fromJson(data['data']['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', jsonEncode(data['data']['user']));
        return true;
      } else {
        throw Exception(
            jsonDecode(response.body)['message'] ?? 'Registrasi gagal');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> googleLogin() async {
    try {
      print('=== GOOGLE SIGN IN START ===');
      print('Calling _googleSignIn.signIn()...');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('User canceled Google Sign In or sign-in failed');
        return false;
      }

      print('Google User found: ${googleUser.email}');
      print('Getting authentication tokens...');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      print(
          'idToken: ${idToken != null ? "OK (${idToken.length} chars)" : "NULL"}');
      print(
          'accessToken: ${accessToken != null ? "OK (${accessToken.length} chars)" : "NULL"}');

      // Gunakan idToken jika ada, jika tidak gunakan accessToken
      final String? tokenToSend = idToken ?? accessToken;
      final String tokenType = idToken != null ? 'id_token' : 'access_token';

      if (tokenToSend == null) {
        throw Exception('Gagal mendapatkan token dari Google. Coba lagi.');
      }

      print('Using $tokenType for authentication');
      print('Sending to backend: $baseUrl/google');

      // Kirim Token ke Backend (bisa ID Token atau Access Token)
      final response = await http.post(
        Uri.parse('$baseUrl/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'credential': tokenToSend,
          'tokenType': tokenType,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['data']['token'];
        _currentUser = UserProfile.fromJson(data['data']['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', jsonEncode(data['data']['user']));
        return true;
      } else {
        throw Exception(
            jsonDecode(response.body)['message'] ?? 'Google Login gagal');
      }
    } catch (e, stackTrace) {
      // For development debugging only
      print('Google Login Error: $e');
      print('Stack Trace: $stackTrace');
      rethrow;
    }
  }

  Future<bool> updateProfile(
      String displayName, String bio, String? avatarUrl) async {
    try {
      if (_currentUser == null) throw Exception('User not logged in');
      final token = _token ??
          (await SharedPreferences.getInstance()).getString('auth_token');
      if (token == null) throw Exception('Token not found');

      final rootUrl = baseUrl.replaceAll('/auth', '');

      final body = {
        'displayName': displayName,
        'bio': bio,
      };

      // Include avatarUrl if provided
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        body['avatarUrl'] = avatarUrl;
      }

      final response = await http.put(
        Uri.parse('$rootUrl/users/${_currentUser!.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = UserProfile.fromJson(data['data']['user']);

        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(data['data']['user']));
        return true;
      } else {
        throw Exception(
            jsonDecode(response.body)['message'] ?? 'Update profile gagal');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> uploadAvatar(
      String base64Image, String displayName, String bio) async {
    try {
      if (_currentUser == null) throw Exception('User not logged in');
      final token = _token ??
          (await SharedPreferences.getInstance()).getString('auth_token');
      if (token == null) throw Exception('Token not found');

      final rootUrl = baseUrl.replaceAll('/auth', '');
      final response = await http.put(
        Uri.parse('$rootUrl/users/${_currentUser!.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'avatarUrl': base64Image,
          'displayName': displayName,
          'bio': bio,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = UserProfile.fromJson(data['data']['user']);

        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(data['data']['user']));
        return true;
      } else {
        throw Exception(
            jsonDecode(response.body)['message'] ?? 'Upload avatar gagal');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteAvatar() async {
    try {
      if (_currentUser == null) throw Exception('User not logged in');
      final token = _token ??
          (await SharedPreferences.getInstance()).getString('auth_token');
      if (token == null) throw Exception('Token not found');

      final rootUrl = baseUrl.replaceAll('/auth', '');
      final response = await http.delete(
        Uri.parse('$rootUrl/users/${_currentUser!.id}/avatar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = UserProfile.fromJson(data['data']['user']);

        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(data['data']['user']));
        return true;
      } else {
        throw Exception(
            jsonDecode(response.body)['message'] ?? 'Hapus avatar gagal');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteAccount(String? password) async {
    try {
      if (_currentUser == null) throw Exception('User not logged in');
      final token = _token ??
          (await SharedPreferences.getInstance()).getString('auth_token');
      if (token == null) throw Exception('Token not found');

      final rootUrl = baseUrl.replaceAll('/auth', '');
      final response = await http.delete(
        Uri.parse('$rootUrl/users/${_currentUser!.id}/account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        await logout();
        return true;
      } else {
        throw Exception(
            jsonDecode(response.body)['message'] ?? 'Gagal menghapus akun');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await _googleSignIn.signOut();
  }
}
