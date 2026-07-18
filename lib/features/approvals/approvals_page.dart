import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/project_tracker_repo.dart';
import '../../models/project_tracker_models.dart';
import '../../widgets/sign_out_action.dart';
import '../../widgets/status_chip.dart';

class ApprovalsPage extends ConsumerStatefulWidget {
  const ApprovalsPage({super.key});

  @override
  ConsumerState<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends ConsumerState<ApprovalsPage> {
  String _status = 'Loading…';
  List<ApprovalItem> _rows = [];
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
      final rows = await ref
          .read(projectTrackerRepoProvider)
          .listApprovalsMine();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _status = 'Connected · ${rows.length} pending';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'API error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve(ApprovalItem item) async {
    setState(() => _busy = true);
    try {
      await ref.read(projectTrackerRepoProvider).approve(item.name);
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Approved ${item.name}')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Approve failed: $e';
        _busy = false;
      });
    }
  }

  Future<void> _reject(ApprovalItem item) async {
    setState(() => _busy = true);
    try {
      await ref.read(projectTrackerRepoProvider).reject(item.name);
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Rejected ${item.name}')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Reject failed: $e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approvals'),
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
                child: Center(child: Text('No approvals waiting for you.')),
              ),
            ..._rows.map(
              (a) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.entityName ?? a.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text('${a.entityType ?? '—'} · ${a.requestedBy ?? '—'}'),
                      const SizedBox(height: 8),
                      StatusChip(label: a.status ?? 'Pending'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FilledButton(
                            onPressed: _busy ? null : () => _approve(a),
                            child: const Text('Approve'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _busy ? null : () => _reject(a),
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
