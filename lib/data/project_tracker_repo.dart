import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zatgo_dart_sdk/zatgo_dart_sdk.dart';

import '../models/project_tracker_models.dart';
import '../services/session.dart';

class ProjectTrackerRepo {
  ProjectTrackerRepo(this._session);

  final ProjectTrackerSession _session;

  Future<void> pingHub() async {
    await _session.store.callMethod(ZatGoApiMethods.projectTrackerPing);
  }

  Future<DashboardStats> dashboardSummary() async {
    final env = await _session.store.callMethod(
      ZatGoApiMethods.projectsDashboardSummary,
    );
    final data = env.data;
    return DashboardStats.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : null,
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
  }) async {
    final args = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (project != null && project.isNotEmpty) {
      args['filters'] = {'project': project};
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

  Future<List<ApprovalItem>> listApprovalsMine() async {
    final env = await _session.store.callMethod(
      ZatGoApiMethods.approvalsListMine,
    );
    final data = env.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => ApprovalItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map>()
          .map((e) => ApprovalItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<void> approve(String name) async {
    await _session.store.callMethod(
      ZatGoApiMethods.approvalsApprove,
      args: {'name': name},
    );
  }

  Future<void> reject(String name, {String? reason}) async {
    await _session.store.callMethod(
      ZatGoApiMethods.approvalsReject,
      args: {'name': name, 'reason': ?reason},
    );
  }

  List<ProjectSummary> _projects(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => ProjectSummary.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.name.isNotEmpty)
        .toList();
  }

  List<TaskSummary> _tasks(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => TaskSummary.fromJson(Map<String, dynamic>.from(e)))
        .where((t) => t.name.isNotEmpty)
        .toList();
  }

  int? _total(Map<String, dynamic>? meta) {
    final t = meta?['total'];
    if (t is num) return t.toInt();
    return int.tryParse('$t');
  }
}

final projectTrackerRepoProvider = Provider<ProjectTrackerRepo>((ref) {
  return ProjectTrackerRepo(ref.watch(projectTrackerSessionProvider));
});
