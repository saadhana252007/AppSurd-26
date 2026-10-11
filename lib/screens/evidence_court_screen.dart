import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class EvidenceCourtScreen extends StatelessWidget {
  final String reportId;

  const EvidenceCourtScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EVIDENCE COURT')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.gavel, size: 42, color: AppTheme.lime),
          const SizedBox(height: 16),
          Text('REPORT: $reportId'),
          const SizedBox(height: 20),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AWAITING EVIDENCE',
                    style: TextStyle(color: AppTheme.text),
                  ),
                  SizedBox(height: 8),
                  Text('No verification report has been generated.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
