import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized API service for handling algorithm run data and analysis.
class ApiService {
  // Use IP instead of localhost for real device compatibility, fetched from .env
  static String get baseUrl => dotenv.env['API_URL'] ?? "http://localhost:3000/api";

  // --- Runs API ---

  /// Saves a specific algorithm run to the backend.
  Future<void> saveRun(Map<String, dynamic> runData) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/runs"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(runData),
      );

      if (response.statusCode != 201) {
        throw Exception("Failed to save run: ${response.statusCode} - ${response.body}");
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
  }) async {
    try {
      String url = "$baseUrl/runs?page=$page&limit=$limit";

      if (algorithm != null && algorithm != "All") {
        url += "&algorithm=$algorithm";
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
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
      final response = await http.delete(Uri.parse("$baseUrl/runs/$id"));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception("Failed to delete run: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error while deleting run: $e");
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
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
  }) async {
    try {
      final query = {
        if (algorithm != null && algorithm != "All") "algorithm": algorithm,
        if (metric != null) "metric": metric,
      };

      final uri = Uri.parse("$_analyticsUrl/trends").replace(queryParameters: query);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to fetch trends: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error while fetching trends: $e");
    }
  }

  /// Fetches algorithm usage distribution.
  Future<Map<String, dynamic>> getDistribution() async {
    try {
      final uri = Uri.parse("$_analyticsUrl/distribution");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to fetch distribution: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error while fetching distribution: $e");
    }
  }

  /// Fetches comparative AI-style insights.
  Future<Map<String, dynamic>> getBattleInsights() async {
    try {
      final uri = Uri.parse("$_analyticsUrl/battle-insights");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to fetch battle insights: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error while fetching battle insights: $e");
    }
  }
}
