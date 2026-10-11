
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class CommandCenterScreen extends StatelessWidget {
  const CommandCenterScreen({super.key});

  Widget sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: AppTheme.secondaryText,
      ),
    );
  }

  Widget panel({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppTheme.elevated),
      ),
      child: child,
    );
  }

  Widget metric(String value, String label) {
    return Expanded(
      child: panel(
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppTheme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget activity(
      String title,
      String id,
      String status,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: panel(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    id,
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.lime),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                status.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.lime,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PROOFLOCK',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune, size: 19),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
          children: [
            sectionLabel('Command Center'),
            const SizedBox(height: 6),
            const Text(
              'Proof, not promises.',
              style: TextStyle(
                color: AppTheme.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Turn tasks into verifiable outcomes.',
              style: TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 13),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/tasks');
              },
              icon: const Icon(Icons.add, size: 17),
              label: const Text(
                'Create Task',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                metric('0', 'Active Tasks'),
                const SizedBox(width: 6),
                metric('0', 'Verified Tasks'),
                const SizedBox(width: 6),
                metric('0', 'Needs Correction'),
              ],
            ),

            const SizedBox(height: 12),
            panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      sectionLabel('Integrity Index'),
                      const Text(
                        '--',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: const LinearProgressIndicator(
                      value: 0,
                      minHeight: 4,
                      backgroundColor: AppTheme.background,
                      color: AppTheme.lime,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Based on approved verification runs.',
                    style: TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            panel(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        sectionLabel('Current Streak'),
                        const SizedBox(height: 5),
                        const Text(
                          '0 Days',
                          style: TextStyle(
                            color: AppTheme.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 34,
                    color: AppTheme.elevated,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        sectionLabel('Daily Target'),
                        const SizedBox(height: 5),
                        const Text(
                          '0 / 1 Verified',
                          style: TextStyle(
                            color: AppTheme.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            sectionLabel('Recent Activity'),
            const SizedBox(height: 8),
            panel(
              child: const Text(
                'No verification events recorded yet. '
                    'Create a task and submit evidence to get started.',
                style: TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
