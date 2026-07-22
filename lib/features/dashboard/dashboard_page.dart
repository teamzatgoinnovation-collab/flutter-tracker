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
  List<Map<String, dynamic>> _running = [];
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
      final running = await repo.listRunningNow();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _running = running;
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final connected = _status == 'Connected';

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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                visualDensity: VisualDensity.compact,
                avatar: Icon(
                  connected ? Icons.check_circle : Icons.cloud_outlined,
                  size: 16,
                  color: connected
                      ? const Color(0xFF15803D)
                      : scheme.onSurfaceVariant,
                ),
                label: Text(_status),
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            if (stats != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                  color: theme.cardTheme.color ?? scheme.surface,
                ),
                child: Row(
                  children: [
                    _MetricCell(
                      label: 'Projects',
                      value: '${stats.projectsTotal}',
                    ),
                    _MetricDivider(),
                    _MetricCell(
                      label: 'Open tasks',
                      value: '${stats.tasksOpen}',
                    ),
                    _MetricDivider(),
                    _MetricCell(
                      label: 'Done',
                      value: '${stats.tasksCompleted}',
                    ),
                    _MetricDivider(),
                    _MetricCell(
                      label: 'Running',
                      value: '${stats.runningNow}',
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Who is running',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (_running.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 22,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_off_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No active timers.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < _running.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        dense: true,
                        title: Text('${_running[i]['user'] ?? '—'}'),
                        subtitle: Text(
                          '${_running[i]['task'] ?? _running[i]['project'] ?? _running[i]['name'] ?? '—'}',
                        ),
                        trailing: Text(
                          _fmtElapsed(_running[i]['elapsed_seconds']),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Navigate',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: const Text('Projects'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/projects'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.task_alt),
                    title: const Text('Tasks'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/tasks'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.confirmation_number_outlined),
                    title: const Text('Tickets'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/tickets'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.55),
    );
  }
}

String _fmtElapsed(dynamic sec) {
  final s = (sec is num ? sec.toInt() : int.tryParse('$sec') ?? 0).clamp(
    0,
    1 << 31,
  );
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final r = s % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
}
