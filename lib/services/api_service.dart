import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized API service for handling algorithm run data and analysis.
class ApiService {
  // Use IP instead of localhost for real device compatibility, fetched from .env
  static String get baseUrl => dotenv.env['API_URL'] ?? "http://localhost:3000/api";

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
      // Re-throw to be handled by the UI layer
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
        return jsonDecode(response.body);
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
}
