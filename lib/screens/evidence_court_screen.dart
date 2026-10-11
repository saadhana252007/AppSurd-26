import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_theme.dart';

class EvidenceCourtScreen extends StatefulWidget {
  final String reportId;

  const EvidenceCourtScreen({super.key, required this.reportId});

  @override
  State<EvidenceCourtScreen> createState() => _EvidenceCourtScreenState();
}

class _EvidenceCourtScreenState extends State<EvidenceCourtScreen> {
  Map<String, dynamic>? report;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  Future<void> loadReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('prooflock_ledger');

      if (raw != null) {
        final decoded = jsonDecode(raw);

        if (decoded is List) {
          final records = decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();

          for (final record in records) {
            final id = (record['id'] ?? '').toString();
            final taskId = (record['taskId'] ?? '').toString();

            if (id == widget.reportId || taskId == widget.reportId) {
              report = record;
              break;
            }
          }
        }
      }
    } catch (_) {
      report = null;
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  bool get isVerified => report?['status'] == 'Verified';

  String get verdict {
    if (report == null) return 'REPORT NOT FOUND';
    return isVerified ? 'APPROVED' : 'INSUFFICIENT EVIDENCE';
  }

  Color get verdictColor => isVerified ? AppTheme.lime : AppTheme.secondaryText;

  Widget panel({
    required String heading,
    required Widget child,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.elevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: AppTheme.lime),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  heading.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget bodyText(String value) {
    return Text(
      value,
      style: const TextStyle(
        color: AppTheme.secondaryText,
        fontSize: 12,
        height: 1.6,
      ),
    );
  }

  String formatTimestamp(dynamic value) {
    if (value == null) return 'Not recorded';

    final date = DateTime.tryParse(value.toString())?.toLocal();
    if (date == null) return 'Not recorded';

    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final evidence = (report?['evidence'] ?? '').toString();
    final title = (report?['title'] ?? 'Untitled task').toString();
    final matched = report?['matchedCriteriaWords'];

    final matchedWords = matched is List
        ? matched.map((word) => word.toString()).toList()
        : <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EVIDENCE COURT',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh report',
            onPressed: loadReport,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : report == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.search_off,
                      size: 44,
                      color: AppTheme.secondaryText,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Report not found',
                      style: TextStyle(
                        color: AppTheme.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    bodyText(
                      'No saved ledger event matches this report ID. '
                      'Open a report using an existing ledger event ID.',
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Icon(Icons.gavel, size: 42, color: AppTheme.lime),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'VERIFICATION REPORT',
                    style: TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Center(
                  child: Text(
                    'REPORT: ${widget.reportId}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                panel(
                  heading: 'Court Verdict',
                  icon: isVerified
                      ? Icons.verified_outlined
                      : Icons.rule_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verdict,
                        style: TextStyle(
                          color: verdictColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      bodyText(
                        isVerified
                            ? 'The current text-matching check passed. '
                                  'This confirms a match with the configured '
                                  'rule, not independent proof of real-world '
                                  'completion.'
                            : 'The submitted evidence did not pass the '
                                  'current text-matching check. Review the '
                                  'task criteria and submit more relevant '
                                  'evidence.',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Recorded: ${formatTimestamp(report!['timestamp'])}',
                        style: const TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                panel(
                  heading: 'Task Under Review',
                  icon: Icons.fact_check_outlined,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                panel(
                  heading: 'Submitted Evidence',
                  icon: Icons.description_outlined,
                  child: bodyText(
                    evidence.isEmpty
                        ? 'No evidence was saved with this report.'
                        : evidence,
                  ),
                ),
                panel(
                  heading: 'Rule Check',
                  icon: Icons.rule,
                  child: matchedWords.isEmpty
                      ? bodyText(
                          'No matching criteria words were recorded. '
                          'This does not establish why any real-world '
                          'task was or was not completed.',
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: matchedWords.map((word) {
                            return Chip(
                              label: Text(
                                word,
                                style: const TextStyle(fontSize: 10),
                              ),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: AppTheme.background,
                              side: const BorderSide(color: AppTheme.elevated),
                            );
                          }).toList(),
                        ),
                ),
                panel(
                  heading: 'Corrective Challenges',
                  icon: Icons.build_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final challenge
                          in (isVerified
                              ? <String>[
                                  'Review the task criteria before relying '
                                      'on this result.',
                                  'Keep any supporting files or links '
                                      'available for independent review.',
                                ]
                              : <String>[
                                  'Identify the specific criteria not '
                                      'addressed by your evidence.',
                                  'Add concrete details describing the work '
                                      'completed and its outcome.',
                                  'Attach relevant supporting material and '
                                      'submit the revised evidence.',
                                ]))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.arrow_forward,
                                size: 15,
                                color: AppTheme.lime,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: bodyText(challenge)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Return to Previous Screen'),
                ),
              ],
            ),
    );
  }
}
