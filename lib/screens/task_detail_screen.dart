import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_theme.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  static const tasksKey = 'prooflock_tasks';
  static const ledgerKey = 'prooflock_ledger';

  final evidenceController = TextEditingController();

  Map<String, dynamic>? task;
  bool loading = true;
  bool submitting = false;
  String? resultMessage;

  @override
  void initState() {
    super.initState();
    loadTask();
  }

  Future<void> loadTask() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(tasksKey);

    if (stored != null) {
      try {
        final items = (jsonDecode(stored) as List).map(
          (item) => Map<String, dynamic>.from(item as Map),
        );

        for (final item in items) {
          if (item['id']?.toString() == widget.taskId) {
            task = item;
            break;
          }
        }
      } catch (_) {
        task = null;
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> submitEvidence() async {
    if (task == null || submitting) return;

    final evidence = evidenceController.text.trim();

    if (evidence.length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter at least 20 characters of evidence.'),
        ),
      );
      return;
    }

    setState(() => submitting = true);

    try {
      final criteria = (task!['criteria'] ?? '').toString();

      // Transparent demo rule:
      // Evidence must contain at least one meaningful word
      // from the task's verification criteria.
      final words = criteria
          .toLowerCase()
          .split(RegExp(r'[^a-z0-9]+'))
          .where((word) => word.length >= 4)
          .toSet();

      final evidenceLower = evidence.toLowerCase();
      final matchedWords = words
          .where((word) => evidenceLower.contains(word))
          .toList();

      final verified = matchedWords.isNotEmpty;
      final status = verified ? 'Verified' : 'Needs Correction';

      final prefs = await SharedPreferences.getInstance();

      final storedTasks = prefs.getString(tasksKey);
      final List<dynamic> taskList = storedTasks == null
          ? []
          : jsonDecode(storedTasks) as List;

      final updatedTasks = taskList.map((item) {
        final current = Map<String, dynamic>.from(item as Map);

        if (current['id']?.toString() == widget.taskId) {
          current['status'] = status;
          current['lastEvidence'] = evidence;
          current['lastCheckedAt'] = DateTime.now().toIso8601String();
        }

        return current;
      }).toList();

      await prefs.setString(tasksKey, jsonEncode(updatedTasks));

      final storedLedger = prefs.getString(ledgerKey);
      final List<dynamic> events = storedLedger == null
          ? []
          : jsonDecode(storedLedger) as List;

      events.insert(0, {
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'taskId': widget.taskId,
        'title': task!['title'],
        'event': 'Evidence submitted',
        'status': status,
        'evidence': evidence,
        'matchedCriteriaWords': matchedWords,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await prefs.setString(ledgerKey, jsonEncode(events));

      if (!mounted) return;

      setState(() {
        task!['status'] = status;
        task!['lastEvidence'] = evidence;
        resultMessage = verified
            ? 'The evidence passed the configured text-matching check.'
            : 'No meaningful criteria words matched. Revise your evidence and try again.';
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save evidence: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  @override
  void dispose() {
    evidenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('TASK DETAIL')),
        body: const Center(
          child: Text('Task not found. Return to the Task Registry.'),
        ),
      );
    }

    final status = (task!['status'] ?? 'Pending').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('TASK DETAIL')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'PROOF CHAIN',
            style: TextStyle(
              color: AppTheme.lime,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            task!['title'].toString(),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Task ID: ${widget.taskId}',
            style: const TextStyle(color: AppTheme.secondaryText, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VERIFICATION CRITERIA',
                    style: TextStyle(
                      color: AppTheme.lime,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(task!['criteria'].toString()),
                  const SizedBox(height: 14),
                  const Text(
                    'Current status',
                    style: TextStyle(color: AppTheme.secondaryText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.lime,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'SUBMIT TEXT EVIDENCE',
            style: TextStyle(
              color: AppTheme.lime,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: evidenceController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Describe your evidence and what it demonstrates...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Demo verification checks for at least one meaningful word '
            'shared with the criteria. This does not prove that the '
            'claimed work was actually completed.',
            style: TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: submitting ? null : submitEvidence,
            icon: const Icon(Icons.fact_check_outlined),
            label: Text(submitting ? 'Checking...' : 'Submit & Verify'),
          ),
          if (resultMessage != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  resultMessage!,
                  style: const TextStyle(color: AppTheme.text, height: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
