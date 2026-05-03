import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Service to handle Firebase Auth token management and session authentication.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Private constructor to prevent direct instantiation.
  AuthService._();

  /// Automatically authenticates anonymously if no user session exists.
  static Future<User?> ensureAuthenticated() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        final userCredential = await _auth.signInAnonymously();
        currentUser = userCredential.user;
      }
      return currentUser;
    } catch (e) {
      print('Firebase Sign-In Error: $e');
      return null;
    }
  }

  /// Get the latest Firebase JWT Auth Token string.
  static Future<String?> getAuthToken() async {
    try {
      final user = _auth.currentUser ?? await ensureAuthenticated();
      if (user != null) {
        // Retrieves the token string
        return await user.getIdToken();
      }
    } catch (e) {
      print('Get Firebase Token Error: $e');
    }
    return null;
  }

  /// Sends a sign-in link to the specified email.
  static Future<void> sendSignInLink(String email) async {
    final actionCodeSettings = ActionCodeSettings(
      url: 'https://ai-algo-arena.web.app/login', // Dynamic or fallback URL
      handleCodeInApp: true,
      androidPackageName: 'com.example.algo_arena',
      androidInstallApp: true,
      androidMinimumVersion: '21',
    );

    // Send link to the email address
    await _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );

    // Cache the email locally to complete sign-in later
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email_for_signin', email);
  }

  /// Checks if a dynamic/deep link is a valid sign-in link.
  static bool isSignInLink(String link) {
    return _auth.isSignInWithEmailLink(link);
  }

  /// Completes sign-in using the deep link.
  static Future<User?> signInWithLink(String link) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email_for_signin');

      if (email != null) {
        final userCredential = await _auth.signInWithEmailLink(
          email: email,
          emailLink: link,
        );
        return userCredential.user;
      }
    } catch (e) {
      print("Error signing in with email link: $e");
    }
    return null;
  }

  /// Sends a one-time passcode (OTP) to the specified email.
  static Future<String?> sendOtp(String email) async {
    try {
      final baseUrl = ApiService.baseUrl;
      final response = await http.post(
        Uri.parse("$baseUrl/auth/send-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['otp'] as String?;
      } else {
        final errorMsg = jsonDecode(response.body)['error'] ?? "Failed to send OTP";
        throw Exception(errorMsg);
      }
    } catch (e) {
      throw Exception("Error sending OTP: $e");
    }
  }

  /// Verifies the OTP and logs in with the resulting custom token.
  static Future<User?> verifyOtp(String email, String otp) async {
    try {
      final baseUrl = ApiService.baseUrl;
      final response = await http.post(
        Uri.parse("$baseUrl/auth/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "otp": otp}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final customToken = data['customToken'] as String?;
        if (customToken != null) {
          final userCredential = await _auth.signInWithCustomToken(customToken);
          return userCredential.user;
        }
      } else {
        final errorMsg = jsonDecode(response.body)['error'] ?? "Failed to verify OTP";
        throw Exception(errorMsg);
      }
    } catch (e) {
      throw Exception("Error verifying OTP: $e");
    }
    return null;
  }

  /// Logs the current user out.
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
