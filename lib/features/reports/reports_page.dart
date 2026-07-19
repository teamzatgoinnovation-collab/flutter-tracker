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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hours'),
        actions: const [SignOutAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_status, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
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
          const SizedBox(height: 16),
          Text('By project', style: Theme.of(context).textTheme.titleMedium),
          ..._byProject.map(
            (r) => ListTile(
              title: Text('${r['project'] ?? '—'}'),
              trailing: Text('${(r['hours'] as num?)?.toStringAsFixed(2) ?? '0'} h'),
              subtitle: Text('${r['entries'] ?? 0} entries'),
            ),
          ),
          if (_byProject.isEmpty) const Text('No hours in range.'),
          const SizedBox(height: 16),
          Text('By user', style: Theme.of(context).textTheme.titleMedium),
          ..._byUser.map(
            (r) => ListTile(
              title: Text('${r['employee_name'] ?? r['user'] ?? r['employee'] ?? '—'}'),
              trailing: Text('${(r['hours'] as num?)?.toStringAsFixed(2) ?? '0'} h'),
              subtitle: Text('${r['user'] ?? ''} · ${r['entries'] ?? 0} entries'),
            ),
          ),
          if (_byUser.isEmpty) const Text('No hours in range.'),
        ],
      ),
    );
  }
}
