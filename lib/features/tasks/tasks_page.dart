import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/tracker_repo.dart';
import '../../models/tracker_models.dart';
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
  bool _team = false;
  String? _selected;
  Map<String, dynamic>? _active;
  int _elapsed = 0;
  Timer? _timer;
  final _subject = TextEditingController();
  List<Map<String, dynamic>> _people = [];
  String? _assignUser;
  bool _canManage = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _subject.dispose();
    super.dispose();
  }

  void _syncTimer() {
    _timer?.cancel();
    if (_active?['status'] == 'Running') {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += 1);
      });
    }
  }

  String _fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final r = s % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _status = 'Loading…';
    });
    try {
      final repo = ref.read(trackerRepoProvider);
      final result = await repo.listTasks(mine: !_team, team: _team);
      final active = await repo.activeSession();
      final caps = await repo.myCapabilities();
      final people = await repo.myTreePeople();
      await repo.setLastFilter(scope: _team ? 'team' : 'mine');
      if (!mounted) return;
      setState(() {
        _rows = result.rows;
        _total = result.total;
        _active = active;
        _people = people;
        _canManage = caps['can_manage_work'] == true;
        _assignUser ??= people.isNotEmpty ? '${people.first['user']}' : null;
        _elapsed = (active?['elapsed_seconds'] as num?)?.toInt() ?? 0;
        _status = 'Connected${_total != null ? ' · $_total total' : ''}';
      });
      _syncTimer();
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  List<({TaskSummary task, int depth})> _tree() {
    final byParent = <String, List<TaskSummary>>{};
    final roots = <TaskSummary>[];
    for (final row in _rows) {
      final p = row.parentTask ?? '';
      if (p.isEmpty) {
        roots.add(row);
      } else {
        byParent.putIfAbsent(p, () => []).add(row);
      }
    }
    final out = <({TaskSummary task, int depth})>[];
    void walk(List<TaskSummary> list, int depth) {
      for (final t in list) {
        out.add((task: t, depth: depth));
        walk(byParent[t.name] ?? const [], depth + 1);
      }
    }

    walk(roots, 0);
    final seen = out.map((e) => e.task.name).toSet();
    for (final t in _rows) {
      if (!seen.contains(t.name)) out.add((task: t, depth: 0));
    }
    return out;
  }

  Color? _priorityTone(String? priority, ColorScheme scheme) {
    switch ((priority ?? '').toLowerCase()) {
      case 'urgent':
      case 'high':
        return scheme.errorContainer;
      case 'medium':
      case 'normal':
        return scheme.secondaryContainer;
      case 'low':
        return scheme.surfaceContainerHighest;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activeLabel = _active == null
        ? 'None'
        : '${_active!['status']}: ${_active!['task'] ?? _active!['name']} · ${_fmt(_elapsed)}';
    final running = _active?['status'] == 'Running';
    final tree = _tree();

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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text(
              _status,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (_busy) const LinearProgressIndicator(),
            const SizedBox(height: 10),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('My Work')),
                ButtonSegment(value: true, label: Text('Team')),
              ],
              selected: {_team},
              onSelectionChanged: (s) {
                setState(() => _team = s.first);
                _refresh();
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Active session',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeLabel,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed: _busy || _selected == null || running
                              ? null
                              : () => _run(
                                  () => ref
                                      .read(trackerRepoProvider)
                                      .startActivity(_selected!),
                                ),
                          child: const Text('Start'),
                        ),
                        FilledButton.tonal(
                          onPressed: _busy || !running
                              ? null
                              : () => _run(
                                  () => ref
                                      .read(trackerRepoProvider)
                                      .pauseActivity(),
                                ),
                          child: const Text('Pause'),
                        ),
                        OutlinedButton(
                          onPressed: _busy || _selected == null
                              ? null
                              : () => _run(
                                  () => ref
                                      .read(trackerRepoProvider)
                                      .nextActivity(_selected!),
                                ),
                          child: const Text('Next'),
                        ),
                        OutlinedButton(
                          onPressed: _busy || _active == null
                              ? null
                              : () => _run(
                                  () => ref
                                      .read(trackerRepoProvider)
                                      .stopActivity(),
                                ),
                          child: const Text('Stop'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_canManage) ...[
              const SizedBox(height: 22),
              Text(
                'Manage',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _subject,
                decoration: InputDecoration(
                  labelText: _selected == null
                      ? 'New task subject (Draft)'
                      : 'New subtask under selection',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () {
                        final subject = _subject.text.trim();
                        if (subject.isEmpty) return;
                        _run(() async {
                          await ref
                              .read(trackerRepoProvider)
                              .createTask(
                                subject: subject,
                                parentTask: _selected,
                              );
                          _subject.clear();
                        });
                      },
                child: const Text('Create task'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _assignUser,
                decoration: const InputDecoration(
                  labelText: 'Assign to',
                ),
                items: [
                  for (final p in _people)
                    DropdownMenuItem(
                      value: '${p['user']}',
                      child: Text(
                        '${p['full_name'] ?? p['user']}${p['is_self'] == true ? ' (you)' : ''}',
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _assignUser = v),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy || _selected == null || _assignUser == null
                    ? null
                    : () {
                        final user = _assignUser!;
                        _run(() async {
                          await ref
                              .read(trackerRepoProvider)
                              .assignTask(_selected!, user);
                        });
                      },
                child: const Text('Assign selected'),
              ),
            ],
            const SizedBox(height: 22),
            Text(
              'Task list',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (tree.isEmpty && !_busy)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No tasks returned.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ...tree.map((item) {
              final stage = item.task.displayStage;
              final selected = _selected == item.task.name;
              final priority = item.task.priority;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                clipBehavior: Clip.antiAlias,
                color: selected ? scheme.primaryContainer : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: selected
                        ? scheme.primary.withValues(alpha: 0.55)
                        : scheme.outlineVariant.withValues(alpha: 0.55),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.only(
                    left: 16.0 + item.depth * 16,
                    right: 16,
                  ),
                  title: Text(
                    item.task.title,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${item.task.project ?? '—'} · $stage'
                    '${priority != null && priority.isNotEmpty ? ' · $priority' : ''}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusChip(label: stage),
                      if (priority != null && priority.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        StatusChip(
                          label: priority,
                          tone: _priorityTone(priority, scheme),
                        ),
                      ],
                    ],
                  ),
                  selected: selected,
                  onTap: () => setState(() => _selected = item.task.name),
                  onLongPress: () => context.go('/tasks/${item.task.name}'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
