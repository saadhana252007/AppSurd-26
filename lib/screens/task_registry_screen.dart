
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_theme.dart';

class TaskRegistryScreen extends StatefulWidget {
  const TaskRegistryScreen({super.key});

  @override
  State<TaskRegistryScreen> createState() => _TaskRegistryScreenState();
}

class _TaskRegistryScreenState extends State<TaskRegistryScreen> {
  static const String storageKey = 'prooflock_tasks';

  List<Map<String, dynamic>> tasks = [];
  bool loading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(storageKey);

    if (stored != null) {
      try {
        final decoded = jsonDecode(stored) as List;
        tasks = decoded
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      } catch (_) {
        tasks = [];
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(tasks));
  }

  Future<void> createTask() async {
    final titleController = TextEditingController();
    final criteriaController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Create Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  hintText: 'e.g. Complete physics assignment',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: criteriaController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Verification criteria',
                  hintText: 'What must the evidence demonstrate?',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final criteria = criteriaController.text.trim();

              if (title.isEmpty || criteria.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Enter both title and criteria.'),
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext, {
                'title': title,
                'criteria': criteria,
              });
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    titleController.dispose();
    criteriaController.dispose();

    if (result == null || !mounted) return;

    final task = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'title': result['title']!,
      'criteria': result['criteria']!,
      'status': 'Pending',
      'createdAt': DateTime.now().toIso8601String(),
    };

    setState(() {
      tasks.insert(0, task);
    });

    await saveTasks();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = tasks.where((task) {
      final title = (task['title'] ?? '').toString().toLowerCase();
      return title.contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TASK REGISTRY',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR PROOF OBLIGATIONS',
                    style: TextStyle(
                      color: AppTheme.lime,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) {
                      setState(() => searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search tasks',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredTasks.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fact_check_outlined,
                        size: 42,
                        color: AppTheme.secondaryText,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        searchQuery.isEmpty
                            ? 'No tasks registered'
                            : 'No matching tasks',
                        style: const TextStyle(
                          color: AppTheme.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Create a task and define how it will be verified.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: filteredTasks.length,
                separatorBuilder: (_, _) =>
                const SizedBox(height: 9),
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];

                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: const Icon(
                        Icons.assignment_outlined,
                        color: AppTheme.lime,
                      ),
                      title: Text(
                        task['title'].toString(),
                        style: const TextStyle(
                          color: AppTheme.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${task['status']}\n${task['criteria']}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.secondaryText,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppTheme.secondaryText,
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/task-detail',
                          arguments: task['id'].toString(),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createTask,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }
}
