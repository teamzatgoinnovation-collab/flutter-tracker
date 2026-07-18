class DashboardStats {
  const DashboardStats({
    this.projectsTotal = 0,
    this.projectsActive = 0,
    this.projectsOnHold = 0,
    this.projectsRagRed = 0,
    this.tasksOpen = 0,
    this.tasksCompleted = 0,
  });

  final int projectsTotal;
  final int projectsActive;
  final int projectsOnHold;
  final int projectsRagRed;
  final int tasksOpen;
  final int tasksCompleted;

  factory DashboardStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DashboardStats();
    int n(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return DashboardStats(
      projectsTotal: n(json['projects_total']),
      projectsActive: n(json['projects_active']),
      projectsOnHold: n(json['projects_on_hold']),
      projectsRagRed: n(json['projects_rag_red']),
      tasksOpen: n(json['tasks_open']),
      tasksCompleted: n(json['tasks_completed']),
    );
  }
}

class ProjectSummary {
  const ProjectSummary({
    required this.name,
    this.projectName,
    this.status,
    this.ragStatus,
    this.company,
    this.description,
  });

  final String name;
  final String? projectName;
  final String? status;
  final String? ragStatus;
  final String? company;
  final String? description;

  String get title => (projectName?.isNotEmpty == true) ? projectName! : name;

  factory ProjectSummary.fromJson(Map<String, dynamic> json) {
    return ProjectSummary(
      name: '${json['name'] ?? ''}',
      projectName: json['project_name']?.toString(),
      status: json['status']?.toString(),
      ragStatus: json['rag_status']?.toString(),
      company: json['company']?.toString(),
      description: json['description']?.toString(),
    );
  }
}

class TaskSummary {
  const TaskSummary({
    required this.name,
    this.subject,
    this.status,
    this.project,
    this.priority,
    this.description,
  });

  final String name;
  final String? subject;
  final String? status;
  final String? project;
  final String? priority;
  final String? description;

  String get title => (subject?.isNotEmpty == true) ? subject! : name;

  factory TaskSummary.fromJson(Map<String, dynamic> json) {
    return TaskSummary(
      name: '${json['name'] ?? ''}',
      subject: json['subject']?.toString(),
      status: json['status']?.toString(),
      project: json['project']?.toString(),
      priority: json['priority']?.toString(),
      description: json['description']?.toString(),
    );
  }
}

class ApprovalItem {
  const ApprovalItem({
    required this.name,
    this.entityType,
    this.entityName,
    this.status,
    this.requestedBy,
  });

  final String name;
  final String? entityType;
  final String? entityName;
  final String? status;
  final String? requestedBy;

  factory ApprovalItem.fromJson(Map<String, dynamic> json) {
    return ApprovalItem(
      name: '${json['name'] ?? ''}',
      entityType: json['entity_type']?.toString(),
      entityName: json['entity_name']?.toString(),
      status: json['status']?.toString(),
      requestedBy:
          json['requested_by']?.toString() ?? json['owner']?.toString(),
    );
  }
}

const kDefaultTaskStatuses = [
  'Open',
  'Working',
  'Pending Review',
  'Completed',
  'Cancelled',
];
