class DashboardStats {
  const DashboardStats({
    this.projectsTotal = 0,
    this.projectsActive = 0,
    this.projectsOnHold = 0,
    this.projectsRagRed = 0,
    this.tasksOpen = 0,
    this.tasksCompleted = 0,
    this.runningNow = 0,
  });

  final int projectsTotal;
  final int projectsActive;
  final int projectsOnHold;
  final int projectsRagRed;
  final int tasksOpen;
  final int tasksCompleted;
  final int runningNow;
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
    this.stage,
    this.project,
    this.priority,
    this.parentTask,
    this.description,
  });

  final String name;
  final String? subject;
  final String? status;
  final String? stage;
  final String? project;
  final String? priority;
  final String? parentTask;
  final String? description;

  String get title => (subject?.isNotEmpty == true) ? subject! : name;
  String get displayStage =>
      (stage?.isNotEmpty == true) ? stage! : (status ?? '');

  factory TaskSummary.fromJson(Map<String, dynamic> json) {
    return TaskSummary(
      name: '${json['name'] ?? ''}',
      subject: json['subject']?.toString(),
      status: json['status']?.toString(),
      stage: json['stage']?.toString(),
      project: json['project']?.toString(),
      priority: json['priority']?.toString(),
      parentTask: json['parent_task']?.toString(),
      description: json['description']?.toString(),
    );
  }
}

class TicketSummary {
  const TicketSummary({
    required this.name,
    this.subject,
    this.status,
    this.project,
    this.priority,
  });

  final String name;
  final String? subject;
  final String? status;
  final String? project;
  final String? priority;

  String get title => (subject?.isNotEmpty == true) ? subject! : name;

  factory TicketSummary.fromJson(Map<String, dynamic> json) {
    return TicketSummary(
      name: '${json['name'] ?? ''}',
      subject: json['subject']?.toString(),
      status: json['status']?.toString(),
      project: json['project']?.toString(),
      priority: json['priority']?.toString(),
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
