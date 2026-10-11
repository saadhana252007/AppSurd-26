
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_theme.dart';

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> events = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> readList(String key) {
      try {
        final raw = prefs.getString(key);
        if (raw == null) return [];

        final decoded = jsonDecode(raw);
        if (decoded is! List) return [];

        return decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } catch (_) {
        return [];
      }
    }

    final savedTasks = readList('prooflock_tasks');
    final savedEvents = readList('prooflock_ledger');

    savedEvents.sort((a, b) {
      final aTime =
          DateTime.tryParse('${a['timestamp'] ?? ''}') ??
              DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          DateTime.tryParse('${b['timestamp'] ?? ''}') ??
              DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    if (!mounted) return;

    setState(() {
      tasks = savedTasks;
      events = savedEvents;
      loading = false;
    });
  }

  int get activeCount =>
      tasks.where((t) => t['status'] == 'Pending').length;

  int get verifiedCount =>
      tasks.where((t) => t['status'] == 'Verified').length;

  int get correctionCount =>
      tasks.where((t) => t['status'] == 'Needs Correction').length;

  int get resolvedCount => verifiedCount + correctionCount;

  int get integrityIndex =>
      resolvedCount == 0 ? 0 : (verifiedCount * 100 / resolvedCount).round();

  int get verifiedToday {
    final now = DateTime.now();

    return tasks.where((task) {
      if (task['status'] != 'Verified') return false;

      final raw = task['lastCheckedAt'];
      if (raw == null) return false;

      final date = DateTime.tryParse(raw.toString());
      return date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  int get currentStreak {
    final verifiedDays = <String>{};

    for (final task in tasks) {
      if (task['status'] != 'Verified') continue;

      final raw = task['lastCheckedAt'];
      if (raw == null) continue;

      final date = DateTime.tryParse(raw.toString());
      if (date != null) {
        verifiedDays.add(
          '${date.year}-${date.month}-${date.day}',
        );
      }
    }

    var day = DateTime.now();
    String key(DateTime d) => '${d.year}-${d.month}-${d.day}';

    if (!verifiedDays.contains(key(day))) {
      day = day.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (verifiedDays.contains(key(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }

    return streak;
  }

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

  String formatTime(dynamic raw) {
    if (raw == null) return 'Time unavailable';

    final date = DateTime.tryParse(raw.toString())?.toLocal();
    if (date == null) return 'Time unavailable';

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day}/${date.month}/${date.year}  $hour:$minute $period';
  }

  Widget activity(Map<String, dynamic> event) {
    final title = (event['title'] ?? 'Untitled task').toString();
    final status = (event['status'] ?? 'Unknown').toString();
    final id = (event['taskId'] ?? event['id'] ?? '').toString();
    final isVerified = status == 'Verified';

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: panel(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(
              isVerified ? Icons.verified_outlined : Icons.rule_outlined,
              color: isVerified ? AppTheme.lime : AppTheme.secondaryText,
              size: 18,
            ),
            const SizedBox(width: 9),
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
                    '${event['event'] ?? 'Verification event'} · ${formatTime(event['timestamp'])}',
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 9,
                    ),
                  ),
                  if (id.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Task ID: $id',
                      style: const TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              status.toUpperCase(),
              style: TextStyle(
                color: isVerified ? AppTheme.lime : AppTheme.secondaryText,
                fontSize: 8,
                fontWeight: FontWeight.w700,
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
            tooltip: 'Refresh dashboard',
            onPressed: loadData,
            icon: const Icon(Icons.refresh, size: 19),
          ),
        ],
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: loadData,
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
                  metric('$activeCount', 'Active Tasks'),
                  const SizedBox(width: 6),
                  metric('$verifiedCount', 'Verified Tasks'),
                  const SizedBox(width: 6),
                  metric('$correctionCount', 'Needs Correction'),
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
                        Text(
                          resolvedCount == 0 ? '--' : '$integrityIndex%',
                          style: const TextStyle(
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
                      child: LinearProgressIndicator(
                        value: resolvedCount == 0
                            ? 0
                            : integrityIndex / 100,
                        minHeight: 4,
                        backgroundColor: AppTheme.background,
                        color: AppTheme.lime,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Based on completed verification outcomes.',
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
                          Text(
                            '$currentStreak ${currentStreak == 1 ? 'Day' : 'Days'}',
                            style: const TextStyle(
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
                          Text(
                            '${verifiedToday > 0 ? 1 : 0} / 1 Verified',
                            style: const TextStyle(
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
              if (events.isEmpty)
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
                )
              else
                ...events.take(3).map(activity),
            ],
          ),
        ),
      ),
    );
  }
}
