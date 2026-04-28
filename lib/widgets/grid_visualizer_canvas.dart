import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/core/grid_problem.dart';
import 'package:algo_arena/models/grid_node.dart';
import 'package:algo_arena/models/app_settings.dart';
import 'package:algo_arena/services/algorithm_executor.dart';
import 'package:algo_arena/state/grid_controller.dart';
import 'package:algo_arena/state/settings_provider.dart';

class GridVisualizerCanvas extends ConsumerStatefulWidget {
  final GridController controller;
  final AlgorithmExecutor<GridCoordinate>? executor;
  final List<GridCoordinate>? exploredNodes;
  final int? exploredCount;
  final List<GridCoordinate>? pathNodes;
  final int? pathCount;
  final Color? accentColor;
  final bool isInteractive;
  final bool showHeuristics;
  final void Function(int row, int col)? onPointerDown;
  final void Function(int row, int col)? onPointerUpdate;
  final void Function()? onPointerUp;

  const GridVisualizerCanvas({
    super.key,
    required this.controller,
    this.executor,
    this.accentColor,
    this.isInteractive = true,
    this.onPointerDown,
    this.onPointerUpdate,
    this.onPointerUp,
    this.exploredNodes,
    this.exploredCount,
    this.pathNodes,
    this.pathCount,
    this.showHeuristics = false,
  });

  @override
  ConsumerState<GridVisualizerCanvas> createState() =>
      _GridVisualizerCanvasState();
}

