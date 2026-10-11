import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_theme.dart';
import '../services/gemini_verification_service.dart';
import '../services/supabase_database_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final database = SupabaseDatabaseService.instance;
  final evidenceController = TextEditingController();
  final urlController = TextEditingController();

  Map<String, dynamic>? task;
  Uint8List? imageBytes;
  String? imageName;
  String imageMimeType = 'image/jpeg';

  bool loading = true;
  bool submitting = false;
  String? resultMessage;
  String? lastReportId;

  @override
  void initState() {
    super.initState();
    loadTask();
  }

  // LOAD TASK FROM SUPABASE
  Future<void> loadTask() async {
    try {
      final result = await database.getTask(widget.taskId);

      if (!mounted) return;

      setState(() {
        task = result;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load task: $error')),
      );
    }
  }

  // SELECT IMAGE EVIDENCE
  Future<void> pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1800,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final filename = picked.name.toLowerCase();

      if (!mounted) return;

      setState(() {
        imageBytes = bytes;
        imageName = picked.name;
        imageMimeType = filename.endsWith('.png')
            ? 'image/png'
            : filename.endsWith('.webp')
            ? 'image/webp'
            : 'image/jpeg';
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not select image: $error')),
      );
    }
  }

  // SUBMIT EVIDENCE, ASSESS WITH GEMINI, SAVE TO SUPABASE
  Future<void> submitEvidence() async {
    if (task == null || submitting) return;

    final evidence = evidenceController.text.trim();
    final url = urlController.text.trim();

    if (evidence.isEmpty && url.isEmpty && imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Provide text, an image, or a supporting URL.'),
        ),
      );
      return;
    }

    setState(() {
      submitting = true;
      resultMessage = null;
    });

    try {
      final assessment = await GeminiVerificationService.verify(
        taskTitle: (task!['title'] ?? 'Untitled task').toString(),
        criteria: (task!['criteria'] ?? '').toString(),
        evidenceText: evidence,
        evidenceUrl: url.isEmpty ? null : url,
        imageBytes: imageBytes,
        imageMimeType: imageMimeType,
      );

      final verdict = assessment['verdict'].toString();

      final status = switch (verdict) {
        'VERIFIED' => 'Verified',
        'NEEDS_CORRECTION' => 'Needs Correction',
        _ => 'Unable to Verify',
      };

      final reportId =
      DateTime.now().microsecondsSinceEpoch.toString();

      // Update the task in Supabase.
      await database.updateTaskStatus(
        taskId: widget.taskId,
        status: status,
      );

      // Save the verification report in Supabase.
      await database.saveReport({
        'reportId': reportId,
        'taskId': widget.taskId,
        'title': task!['title'],
        'verdict': verdict,
        'status': status,
        'evidenceText': evidence,
        'evidenceUrl': url.isEmpty ? null : url,
        'imageName': imageName,
        'summary': assessment['summary'],
        'confidence': assessment['confidence'],
        'criteriaResults': assessment['criteriaResults'] ?? [],
        'missingCriteria': assessment['missingCriteria'] ?? [],
        'challenges': assessment['challenges'] ?? [],
        'followUpQuestion': assessment['followUpQuestion'],
        'limitations': assessment['limitations'] ?? [],
      });

      if (!mounted) return;

      final challenges =
      (assessment['challenges'] as List? ?? [])
          .map((item) => item.toString())
          .toList();

      final confidence = assessment['confidence'];
      final confidenceText = confidence is num
          ? '${(confidence * 100).round()}%'
          : 'Unavailable';

      setState(() {
        task = {
          ...task!,
          'status': status,
        };

        lastReportId = reportId;

        resultMessage =
        '$verdict\n\n'
            '${assessment['summary']}\n\n'
            'Assessment confidence: $confidenceText\n\n'
            '${challenges.isEmpty ? 'No corrective challenges returned.' : 'Corrective challenges:\n• ${challenges.join('\n• ')}'}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assessment and report saved to Supabase.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        resultMessage = 'Assessment or database save failed:\n$error';
      });
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  @override
  void dispose() {
    evidenceController.dispose();
    urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('TASK DETAIL')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.assignment_late_outlined,
                  size: 44,
                  color: AppTheme.secondaryText,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Task not found',
                  style: TextStyle(
                    color: AppTheme.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The task may have been deleted, or you may be signed '
                      'in with a different account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Return to Tasks'),
                ),
                TextButton(
                  onPressed: loadTask,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('TASK DETAIL'),
      ),
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
            style: const TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 11,
            ),
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
                  Text((task!['criteria'] ?? '').toString()),
                  const SizedBox(height: 14),
                  const Text(
                    'CURRENT STATUS',
                    style: TextStyle(
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (task!['status'] ?? 'Pending')
                        .toString()
                        .toUpperCase(),
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
            'TEXT EVIDENCE',
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
              hintText: 'Describe the evidence and what it demonstrates...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'IMAGE EVIDENCE',
            style: TextStyle(
              color: AppTheme.lime,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: submitting ? null : pickImage,
            icon: const Icon(Icons.image_outlined),
            label: Text(
              imageName == null ? 'Attach Image' : imageName!,
            ),
          ),
          if (imageBytes != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                imageBytes!,
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
            TextButton(
              onPressed: submitting
                  ? null
                  : () {
                setState(() {
                  imageBytes = null;
                  imageName = null;
                  imageMimeType = 'image/jpeg';
                });
              },
              child: const Text('Remove image'),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'SUPPORTING URL (OPTIONAL)',
            style: TextStyle(
              color: AppTheme.lime,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: urlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'https://github.com/your-project',
              prefixIcon: Icon(Icons.link),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The URL is supplied as context to Gemini. This app does not '
                'fetch the linked page, and an image or URL alone may not '
                'prove real-world completion.',
            style: TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: submitting ? null : submitEvidence,
            icon: submitting
                ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(Icons.fact_check_outlined),
            label: Text(
              submitting
                  ? 'Assessing with Gemini...'
                  : 'Submit & Verify',
            ),
          ),
          if (resultMessage != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: SelectableText(
                  resultMessage!,
                  style: const TextStyle(
                    color: AppTheme.text,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            if (lastReportId != null)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    '/evidence-court',
                    arguments: lastReportId,
                  );
                },
                icon: const Icon(Icons.gavel),
                label: const Text('Open Evidence Court'),
              ),
          ],
        ],
      ),
    );
  }
}