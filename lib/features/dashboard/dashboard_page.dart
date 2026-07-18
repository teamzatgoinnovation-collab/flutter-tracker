import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/tracker_repo.dart';
import '../../models/tracker_models.dart';
import '../../widgets/sign_out_action.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String _status = 'Loading…';
  DashboardStats? _stats;
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
      final repo = ref.read(trackerRepoProvider);
      await repo.pingHub();
      final stats = await repo.dashboardSummary();
      if (!mounted) return;
      setState(() {
        _stats = stats;
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
    final stats = _stats;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
            if (stats != null)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(label: 'Projects', value: '${stats.projectsTotal}'),
                  _StatCard(label: 'Open tasks', value: '${stats.tasksOpen}'),
                  _StatCard(label: 'Done', value: '${stats.tasksCompleted}'),
                  _StatCard(label: 'Running', value: '${stats.runningNow}'),
                ],
              ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Projects'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/projects'),
            ),
            ListTile(
              leading: const Icon(Icons.task_alt),
              title: const Text('Tasks'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/tasks'),
            ),
            ListTile(
              leading: const Icon(Icons.confirmation_number),
              title: const Text('Tickets'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/tickets'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
