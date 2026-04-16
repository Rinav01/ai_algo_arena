import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AlgorithmInfoSheet extends StatelessWidget {
  final String algorithmName;
  final String description;
  final List<String> timeComplexity;
  final List<String> spaceComplexity;
  final String category;
  final List<String> advantages;
  final List<String> disadvantages;

  const AlgorithmInfoSheet({
    super.key,
    required this.algorithmName,
    required this.description,
    required this.timeComplexity,
    required this.spaceComplexity,
    required this.category,
    required this.advantages,
    required this.disadvantages,
  });

  static Future<void> show(BuildContext context, AlgorithmInfoSheet sheet) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E2233),
      builder: (context) => sheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                algorithmName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(color: Colors.grey[400], height: 1.6),
          ),
          const SizedBox(height: 24),
          _buildSection('Category', category),
          const SizedBox(height: 16),
          _buildComplexitySection('Time Complexity', timeComplexity),
          const SizedBox(height: 12),
          _buildComplexitySection('Space Complexity', spaceComplexity),
          const SizedBox(height: 24),
          _buildListSection('Advantages', advantages, Colors.green),
          const SizedBox(height: 12),
          _buildListSection('Disadvantages', disadvantages, Colors.red),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(content, style: TextStyle(color: Colors.grey[300])),
        ),
      ],
    );
  }

  Widget _buildComplexitySection(String title, List<String> complexities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...complexities.map((complexity) {
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Text(
                complexity,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildListSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...items.map((item) {
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6.w,
                  height: 6.h,
                  margin: EdgeInsets.only(top: 6.h),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(color: Colors.grey[300], height: 1.4),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
