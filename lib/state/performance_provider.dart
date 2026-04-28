import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/performance_monitor.dart';

final performanceMonitorProvider = ChangeNotifierProvider<PerformanceMonitor>((ref) {
  final monitor = PerformanceMonitor();
  monitor.startMonitoring();
  ref.onDispose(() => monitor.stopMonitoring());
  return monitor;
});

final qualityLevelProvider = Provider<QualityLevel>((ref) {
  final monitor = ref.watch(performanceMonitorProvider);
  return monitor.currentLevel;
});
