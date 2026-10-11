import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class TaskDetailScreen extends StatelessWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TASK DETAIL')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('PROOF CHAIN', style: TextStyle(color: AppTheme.lime)),
          const SizedBox(height: 12),
          Text('Task ID: $taskId'),
          const SizedBox(height: 20),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Proof DNA criteria will appear here.'),
            ),
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Evidence and verification history'),
            ),
          ),
          FilledButton(onPressed: () {}, child: const Text('Submit evidence')),
        ],
      ),
    );
  }
}
