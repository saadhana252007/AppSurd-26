import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_theme.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  static const String ledgerKey = 'prooflock_ledger';

  List<Map<String, dynamic>> events = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(ledgerKey);

    List<Map<String, dynamic>> loaded = [];

    if (stored != null) {
      try {
        final decoded = jsonDecode(stored) as List;
        loaded = decoded
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      } catch (_) {
        loaded = [];
      }
    }

    if (!mounted) return;

    setState(() {
      events = loaded;
      loading = false;
    });
  }

  String formatTimestamp(dynamic value) {
    if (value == null) return 'Time unavailable';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return 'Time unavailable';

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/${local.year}  $hour:$minute';
  }

  void openEvidenceCourt(Map<String, dynamic> event) {
    final reportId = (event['id'] ?? '').toString();

    if (reportId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This event has no report ID.')),
      );
      return;
    }

    Navigator.of(context).pushNamed('/evidence-court', arguments: reportId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'VERIFICATION LEDGER',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loadEvents,
            tooltip: 'Refresh ledger',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : events.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 46,
                      color: AppTheme.secondaryText,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No ledger events yet',
                      style: TextStyle(
                        color: AppTheme.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Submit evidence for a task to record its '
                      'verification outcome here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: loadEvents,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadEvents,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'RECENT VERIFICATION EVENTS',
                    style: TextStyle(
                      color: AppTheme.lime,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${events.length} recorded event${events.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final event in events)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.fact_check_outlined,
                                  color: AppTheme.lime,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    (event['title'] ??
                                            event['event'] ??
                                            'Verification event')
                                        .toString(),
                                    style: const TextStyle(
                                      color: AppTheme.text,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  event['status'] == 'Verified'
                                      ? Icons.check_circle
                                      : Icons.info_outline,
                                  color: event['status'] == 'Verified'
                                      ? AppTheme.lime
                                      : AppTheme.secondaryText,
                                  size: 16,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              (event['event'] ?? 'Evidence submitted')
                                  .toString(),
                              style: const TextStyle(
                                color: AppTheme.secondaryText,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _tag(
                                  'STATUS: ${(event['status'] ?? 'UNKNOWN').toString().toUpperCase()}',
                                ),
                                _tag(formatTimestamp(event['timestamp'])),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'TASK ID: ${(event['taskId'] ?? 'Unavailable').toString()}',
                              style: const TextStyle(
                                color: AppTheme.secondaryText,
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => openEvidenceCourt(event),
                                icon: const Icon(Icons.gavel, size: 17),
                                label: const Text('Open Evidence Court'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppTheme.elevated),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.text,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
