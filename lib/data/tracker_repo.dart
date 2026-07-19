import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zatgo_dart_sdk/zatgo_dart_sdk.dart';

import '../models/tracker_models.dart';
import '../services/session.dart';

class TrackerRepo {
  TrackerRepo(this._session);

  final TrackerSession _session;

  Future<void> pingHub() async {
    await _session.store.callMethod(ZatGoApiMethods.healthPing);
  }

  Future<DashboardStats> dashboardSummary() async {
    final projects = await listProjects(pageSize: 200);
    final tasks = await listTasks(mine: true, pageSize: 200);
    final running = await listRunningNow();
    final open = tasks.rows
        .where((t) => t.status != 'Completed' && t.status != 'Cancelled')
        .length;
    return DashboardStats(
      projectsTotal: projects.rows.length,
      projectsActive: projects.rows
          .where((p) => p.status == 'Open' || p.status == 'Completed')
          .length,
      tasksOpen: open,
      tasksCompleted: tasks.rows.where((t) => t.status == 'Completed').length,
      runningNow: running.length,
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

  Future<ProjectSummary> createProject(String projectName) async {
    final env = await _session.store.callMethod(
      ZatGoApiMethods.projectsCreate,
      args: {'project_name': projectName},
    );
    final data = env.data;
    if (data is! Map) {
      throw ZatGoApiError(code: 'EMPTY', message: 'Create project failed');
    }
    return ProjectSummary.fromJson(Map<String, dynamic>.from(data));
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
    bool mine = false,
    bool team = false,
    bool tree = true,
  }) async {
    final args = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (mine) 'mine': 1,
      if (team) 'team': 1,
      if (tree) 'tree': 1,
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

  Future<TaskSummary> createTask({
    required String subject,
    String? project,
    String? parentTask,
  }) async {
    final args = <String, dynamic>{'subject': subject};
    if (project != null && project.isNotEmpty) args['project'] = project;
    if (parentTask != null && parentTask.isNotEmpty) {
      args['parent_task'] = parentTask;
    }
    final env = await _session.store.callMethod(
      ZatGoApiMethods.tasksCreate,
      args: args,
    );
    final data = env.data;
    if (data is! Map) {
      throw ZatGoApiError(code: 'EMPTY', message: 'Create task failed');
    }
    return TaskSummary.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> assignTask(String name, String user) async {
    await _session.store.callMethod(
      ZatGoApiMethods.hierarchyAssign,
      args: {'doctype': 'Task', 'name': name, 'user': user},
    );
  }

  Future<void> assignTicket(String name, String user) async {
    await _session.store.callMethod(
      ZatGoApiMethods.hierarchyAssign,
      args: {'doctype': 'Issue', 'name': name, 'user': user},
    );
  }

  Future<List<Map<String, dynamic>>> myTreePeople() async {
    final env = await _session.store.callMethod(
      ZatGoApiMethods.hierarchyMyTree,
    );
    final data = env.data;
    if (data is! Map) return [];
    final people = data['people'];
    if (people is! List) return [];
    return people
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
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

  Future<({List<TicketSummary> rows, int? total})> listTickets({
    int page = 1,
    int pageSize = 50,
    bool mine = false,
    bool team = false,
    String? project,
    String? status,
  }) async {
    final args = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (mine) 'mine': 1,
      if (team) 'team': 1,
    };
    if (project != null && project.isNotEmpty) args['project'] = project;
    if (status != null && status.isNotEmpty) args['status'] = status;
    final env = await _session.store.callMethod(
      ZatGoApiMethods.ticketsList,
      args: args,
    );
    return (rows: _tickets(env.data), total: _total(env.meta));
  }

  Future<Map<String, dynamic>> getFilterPresets() async {
    final env = await _session.store.callMethod(
      ZatGoApiMethods.filtersGetPresets,
    );
    final data = env.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'last': null, 'presets': []};
  }

  Future<void> setLastFilter({
    required String scope,
    String? project,
    String? status,
  }) async {
    await _session.store.callMethod(
      ZatGoApiMethods.filtersSetLast,
      args: {
        'scope': scope,
        if (project != null && project.isNotEmpty) 'project': project,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
  }

  Future<List<Map<String, dynamic>>> hoursByProject({
    required String fromDate,
    required String toDate,
  }) async {
    final env = await _session.store.callMethod(
      ZatGoApiMethods.hoursByProject,
      args: {'from_date': fromDate, 'to_date': toDate, 'page_size': 100},
    );
    final data = env.data;
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> hoursByUser({
    required String fromDate,
    required String toDate,
  }) async {
    final env = await _session.store.callMethod(
      ZatGoApiMethods.hoursByUser,
      args: {'from_date': fromDate, 'to_date': toDate, 'page_size': 100},
    );
    final data = env.data;
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<TicketSummary> createTicket(String subject) async {
    final env = await _session.store.callMethod(
      ZatGoApiMethods.ticketsCreate,
      args: {'subject': subject},
    );
    final data = env.data;
    if (data is! Map) {
      throw ZatGoApiError(code: 'EMPTY', message: 'Create ticket failed');
    }
    return TicketSummary.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Map<String, dynamic>?> activeSession() async {
    final env = await _session.store.callMethod(ZatGoApiMethods.activityActive);
    final data = env.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  Future<List<Map<String, dynamic>>> listRunningNow() async {
    final env = await _session.store.callMethod(
      ZatGoApiMethods.activityRunningNow,
    );
    final data = env.data;
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
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

  Future<void> stopActivity() async {
    await _session.store.callMethod(ZatGoApiMethods.activityStop);
  }

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

  List<TicketSummary> _tickets(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => TicketSummary.fromJson(Map<String, dynamic>.from(e)))
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

final trackerRepoProvider = Provider<TrackerRepo>((ref) {
  final session = ref.watch(trackerSessionProvider);
  return TrackerRepo(session);
});
