import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final runsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  debugPrint('Fetching run history...');
  final runs = await api.getRuns();
  debugPrint('Fetched ${runs.length} runs');
  return runs;
});
