import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/project_tracker_repo.dart';
import '../../models/project_tracker_models.dart';
import '../../widgets/sign_out_action.dart';
import '../../widgets/status_chip.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  String _status = 'Loading…';
  List<TaskSummary> _rows = [];
  int? _total;
  bool _busy = false;
  String? _selected;
  Map<String, dynamic>? _active;

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
      final result = await repo.listTasks(mine: true);
      final active = await repo.activeSession();
      if (!mounted) return;
      setState(() {
        _rows = result.rows;
        _total = result.total;
        _active = active;
        _status = 'Connected${_total != null ? ' · $_total total' : ''}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'API error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLabel = _active == null
        ? 'None'
        : '${_active!['status']}: ${_active!['task'] ?? _active!['name']}';
    final running = _active?['status'] == 'Running';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
          const SignOutAction(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(_status),
            if (_busy) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active session', style: Theme.of(context).textTheme.labelMedium),
                    Text(activeLabel, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton(
                          onPressed: _busy || _selected == null || running
                              ? null
                              : () => _run(
                                    () => ref
                                        .read(projectTrackerRepoProvider)
                                        .startActivity(_selected!),
                                  ),
                          child: const Text('Start'),
                        ),
                        FilledButton.tonal(
                          onPressed: _busy || !running
                              ? null
                              : () => _run(
                                    () => ref
                                        .read(projectTrackerRepoProvider)
                                        .pauseActivity(),
                                  ),
                          child: const Text('Pause'),
                        ),
                        OutlinedButton(
                          onPressed: _busy || _selected == null
                              ? null
                              : () => _run(
                                    () => ref
                                        .read(projectTrackerRepoProvider)
                                        .nextActivity(_selected!),
                                  ),
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_rows.isEmpty && !_busy)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No tasks returned.')),
              ),
            ..._rows.map(
              (t) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: _selected == t.name
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: ListTile(
                  title: Text(t.title),
                  subtitle: Text('${t.project ?? '—'} · ${t.priority ?? '—'}'),
                  trailing: StatusChip(label: t.status ?? '—'),
                  selected: _selected == t.name,
                  onTap: () => setState(() => _selected = t.name),
                  onLongPress: () => context.go('/tasks/${t.name}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
