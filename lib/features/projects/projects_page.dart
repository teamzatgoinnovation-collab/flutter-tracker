import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/tracker_repo.dart';
import '../../models/tracker_models.dart';
import '../../widgets/sign_out_action.dart';
import '../../widgets/status_chip.dart';

class ProjectsPage extends ConsumerStatefulWidget {
  const ProjectsPage({super.key});

  @override
  ConsumerState<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends ConsumerState<ProjectsPage> {
  String _status = 'Loading…';
  List<ProjectSummary> _rows = [];
  int? _total;
  bool _busy = false;
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _status = 'Loading…';
    });
    try {
      final result = await ref.read(trackerRepoProvider).listProjects();
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

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(trackerRepoProvider).createProject(name);
      _name.clear();
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
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
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'New project name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _create,
              child: const Text('Create'),
            ),
            const SizedBox(height: 12),
            if (_rows.isEmpty && !_busy)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No projects returned.')),
              ),
            ..._rows.map(
              (p) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(p.title),
                  subtitle: Text('${p.status ?? '—'} · ${p.company ?? '—'}'),
                  trailing: StatusChip(
                    label: p.ragStatus ?? p.status ?? '—',
                    tone: ragColor(p.ragStatus, Theme.of(context).colorScheme),
                  ),
                  onTap: () => context.go('/projects/${p.name}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
