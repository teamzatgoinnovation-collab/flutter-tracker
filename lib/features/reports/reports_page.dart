import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tracker_repo.dart';
import '../../widgets/sign_out_action.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  String _status = 'Loading…';
  late String _from;
  late String _to;
  List<Map<String, dynamic>> _byProject = [];
  List<Map<String, dynamic>> _byUser = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    _to =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _status = 'Loading…');
    try {
      final repo = ref.read(trackerRepoProvider);
      final p = await repo.hoursByProject(fromDate: _from, toDate: _to);
      final u = await repo.hoursByUser(fromDate: _from, toDate: _to);
      if (!mounted) return;
      setState(() {
        _byProject = p;
        _byUser = u;
        _status = 'Connected';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hours'),
        actions: const [SignOutAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            _status,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Date range',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _from,
                  decoration: const InputDecoration(labelText: 'From'),
                  onChanged: (v) => _from = v,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: _to,
                  decoration: const InputDecoration(labelText: 'To'),
                  onChanged: (v) => _to = v,
                ),
              ),
              IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'By project',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (_byProject.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No hours in range.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ..._byProject.map(
              (r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  title: Text(
                    '${r['project'] ?? '—'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Text(
                    '${(r['hours'] as num?)?.toStringAsFixed(2) ?? '0'} h',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text('${r['entries'] ?? 0} entries'),
                ),
              ),
            ),
          const SizedBox(height: 22),
          Text(
            'By user',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (_byUser.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No hours in range.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ..._byUser.map(
              (r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  title: Text(
                    '${r['employee_name'] ?? r['user'] ?? r['employee'] ?? '—'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Text(
                    '${(r['hours'] as num?)?.toStringAsFixed(2) ?? '0'} h',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${r['user'] ?? ''} · ${r['entries'] ?? 0} entries',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
