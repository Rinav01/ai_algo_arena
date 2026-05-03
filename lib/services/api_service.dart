// ignore_for_file: use_null_aware_elements
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

/// Centralized API service for handling algorithm run data and analysis.
class ApiService {
  static String? _resolvedBaseUrl;

  /// Dynamic one-time resolution for correct emulator vs real physical device testing
  static Future<void> init() async {
    final url = dotenv.env['API_URL'] ?? "http://localhost:3000/api";
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // 1. Try testing localhost (for physical devices with adb reverse tcp:3000 tcp:3000 or local dev)
      try {
        final res = await http.get(Uri.parse("http://localhost:3000/health")).timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200) {
          _resolvedBaseUrl = url.replaceAll("10.0.2.2", "localhost");
          return;
        }
      } catch (_) {}

      // 2. Try testing 10.0.2.2 (for Android Emulators)
      try {
        final res = await http.get(Uri.parse("http://10.0.2.2:3000/health")).timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200) {
          _resolvedBaseUrl = url.replaceAll("localhost", "10.0.2.2");
          return;
        }
      } catch (_) {}

      // 3. Extract actual host from url and see if we can reach it
      try {
        final uri = Uri.parse(url);
        final res = await http.get(Uri.parse("${uri.scheme}://${uri.host}:${uri.port}/health")).timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200) {
          _resolvedBaseUrl = url;
          return;
        }
      } catch (_) {}
    }
    _resolvedBaseUrl = url;
  }

  static String get baseUrl {
    if (_resolvedBaseUrl != null) return _resolvedBaseUrl!;
    return dotenv.env['API_URL'] ?? "http://localhost:3000/api";
  }

  /// Generates the necessary headers, injecting the Bearer authentication token.
  Future<Map<String, String>> _getHeaders() async {
    final Map<String, String> headers = {
      "Content-Type": "application/json",
    };
    final token = await AuthService.getAuthToken();
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  // --- Runs API ---

  /// Saves a specific algorithm run to the backend.
  Future<void> saveRun(Map<String, dynamic> runData) async {
    try {
      final jsonStr = await compute(jsonEncode, runData);
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl/runs"),
        headers: headers,
        body: jsonStr,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 202) {
        throw Exception("Failed to save run: ${response.statusCode} - ${response.body}");
      }
      if (response.statusCode == 202) {
        // Wait for asynchronous ingestion on the backend to write to the database
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    } catch (e) {
      throw Exception("Network error while saving run: $e");
    }
  }

  /// Fetches a list of algorithm runs with optional filtering and pagination.
  Future<List<dynamic>> getRuns({
    String? algorithm,
    int page = 1,
    int limit = 20,
    String? sort,
    String? date,
  }) async {
    try {
      String url = "$baseUrl/runs?page=$page&limit=$limit";

      if (algorithm != null && algorithm != "All") {
        url += "&algorithm=$algorithm";
      }
      if (sort != null) {
        url += "&sort=$sort";
      }
      if (date != null) {
        url += "&date=$date";
      }

      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = await compute(jsonDecode, response.body);
        if (body is Map && body.containsKey('data')) {
          return body['data'] as List<dynamic>;
        }
        return body as List<dynamic>;
      } else {
        throw Exception("Failed to fetch runs: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error while fetching runs: $e");
    }
  }

  /// Deletes a specific algorithm run from the backend.
  Future<void> deleteRun(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse("$baseUrl/runs/$id"), headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception("Failed to delete run: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error while deleting run: $e");
    }
  }

  /// Deletes all algorithm runs from the backend.
  Future<void> deleteAllRuns() async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse("$baseUrl/runs"), headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception("Failed to delete all runs: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error while deleting all runs: $e");
    }
  }

  // --- Analytics API ---

  String get _analyticsUrl => "$baseUrl/analytics";

  /// Fetches summary data for algorithms based on optional filters.
  Future<Map<String, dynamic>> getSummary({
    String? algorithm,
    String? startDate,
    String? endDate,
    List<String>? tags,
  }) async {
    try {
      final query = {
        if (algorithm != null && algorithm != "All") "algorithm": algorithm,
        if (startDate != null) "startDate": startDate,
        if (endDate != null) "endDate": endDate,
        if (tags != null && tags.isNotEmpty) "tags": tags.join(","),
      };

      final uri = Uri.parse("$_analyticsUrl/summary").replace(queryParameters: query);
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return await compute(jsonDecode, response.body) as Map<String, dynamic>;
      } else {
        throw Exception("Failed to fetch summary: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error while fetching summary: $e");
    }
  }

  /// Fetches performance trends over time.
  Future<Map<String, dynamic>> getTrends({
    String? algorithm,
    String? metric, // "nodes" or "time"
    String? startDate,
    String? endDate,
  }) async {
    try {
      final query = {
        if (algorithm != null && algorithm != "All") "algorithm": algorithm,
        if (metric != null) "metric": metric,
        if (startDate != null) "startDate": startDate,
        if (endDate != null) "endDate": endDate,
      };

      final uri = Uri.parse("$_analyticsUrl/trends").replace(queryParameters: query);
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return await compute(jsonDecode, response.body) as Map<String, dynamic>;
      } else {
        throw Exception("Failed to fetch trends: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error while fetching trends: $e");
    }
  }

  /// Fetches algorithm usage distribution.
  Future<Map<String, dynamic>> getDistribution({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final query = {
        if (startDate != null) "startDate": startDate,
        if (endDate != null) "endDate": endDate,
      };
      final uri = Uri.parse("$_analyticsUrl/distribution").replace(queryParameters: query);
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return await compute(jsonDecode, response.body) as Map<String, dynamic>;
      } else {
        throw Exception("Failed to fetch distribution: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error while fetching distribution: $e");
    }
  }

  /// Fetches battle insights.
  Future<Map<String, dynamic>> getBattleInsights() async {
    try {
      final uri = Uri.parse("$_analyticsUrl/battle-insights");
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return await compute(jsonDecode, response.body) as Map<String, dynamic>;
      } else {
        throw Exception("Failed to fetch battle insights: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error while fetching battle insights: $e");
    }
  }

  /// Fetches complexity data.
  Future<Map<String, dynamic>> getComplexity() async {
    try {
      final uri = Uri.parse("$_analyticsUrl/complexity");
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return await compute(jsonDecode, response.body) as Map<String, dynamic>;
      } else {
        throw Exception("Failed to fetch complexity: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error while fetching complexity: $e");
    }
  }
}
