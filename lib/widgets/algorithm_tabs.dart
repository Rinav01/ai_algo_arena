import 'package:flutter/material.dart';

class AlgorithmTabsWidget extends StatefulWidget {
  final Function(String) onAlgorithmSelected;
  final String initialAlgorithm;

  const AlgorithmTabsWidget({
    super.key,
    required this.onAlgorithmSelected,
    this.initialAlgorithm = 'BFS',
  });

  @override
  State<AlgorithmTabsWidget> createState() => _AlgorithmTabsWidgetState();
}

class _AlgorithmTabsWidgetState extends State<AlgorithmTabsWidget> {
  late String _selectedAlgorithm;

  final algorithms = const [
    {'name': 'BFS', 'icon': '📊', 'fullName': 'Breadth-First Search'},
    {'name': 'DFS', 'icon': '🔗', 'fullName': 'Depth-First Search'},
    {'name': 'A*', 'icon': '🚀', 'fullName': 'A* Search'},
    {'name': 'Dijkstra', 'icon': '🔍', 'fullName': 'Dijkstra\'s Algorithm'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedAlgorithm = widget.initialAlgorithm;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ...algorithms.map((algo) {
            final isSelected = _selectedAlgorithm == algo['name'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedAlgorithm = algo['name']!);
                  widget.onAlgorithmSelected(algo['name']!);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFA500)
                        : const Color(0xFF0E2233),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFFA500)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(algo['icon']!, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        algo['name']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
