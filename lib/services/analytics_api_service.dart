import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for interacting with the Analytics API endpoints.
class AnalyticsApiService {
  // Base URL fetched from .env, similar to ApiService
  static String get baseUrl => "${dotenv.env['API_URL'] ?? "http://localhost:3000/api"}/analytics";

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

      final uri = Uri.parse("$baseUrl/summary").replace(queryParameters: query);
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

      final uri = Uri.parse("$baseUrl/trends").replace(queryParameters: query);
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
      final uri = Uri.parse("$baseUrl/distribution");
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
      final uri = Uri.parse("$baseUrl/battle-insights");
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
