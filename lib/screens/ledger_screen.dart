import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('INTEGRITY LEDGER')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'APPEND-ONLY EVENT LOG',
            style: TextStyle(color: AppTheme.lime, letterSpacing: 1.5),
          ),
          const SizedBox(height: 24),
          const Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppTheme.secondaryText,
          ),
          const SizedBox(height: 12),
          const Center(child: Text('No ledger events yet')),
          const Center(child: Text('Every verification will leave a trace.')),
        ],
      ),
    );
  }
}
