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
      final result = await ref.read(projectTrackerRepoProvider).listTasks();
      if (!mounted) return;
      setState(() {
        _rows = result.rows;
        _total = result.total;
        _status = 'Connected${_total != null ? ' · $_total total' : ''}';
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
            const SizedBox(height: 8),
            if (_rows.isEmpty && !_busy)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No tasks returned.')),
              ),
            ..._rows.map(
              (t) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(t.title),
                  subtitle: Text('${t.project ?? '—'} · ${t.priority ?? '—'}'),
                  trailing: StatusChip(label: t.status ?? '—'),
                  onTap: () => context.go('/tasks/${t.name}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
