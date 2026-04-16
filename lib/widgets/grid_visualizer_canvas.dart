import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/grid_problem.dart';
import '../models/grid_node.dart';
import '../services/algorithm_executor.dart';
import '../state/grid_controller.dart';

class GridVisualizerCanvas extends StatefulWidget {
  final GridController controller;
  final AlgorithmExecutor<GridCoordinate>? executor;
  final Color? accentColor;
  final bool isInteractive;
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
  });

  @override
  State<GridVisualizerCanvas> createState() => _GridVisualizerCanvasState();
}

class _GridVisualizerCanvasState extends State<GridVisualizerCanvas>
    with SingleTickerProviderStateMixin {
  ui.Picture? _staticGridPicture;
  
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
    
    if (row >= 0 && row < widget.controller.rows && 
        col >= 0 && col < widget.controller.columns) {
      return (row, col);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        
        return GestureDetector(
          onPanStart: (details) => _handlePointerDown(details.localPosition, size),
          onPanUpdate: (details) => _handlePointerUpdate(details.localPosition, size),
          onPanEnd: (_) => _handlePointerUp(),
          onTapDown: (details) => _handlePointerDown(details.localPosition, size),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: size,
                painter: _GridPainter(
                  controller: widget.controller,
                  executor: widget.executor,
                  accentColor: widget.accentColor ?? AppTheme.accent,
                  pulseValue: _pulseAnimation.value,
                  staticPicture: _staticGridPicture,
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
  final Color accentColor;
  final double pulseValue;
  final ui.Picture? staticPicture;
  final Function(ui.Picture) onPictureCreated;

  _GridPainter({
    required this.controller,
    required this.executor,
    required this.accentColor,
    required this.pulseValue,
    required this.staticPicture,
    required this.onPictureCreated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / controller.columns;
    final cellHeight = size.height / controller.rows;

    // 1. Draw or Create Static Content (Background and Walls)
    if (staticPicture != null) {
      canvas.drawPicture(staticPicture!);
    } else {
      final recorder = ui.PictureRecorder();
      final staticCanvas = Canvas(recorder);
      _drawStaticGrid(staticCanvas, size, cellWidth, cellHeight);
      final picture = recorder.endRecording();
      onPictureCreated(picture);
      canvas.drawPicture(picture);
    }

    // 2. Draw Dynamic Content (Explored Set and Path)
    _drawExploredStates(canvas, cellWidth, cellHeight);
    _drawPath(canvas, cellWidth, cellHeight);
    _drawCurrentNode(canvas, cellWidth, cellHeight);
  }

  void _drawStaticGrid(Canvas canvas, Size size, double cellWidth, double cellHeight) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0;

    // Background
    paint.color = AppTheme.surfaceLow;
    canvas.drawRect(Offset.zero & size, paint);

    // Draw grid nodes (primarily walls and anchors)
    for (int r = 0; r < controller.rows; r++) {
      for (int c = 0; c < controller.columns; c++) {
        final node = controller.grid[r][c];
        final rect = Rect.fromLTWH(
          c * cellWidth + 0.5, 
          r * cellHeight + 0.5, 
          cellWidth - 1, 
          cellHeight - 1
        );

        if (node.type == NodeType.wall) {
          paint.color = AppTheme.cellWall;
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
        } else if (node.type == NodeType.start) {
          paint.color = AppTheme.cellStart;
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
        } else if (node.type == NodeType.goal) {
          paint.color = AppTheme.cellGoal;
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
        } else if (node.type == NodeType.weight) {
          paint.color = AppTheme.cellWeight;
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
        }
      }
    }
    
    // Grid Lines (Subtle)
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
      
    for (int i = 0; i <= controller.columns; i++) {
      canvas.drawLine(Offset(i * cellWidth, 0), Offset(i * cellWidth, size.height), linePaint);
    }
    for (int i = 0; i <= controller.rows; i++) {
      canvas.drawLine(Offset(0, i * cellHeight), Offset(size.width, i * cellHeight), linePaint);
    }
  }

  void _drawExploredStates(Canvas canvas, double cellWidth, double cellHeight) {
    if (executor == null || executor!.exploredSet.isEmpty) return;
    
    final paint = Paint()
      ..color = accentColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
      
    for (final state in executor!.exploredSet) {
      if (controller.grid[state.row][state.column].type != NodeType.empty) continue;
      
      final rect = Rect.fromLTWH(
        state.column * cellWidth + 0.5, 
        state.row * cellHeight + 0.5, 
        cellWidth - 1, 
        cellHeight - 1
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
    }
  }

  void _drawPath(Canvas canvas, double cellWidth, double cellHeight) {
    if (executor == null || executor!.pathSet.isEmpty) return;
    
    final paint = Paint()
      ..color = AppTheme.cyan
      ..style = PaintingStyle.fill;
      
    final shadowPaint = Paint()
      ..color = AppTheme.cyan.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (final state in executor!.pathSet) {
      if (controller.grid[state.row][state.column].type == NodeType.start || 
          controller.grid[state.row][state.column].type == NodeType.goal) {
        continue;
      }
          
      final rect = Rect.fromLTWH(
        state.column * cellWidth + 0.5, 
        state.row * cellHeight + 0.5, 
        cellWidth - 1, 
        cellHeight - 1
      );
      canvas.drawRect(rect, shadowPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
    }
  }

  void _drawCurrentNode(Canvas canvas, double cellWidth, double cellHeight) {
    final current = executor?.lastStep?.currentState;
    if (current == null) return;
    
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    final pulsePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.8)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, pulseValue);
      
    final center = Offset(
      current.column * cellWidth + cellWidth / 2,
      current.row * cellHeight + cellHeight / 2
    );
    
    canvas.drawCircle(center, cellWidth / 3, pulsePaint);
    canvas.drawCircle(center, 2.0, paint);
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue || 
           oldDelegate.staticPicture != staticPicture ||
           oldDelegate.executor?.lastStep != executor?.lastStep ||
           oldDelegate.controller != controller;
  }
}
