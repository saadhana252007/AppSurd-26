import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDatabaseService {
  SupabaseDatabaseService._();

  static final SupabaseDatabaseService instance =
  SupabaseDatabaseService._();

  final SupabaseClient _client = Supabase.instance.client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in first.');
    }
    return user.id;
  }

  // CREATE TASK
  Future<Map<String, dynamic>> createTask({
    required String title,
    required String criteria,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();

    final result = await _client
        .from('prooflock_tasks')
        .insert({
      'id': id,
      'user_id': _userId,
      'title': title,
      'criteria': criteria,
      'status': 'Pending',
    })
        .select()
        .single();

    return _mapTask(result);
  }

  // FETCH ALL TASKS
  Future<List<Map<String, dynamic>>> getTasks() async {
    final result = await _client
        .from('prooflock_tasks')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return result.map((row) => _mapTask(row)).toList();
  }

  // FETCH ONE TASK — WITH DEBUGGING
  Future<Map<String, dynamic>?> getTask(String taskId) async {
    final result = await _client
        .from('prooflock_tasks')
        .select()
        .eq('id', taskId)
        .eq('user_id', _userId)
        .maybeSingle();

    return result == null ? null : _mapTask(result);
  }

  // UPDATE TASK STATUS
  Future<void> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    await _client
        .from('prooflock_tasks')
        .update({
      'status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    })
        .eq('id', taskId)
        .eq('user_id', _userId);
  }

  // DELETE TASK
  Future<void> deleteTask(String taskId) async {
    await _client
        .from('prooflock_tasks')
        .delete()
        .eq('id', taskId)
        .eq('user_id', _userId);
  }

  // SAVE VERIFICATION REPORT
  Future<void> saveReport(Map<String, dynamic> report) async {
    await _client.from('prooflock_reports').insert({
      'id': report['reportId']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      'user_id': _userId,
      'task_id': report['taskId'].toString(),
      'verdict': report['verdict'] ?? 'UNABLE_TO_VERIFY',
      'summary': report['summary'],
      'confidence': report['confidence'],
      'evidence_text': report['evidenceText'],
      'evidence_url': report['evidenceUrl'],
      'image_name': report['imageName'],
      'criteria_results': report['criteriaResults'] ?? [],
      'missing_criteria': report['missingCriteria'] ?? [],
      'challenges': report['challenges'] ?? [],
      'follow_up_question': report['followUpQuestion'],
      'limitations': report['limitations'] ?? [],
    });
  }

  // FETCH ALL REPORTS
  Future<List<Map<String, dynamic>>> getReports() async {
    final result = await _client
        .from('prooflock_reports')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return result.map((row) => _mapReport(row)).toList();
  }

  // FETCH ONE REPORT
  Future<Map<String, dynamic>?> getReport(String reportId) async {
    final result = await _client
        .from('prooflock_reports')
        .select()
        .eq('id', reportId)
        .eq('user_id', _userId)
        .maybeSingle();

    return result == null ? null : _mapReport(result);
  }

  Map<String, dynamic> _mapTask(Map<String, dynamic> row) {
    return {
      ...row,
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    };
  }

  Map<String, dynamic> _mapReport(Map<String, dynamic> row) {
    return {
      ...row,
      'reportId': row['id'],
      'taskId': row['task_id'],
      'evidenceText': row['evidence_text'],
      'evidenceUrl': row['evidence_url'],
      'imageName': row['image_name'],
      'criteriaResults': row['criteria_results'] ?? [],
      'missingCriteria': row['missing_criteria'] ?? [],
      'challenges': row['challenges'] ?? [],
      'followUpQuestion': row['follow_up_question'],
      'createdAt': row['created_at'],
    };
  }
}