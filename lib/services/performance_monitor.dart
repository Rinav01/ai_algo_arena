import 'dart:async';
import 'package:flutter/widgets.dart';

enum QualityLevel {
  performance, // Low end: Disable blur, reduce animations
  balanced,    // Mid range: Standard effects
  ultra,       // High end: Maximum fidelity
}

class PerformanceMonitor extends ChangeNotifier {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  QualityLevel _currentLevel = QualityLevel.ultra;
  QualityLevel get currentLevel => _currentLevel;

  double _averageFrameTimeMs = 0;
  int _frameCount = 0;
  int _droppedFrames = 0;
  
  bool _isMonitoring = false;

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _frameCount = 0;
    _droppedFrames = 0;
    
    WidgetsBinding.instance.addPersistentFrameCallback(_onFrame);
    
    // Periodically evaluate performance every 5 seconds
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }
      _evaluateQuality();
    });
  }

  void stopMonitoring() {
    _isMonitoring = false;
  }

  Duration? _lastFrameTime;

  void _onFrame(Duration timeStamp) {
    if (!_isMonitoring) return;
    
    _frameCount++;
    
    if (_lastFrameTime != null) {
      final frameDelta = (timeStamp - _lastFrameTime!).inMicroseconds / 1000.0;
      
      // Calculate smoothed average (Exponential Moving Average)
      _averageFrameTimeMs = (_averageFrameTimeMs == 0) 
          ? frameDelta 
          : (_averageFrameTimeMs * 0.9) + (frameDelta * 0.1);

      // If a frame takes longer than 17ms, it's a "jank" frame
      if (frameDelta > 17.0) {
        _droppedFrames++;
      }
    }
    
    _lastFrameTime = timeStamp;
  }

  void _evaluateQuality() {
    if (_frameCount < 60) return; // Wait for enough data

    // Logic: If average frame time is high or we are dropping > 15% of frames
    final dropRate = _droppedFrames / _frameCount;

    if (_averageFrameTimeMs > 20.0 || dropRate > 0.15) {
      // Degrading quality to maintain 60fps
      if (_currentLevel == QualityLevel.ultra) {
        setQualityLevel(QualityLevel.balanced);
      } else if (_currentLevel == QualityLevel.balanced) {
        setQualityLevel(QualityLevel.performance);
      }
    } else if (_averageFrameTimeMs < 14.0 && dropRate < 0.02) {
      // If we have massive headroom, we can upgrade back
      if (_currentLevel == QualityLevel.performance) {
        setQualityLevel(QualityLevel.balanced);
      }
    }

    // Reset counters for the next 5-second window
    _frameCount = 0;
    _droppedFrames = 0;
  }

  void setQualityLevel(QualityLevel level) {
    if (_currentLevel != level) {
      _currentLevel = level;
      notifyListeners();
    }
  }
}
