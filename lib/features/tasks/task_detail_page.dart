import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/tracker_repo.dart';
import '../../models/tracker_models.dart';
import '../../widgets/status_chip.dart';

class TaskDetailPage extends ConsumerStatefulWidget {
  const TaskDetailPage({super.key, required this.name});

  final String name;

  @override
  ConsumerState<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> {
  String _status = 'Loading…';
  TaskSummary? _task;
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
      final task = await ref
          .read(trackerRepoProvider)
          .getTask(widget.name);
      if (!mounted) return;
      setState(() {
        _task = task;
        _status = 'Connected';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'API error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setStatus(String next) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(trackerRepoProvider)
          .updateTaskStatus(widget.name, next);
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Updated ${widget.name} → $next')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Update failed: $e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _task;
    final current = t?.status ?? 'Open';
    return Scaffold(
      appBar: AppBar(
        title: Text(t?.title ?? widget.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/tasks'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(_status),
            if (_busy) const LinearProgressIndicator(),
            if (t != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Project: ${t.project ?? '—'}'),
                      Text('Priority: ${t.priority ?? '—'}'),
                      const SizedBox(height: 12),
                      StatusChip(label: current),
                      if (t.description != null &&
                          t.description!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(t.description!),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Update status',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: kDefaultTaskStatuses.contains(current)
                            ? current
                            : 'Open',
                        items: kDefaultTaskStatuses
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: _busy
                            ? null
                            : (v) {
                                if (v != null) {
                                  _setStatus(v);
                                }
                              },
                      ),
                    ],
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
