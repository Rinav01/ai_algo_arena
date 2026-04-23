import 'package:flutter/material.dart';
import 'package:algo_arena/painters/grid_painter.dart';
import 'package:algo_arena/state/grid_controller.dart';
import 'package:algo_arena/widgets/control_panel.dart';
import 'package:algo_arena/widgets/stat_card.dart';

class VisualizerScreen extends StatefulWidget {
  const VisualizerScreen({super.key});

  @override
  State<VisualizerScreen> createState() => _VisualizerScreenState();
}

class _VisualizerScreenState extends State<VisualizerScreen> {
  late final GridController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GridController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF08111B),
                  Color(0xFF0B1D2C),
                  Color(0xFF07131F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1080;

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(20.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 40,
                      ),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: _buildMainColumn(context),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 4,
                                  child: ControlPanel(controller: _controller),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildMainColumn(context),
                                const SizedBox(height: 20),
                                ControlPanel(controller: _controller),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pathfinding Visualizer',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Week 1 foundation: interactive grid, polished stats, and a control system ready for BFS, DFS, Dijkstra, and A*.',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 20),
        _buildStats(),
        const SizedBox(height: 20),
        _buildGridCard(context),
      ],
    );
  }

  Widget _buildStats() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.75,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(
          label: 'Grid Size',
          value: '${_controller.rows} x ${_controller.columns}',
          accent: const Color(0xFF22C55E),
          icon: Icons.grid_view_rounded,
        ),
        StatCard(
          label: 'Total Nodes',
          value: _controller.totalNodes.toString(),
          accent: const Color(0xFF38BDF8),
          icon: Icons.hub_rounded,
        ),
        StatCard(
          label: 'Walls Painted',
          value: _controller.wallCount.toString(),
          accent: const Color(0xFFF97316),
          icon: Icons.square_rounded,
        ),
        StatCard(
          label: 'Walkable Nodes',
          value: _controller.walkableCount.toString(),
          accent: const Color(0xFFFACC15),
          icon: Icons.route_rounded,
        ),
      ],
    );
  }

  Widget _buildGridCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Interactive Grid',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(999.0),
                  ),
                  child: Text(
                    'Tap or drag to paint',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final cellSize = maxWidth / _controller.columns;
                final gridHeight = cellSize * _controller.rows;

                return GestureDetector(
                  onPanDown: (details) =>
                      _paintFromOffset(details.localPosition, cellSize),
                  onPanUpdate: (details) =>
                      _paintFromOffset(details.localPosition, cellSize),
                  onTapUp: (details) =>
                      _paintFromOffset(details.localPosition, cellSize),
                  child: Container(
                    width: maxWidth,
                    height: gridHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: GridPainter(
                        grid: _controller.grid,
                        cellSize: cellSize,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _paintFromOffset(Offset offset, double cellSize) {
    final row = (offset.dy / cellSize).floor();
    final column = (offset.dx / cellSize).floor();
    _controller.handleCellInteraction(row, column);
  }
}
