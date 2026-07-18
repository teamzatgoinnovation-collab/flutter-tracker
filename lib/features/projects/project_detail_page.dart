import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/project_tracker_repo.dart';
import '../../models/project_tracker_models.dart';
import '../../widgets/status_chip.dart';

class ProjectDetailPage extends ConsumerStatefulWidget {
  const ProjectDetailPage({super.key, required this.name});

  final String name;

  @override
  ConsumerState<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends ConsumerState<ProjectDetailPage> {
  String _status = 'Loading…';
  ProjectSummary? _project;
  List<TaskSummary> _tasks = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _status = 'Loading…';
    });
    try {
      final repo = ref.read(projectTrackerRepoProvider);
      final project = await repo.getProject(widget.name);
      final tasks = await repo.listTasks(project: widget.name, pageSize: 50);
      if (!mounted) return;
      setState(() {
        _project = project;
        _tasks = tasks.rows;
        _status = 'Connected';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'API error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _project;
    return Scaffold(
      appBar: AppBar(
        title: Text(p?.title ?? widget.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/projects'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(_status),
            if (_busy) const LinearProgressIndicator(),
            if (p != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          StatusChip(label: p.status ?? '—'),
                          StatusChip(
                            label: 'RAG ${p.ragStatus ?? '—'}',
                            tone: ragColor(
                              p.ragStatus,
                              Theme.of(context).colorScheme,
                            ),
                          ),
                        ],
                      ),
                      if (p.company != null) ...[
                        const SizedBox(height: 8),
                        Text('Company: ${p.company}'),
                      ],
                      if (p.description != null &&
                          p.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(p.description!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Tasks', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_tasks.isEmpty)
                const Text('No tasks for this project.')
              else
                ..._tasks.map(
                  (t) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(t.title),
                      subtitle: Text(t.status ?? '—'),
                      onTap: () => context.go('/tasks/${t.name}'),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
