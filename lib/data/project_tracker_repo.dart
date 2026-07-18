import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zatgo_dart_sdk/zatgo_dart_sdk.dart';

import '../models/project_tracker_models.dart';
import '../services/session.dart';

class ProjectTrackerRepo {
  ProjectTrackerRepo(this._session);

  final ProjectTrackerSession _session;

  Future<void> pingHub() async {
    await _session.store.callMethod(ZatGoApiMethods.healthPing);
  }

  Future<DashboardStats> dashboardSummary() async {
    final env = await _session.store.callMethod(
      ZatGoApiMethods.tasksList,
      args: {'mine': 1, 'page': 1, 'page_size': 100},
    );
    final rows = _tasks(env.data);
    final open = rows
        .where((t) => t.status != 'Completed' && t.status != 'Cancelled')
        .length;
    return DashboardStats(
      tasksOpen: open,
      projectsActive:
          rows.map((t) => t.project).whereType<String>().toSet().length,
      tasksCompleted: rows.where((t) => t.status == 'Completed').length,
    );
  }

  Future<({List<ProjectSummary> rows, int? total})> listProjects({
    int page = 1,
    int pageSize = 50,
  }) async {
    final env = await _session.store.callMethod(
      ZatGoApiMethods.projectsList,
      args: {'page': page, 'page_size': pageSize},
    );
    return (rows: _projects(env.data), total: _total(env.meta));
  }

  Future<ProjectSummary> getProject(String name) async {
    final env = await _session.store.callMethod(
      ZatGoApiMethods.projectsGet,
      args: {'name': name},
    );
    final data = env.data;
    if (data is! Map) {
      throw ZatGoApiError(code: 'EMPTY', message: 'Project not found');
    }
    return ProjectSummary.fromJson(Map<String, dynamic>.from(data));
  }

  Future<({List<TaskSummary> rows, int? total})> listTasks({
    int page = 1,
    int pageSize = 50,
    String? project,
    bool mine = true,
  }) async {
    final args = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      'mine': mine ? 1 : 0,
    };
    if (project != null && project.isNotEmpty) {
      args['project'] = project;
    }
    final env = await _session.store.callMethod(
      ZatGoApiMethods.tasksList,
      args: args,
    );
    return (rows: _tasks(env.data), total: _total(env.meta));
  }

  Future<TaskSummary> getTask(String name) async {
    final env = await _session.store.callMethod(
      ZatGoApiMethods.tasksGet,
      args: {'name': name},
    );
    final data = env.data;
    if (data is! Map) {
      throw ZatGoApiError(code: 'EMPTY', message: 'Task not found');
    }
    return TaskSummary.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> updateTaskStatus(String name, String status) async {
    await _session.store.callMethod(
      ZatGoApiMethods.updateTaskStatus,
      args: {'name': name, 'status': status},
    );
  }

  Future<Map<String, dynamic>?> activeSession() async {
    final env = await _session.store.callMethod(ZatGoApiMethods.activityActive);
    final data = env.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  Future<void> startActivity(String task) async {
    await _session.store.callMethod(
      ZatGoApiMethods.activityStart,
      args: {'task': task},
    );
  }

  Future<void> pauseActivity() async {
    await _session.store.callMethod(ZatGoApiMethods.activityPause);
  }

  Future<void> nextActivity(String task) async {
    await _session.store.callMethod(
      ZatGoApiMethods.activityNext,
      args: {'task': task},
    );
  }

  Future<List<ApprovalItem>> listApprovalsMine() async {
    return [];
  }

  Future<void> approve(String name) async {}

  Future<void> reject(String name, {String? reason}) async {}

  List<ProjectSummary> _projects(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => ProjectSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<TaskSummary> _tasks(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => TaskSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  int? _total(Map<String, dynamic>? meta) {
    if (meta == null) return null;
    final t = meta['total'];
    if (t is int) return t;
    if (t is num) return t.toInt();
    return null;
  }
}

final projectTrackerRepoProvider = Provider<ProjectTrackerRepo>((ref) {
  final session = ref.watch(projectTrackerSessionProvider);
  return ProjectTrackerRepo(session);
});
