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
  bool _canReview = false;

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
      final repo = ref.read(trackerRepoProvider);
      final task = await repo.getTask(widget.name);
      final caps = await repo.myCapabilities();
      if (!mounted) return;
      setState(() {
        _task = task;
        _canReview = caps['can_review'] == true;
        _status = 'Connected';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'API error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _run(Future<void> Function() action, String okMsg) async {
    setState(() => _busy = true);
    try {
      await action();
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(okMsg)));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Failed: $e';
        _busy = false;
      });
    }
  }

  Future<void> _rework() async {
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Request rework'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(labelText: 'Note'),
            maxLines: 3,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Rework'),
            ),
          ],
        );
      },
    );
    if (note == null || note.isEmpty) return;
    await _run(
      () => ref.read(trackerRepoProvider).requestRework(widget.name, note),
      'Rework requested',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _task;
    final stage = t?.displayStage ?? '—';
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
                      StatusChip(label: stage),
                      if (t.description != null &&
                          t.description!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(t.description!),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (stage == 'In Progress')
                            FilledButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(
                                      () => ref
                                          .read(trackerRepoProvider)
                                          .submitForReview(widget.name),
                                      'Submitted for review',
                                    ),
                              child: const Text('Ready for Review'),
                            ),
                          if (stage == 'Ready for Review' && _canReview) ...[
                            FilledButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(
                                      () => ref
                                          .read(trackerRepoProvider)
                                          .approveTask(widget.name),
                                      'Approved',
                                    ),
                              child: const Text('Approve'),
                            ),
                            FilledButton.tonal(
                              onPressed: _busy ? null : _rework,
                              child: const Text('Rework'),
                            ),
                          ],
                        ],
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