class _GridVisualizerCanvasState extends ConsumerState<GridVisualizerCanvas>
    with SingleTickerProviderStateMixin {
  ui.Picture? _staticGridPicture;
  AppSettings? _lastSettings;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onGridChanged);
    widget.executor?.addListener(_onExecutorUpdate);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 4, end: 12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(GridVisualizerCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onGridChanged);
      widget.controller.addListener(_onGridChanged);
      _invalidateStaticPicture();
    }
    if (oldWidget.executor != widget.executor) {
      oldWidget.executor?.removeListener(_onExecutorUpdate);
      widget.executor?.addListener(_onExecutorUpdate);
    }
    if (oldWidget.showHeuristics != widget.showHeuristics) {
      _invalidateStaticPicture();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onGridChanged);
    widget.executor?.removeListener(_onExecutorUpdate);
    _pulseController.dispose();
    _staticGridPicture?.dispose();
    super.dispose();
  }

  void _onGridChanged() {
    _invalidateStaticPicture();
    setState(() {});
  }

  void _onExecutorUpdate() {
    if (widget.executor?.isRunning == true) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
    }
    setState(() {});
  }

  void _invalidateStaticPicture() {
    _staticGridPicture?.dispose();
    _staticGridPicture = null;
  }

  void _handlePointerDown(Offset localPosition, Size size) {
    if (!widget.isInteractive) return;
    final rowCol = _getRowCol(localPosition, size);
    if (rowCol != null) {
      if (widget.onPointerDown != null) {
        widget.onPointerDown!(rowCol.$1, rowCol.$2);
      } else {
        widget.controller.handleCellInteraction(rowCol.$1, rowCol.$2);
      }
    }
  }

  void _handlePointerUpdate(Offset localPosition, Size size) {
    if (!widget.isInteractive) return;
    final rowCol = _getRowCol(localPosition, size);
    if (rowCol != null) {
      if (widget.onPointerUpdate != null) {
        widget.onPointerUpdate!(rowCol.$1, rowCol.$2);
      } else {
        widget.controller.handleCellInteraction(rowCol.$1, rowCol.$2);
      }
    }
  }

  void _handlePointerUp() {
    if (!widget.isInteractive) return;
    widget.onPointerUp?.call();
  }

  (int, int)? _getRowCol(Offset localPosition, Size size) {
    final cellWidth = size.width / widget.controller.columns;
    final cellHeight = size.height / widget.controller.rows;
    final col = (localPosition.dx / cellWidth).floor();
    final row = (localPosition.dy / cellHeight).floor();

    if (row >= 0 &&
        row < widget.controller.rows &&
        col >= 0 &&
        col < widget.controller.columns) {
      return (row, col);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    // Invalidate if transparency changes
    if (_lastSettings?.gridTransparency != settings.gridTransparency) {
      _invalidateStaticPicture();
      _lastSettings = settings;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onPanStart: (details) =>
              _handlePointerDown(details.localPosition, size),
          onPanUpdate: (details) =>
              _handlePointerUpdate(details.localPosition, size),
          onPanEnd: (_) => _handlePointerUp(),
          onTapDown: (details) =>
              _handlePointerDown(details.localPosition, size),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: size,
                painter: _GridPainter(
                  controller: widget.controller,
                  executor: widget.executor,
                  exploredNodes: widget.exploredNodes,
                  exploredCount: widget.exploredCount,
                  pathNodes: widget.pathNodes,
                  pathCount: widget.pathCount,
                  accentColor: widget.accentColor ?? AppTheme.accent,
                  pulseValue: _pulseAnimation.value,
                  staticPicture: _staticGridPicture,
                  settings: settings,
                  showHeuristics: widget.showHeuristics,
                  onPictureCreated: (picture) {
                    _staticGridPicture = picture;
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  final GridController controller;
  final AlgorithmExecutor<GridCoordinate>? executor;
  final List<GridCoordinate>? exploredNodes;
  final int? exploredCount;
  final List<GridCoordinate>? pathNodes;
  final int? pathCount;
  final Color accentColor;
  final double pulseValue;
  final ui.Picture? staticPicture;
  final AppSettings settings;
  final bool showHeuristics;
  final Function(ui.Picture) onPictureCreated;

  _GridPainter({
    required this.controller,
    required this.executor,
    this.exploredNodes,
    this.exploredCount,
    this.pathNodes,
    this.pathCount,
    required this.accentColor,
    required this.pulseValue,
    required this.staticPicture,
    required this.settings,
    required this.showHeuristics,
    required this.onPictureCreated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / controller.columns;
    final cellHeight = size.height / controller.rows;

    // Define the visible viewport. For now, it's the full size, 
    // but this logic allows for easy integration with zooming/panning.
    final viewport = Offset.zero & size;

    // 1. Draw or Create Static Content (Background and Walls)
    if (staticPicture != null) {
      canvas.drawPicture(staticPicture!);
    } else {
      final recorder = ui.PictureRecorder();
      final staticCanvas = Canvas(recorder);
      _drawStaticGrid(staticCanvas, size, cellWidth, cellHeight, viewport);
      final picture = recorder.endRecording();
      onPictureCreated(picture);
      canvas.drawPicture(picture);
    }

    // 2. Draw Dynamic Content (Explored Set and Path)
    _drawExploredStates(canvas, cellWidth, cellHeight, viewport);
    _drawPath(canvas, cellWidth, cellHeight, viewport);
    _drawCurrentNode(canvas, cellWidth, cellHeight, viewport);
  }

  void _drawStaticGrid(
    Canvas canvas,
    Size size,
    double cellWidth,
    double cellHeight,
    Rect viewport,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0;

    // Background
    paint.color = AppTheme.surfaceLow;
    canvas.drawRect(size.shortestSide > 0 ? (Offset.zero & size) : Rect.zero, paint);

    // Viewport Culling: Calculate visible range
    final startCol = (viewport.left / cellWidth).floor().clamp(0, controller.columns - 1);
    final endCol = (viewport.right / cellWidth).ceil().clamp(0, controller.columns - 1);
    final startRow = (viewport.top / cellHeight).floor().clamp(0, controller.rows - 1);
    final endRow = (viewport.bottom / cellHeight).ceil().clamp(0, controller.rows - 1);

    // Draw grid nodes (primarily walls and anchors)
    for (int r = startRow; r <= endRow; r++) {
      for (int c = startCol; c <= endCol; c++) {
        final node = controller.grid[r][c];
        final rect = Rect.fromLTWH(
          c * cellWidth + 0.5,
          r * cellHeight + 0.5,
          cellWidth - 1,
          cellHeight - 1,
        );

        if (showHeuristics && node.type == NodeType.empty) {
          // Calculate heuristic (Manhattan distance to goal)
          final goal = controller.goal;
          if (goal != null) {
            final distance = (r - goal.row).abs() + (c - goal.column).abs();
            final maxPossible = controller.rows + controller.columns;
            
            // Curve adjusted for more broad visibility and higher peak intensity
            final intensity = math.pow(1.0 - (distance / maxPossible), 1.5).clamp(0.0, 1.0);
            
            // Maximum alpha for a very strong "Force Field" effect
            paint.color = AppTheme.accent.withValues(alpha: intensity.toDouble() * 0.7);
            canvas.drawRect(rect, paint);
          }
        }

        if (node.type == NodeType.wall) {
          paint.color = AppTheme.cellWall;
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)),
            paint,
          );
        } else if (node.type == NodeType.start) {
          paint.color = AppTheme.cellStart;
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)),
            paint,
          );
        } else if (node.type == NodeType.goal) {
          paint.color = AppTheme.cellGoal;
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)),
            paint,
          );
        } else if (node.type == NodeType.weight) {
          paint.color = AppTheme.cellWeight;
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)),
            paint,
          );
        }
      }
    }

    // Grid Lines (Subtle)
    final linePaint = Paint()
      ..color = Colors.white
          .withValues(
            alpha: settings.gridTransparency * 0.1,
          ) // Sensitivity to settings
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i <= controller.columns; i++) {
      canvas.drawLine(
        Offset(i * cellWidth, 0),
        Offset(i * cellWidth, size.height),
        linePaint,
      );
    }
    for (int i = 0; i <= controller.rows; i++) {
      canvas.drawLine(
        Offset(0, i * cellHeight),
        Offset(size.width, i * cellHeight),
        linePaint,
      );
    }
  }

  void _drawExploredStates(
    Canvas canvas,
    double cellWidth,
    double cellHeight,
    Rect viewport,
  ) {
    final explored = exploredNodes ?? executor?.exploredSet;
    if (explored == null || explored.isEmpty) return;

    final paint = Paint()
      ..color = accentColor.withValues(alpha: 0.4)
      ..strokeWidth = math.min(cellWidth, cellHeight) * 0.8
      ..strokeCap = StrokeCap.square;

    final count = exploredCount ?? explored.length;
    int i = 0;
    final points = <Offset>[];
    for (final state in explored) {
      if (i >= count) break;
      
      if (state.row >= controller.rows || state.column >= controller.columns) {
        i++;
        continue;
      }

      // Viewport culling
      final x = state.column * cellWidth + cellWidth / 2;
      final y = state.row * cellHeight + cellHeight / 2;
      if (!viewport.contains(Offset(x, y))) {
        i++;
        continue;
      }

      if (controller.grid[state.row][state.column].type != NodeType.empty) {
        i++;
        continue;
      }

      points.add(Offset(x, y));
      i++;
    }
    
    if (points.isNotEmpty) {
      canvas.drawPoints(ui.PointMode.points, points, paint);
    }
  }

  void _drawPath(
    Canvas canvas,
    double cellWidth,
    double cellHeight,
    Rect viewport,
  ) {
    final pathNodesList = pathNodes ?? executor?.pathSet;
    if (pathNodesList == null || pathNodesList.isEmpty) return;

    final paint = Paint()
      ..color = AppTheme.cyan
      ..style = PaintingStyle.fill;

    final path = Path();
    final count = pathCount ?? pathNodesList.length;

    int i = 0;
    for (final state in pathNodesList) {
      if (i >= count) break;

      final x = state.column * cellWidth + cellWidth / 2;
      final y = state.row * cellHeight + cellHeight / 2;

      // Viewport culling
      if (!viewport.contains(Offset(x, y))) {
        i++;
        continue;
      }

      final rect = Rect.fromLTWH(
        state.column * cellWidth + 1.5,
        state.row * cellHeight + 1.5,
        cellWidth - 3,
        cellHeight - 3,
      );
      path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)));
      i++;
    }
    
    canvas.drawPath(path, paint);
  }

  void _drawCurrentNode(
    Canvas canvas,
    double cellWidth,
    double cellHeight,
    Rect viewport,
  ) {
    final current = executor?.lastStep?.currentState;
    if (current == null) return;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Sensitivity to settings.neonGlowIntensity
    final glowValue = pulseValue * settings.neonGlowIntensity * 2.0;

    final pulsePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.8)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        glowValue.clamp(0.1, 20.0),
      );

    final center = Offset(
      current.column * cellWidth + cellWidth / 2,
      current.row * cellHeight + cellHeight / 2,
    );

    canvas.drawCircle(center, cellWidth / 3, pulsePaint);
    canvas.drawCircle(center, 2.0, paint);
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.staticPicture != staticPicture ||
        oldDelegate.executor?.lastStep != executor?.lastStep ||
        oldDelegate.controller != controller ||
        oldDelegate.settings != settings ||
        oldDelegate.exploredCount != exploredCount ||
        oldDelegate.pathCount != pathCount ||
        oldDelegate.exploredNodes != exploredNodes ||
        oldDelegate.pathNodes != pathNodes;
  }
}

