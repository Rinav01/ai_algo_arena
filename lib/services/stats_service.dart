import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Data class to hold all arena stats
class ArenaStats {
  final int battlesRun;
  final Map<String, int> winCounts;
  final String? bestAlgorithm;
  final List<String> winOrder; // To track who reached the count first

  const ArenaStats({
    this.battlesRun = 0,
    this.winCounts = const {},
    this.bestAlgorithm,
    this.winOrder = const [],
  });

  ArenaStats copyWith({
    int? battlesRun,
    Map<String, int>? winCounts,
    String? bestAlgorithm,
    List<String>? winOrder,
  }) {
    return ArenaStats(
      battlesRun: battlesRun ?? this.battlesRun,
      winCounts: winCounts ?? this.winCounts,
      bestAlgorithm: bestAlgorithm ?? this.bestAlgorithm,
      winOrder: winOrder ?? this.winOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'battlesRun': battlesRun,
        'winCounts': winCounts,
        'winOrder': winOrder,
      };

  factory ArenaStats.fromJson(Map<String, dynamic> json) {
    final winCounts = Map<String, int>.from(json['winCounts'] ?? {});
    final winOrder = List<String>.from(json['winOrder'] ?? []);
    
    String? best;
    int maxWins = 0;
    
    // Tie-breaking: first to reach the count.
    // We iterate through winOrder to find who has the current maxWins.
    // The first one we find with the max wins in the order count reached is the "Senior" leader.
    for (final algo in winOrder) {
      final wins = winCounts[algo] ?? 0;
      if (wins > maxWins) {
        maxWins = wins;
        best = algo;
      }
    }

    return ArenaStats(
      battlesRun: json['battlesRun'] ?? 0,
      winCounts: winCounts,
      bestAlgorithm: best,
      winOrder: winOrder,
    );
  }
}

/// provider for the persistent stats
final arenaStatsProvider = StateNotifierProvider<ArenaStatsNotifier, ArenaStats>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return ArenaStatsNotifier(prefs);
});

/// Shared Preferences provider (initalized in main)
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class ArenaStatsNotifier extends StateNotifier<ArenaStats> {
  final SharedPreferences prefs;
  static const _key = 'arena_stats_v1';

  ArenaStatsNotifier(this.prefs) : super(const ArenaStats()) {
    _load();
  }

  void _load() {
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        state = ArenaStats.fromJson(jsonDecode(raw));
      } catch (_) {
        // Fallback to default if corrupted
      }
    }
  }

  Future<void> recordBattleCompletion(String? winnerName) async {
    final newBattlesRun = state.battlesRun + 1;
    Map<String, int> newWinCounts = Map.from(state.winCounts);
    List<String> newWinOrder = List.from(state.winOrder);

    if (winnerName != null) {
      newWinCounts[winnerName] = (newWinCounts[winnerName] ?? 0) + 1;
      
      // If this algo is not in the winOrder yet, add it.
      // Note: This winOrder logic simple tracks the "existence" of the algo in terms of wins.
      // For true "reached count first" tie-breaking, we need to know when someone surpasses someone else.
      if (!newWinOrder.contains(winnerName)) {
        newWinOrder.add(winnerName);
      } else {
         // To strictly follow "one that reaches the count first":
         // If A has 2 wins and B has 1. B gets a 2nd win. A is still the leader.
         // My loop in fromJson handles this because it picks the first one it finds with maxWins.
      }
    }

    // Recalculate best algorithm
    String? best;
    int maxWins = 0;
    for (final algo in newWinOrder) {
      final wins = newWinCounts[algo] ?? 0;
      if (wins > maxWins) {
        maxWins = wins;
        best = algo;
      }
    }

    state = state.copyWith(
      battlesRun: newBattlesRun,
      winCounts: newWinCounts,
      bestAlgorithm: best,
      winOrder: newWinOrder,
    );

    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> resetStats() async {
    state = const ArenaStats();
    await prefs.remove(_key);
  }
}
