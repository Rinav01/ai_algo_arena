import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_algo_app/models/app_settings.dart';
import 'package:ai_algo_app/services/stats_service.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});

class SettingsNotifier extends Notifier<AppSettings> {
  static const _key = 'app_settings_v1';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        return AppSettings.fromJson(jsonDecode(raw));
      } catch (_) {
        return const AppSettings();
      }
    }
    return const AppSettings();
  }

  Future<void> _save() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  void updateNeonGlow(double value) {
    state = state.copyWith(neonGlowIntensity: value);
    _save();
  }

  void updateGridTransparency(double value) {
    state = state.copyWith(gridTransparency: value);
    _save();
  }

  void toggleDiagonalMoves(bool value) {
    state = state.copyWith(allowDiagonalMoves: value);
    _save();
  }

  void updateHeuristicWeight(double value) {
    state = state.copyWith(heuristicWeight: value);
    _save();
  }

  void toggleCollisionVibration(bool value) {
    state = state.copyWith(collisionVibration: value);
    _save();
  }

  void toggleExecutionPulse(bool value) {
    state = state.copyWith(executionPulse: value);
    _save();
  }

  Future<void> resetToDefaults() async {
    state = const AppSettings();
    await _save();
  }
}
