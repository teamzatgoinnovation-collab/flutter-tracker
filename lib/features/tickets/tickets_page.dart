import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tracker_repo.dart';
import '../../models/tracker_models.dart';
import '../../widgets/sign_out_action.dart';
import '../../widgets/status_chip.dart';

class TicketsPage extends ConsumerStatefulWidget {
  const TicketsPage({super.key});

  @override
  ConsumerState<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends ConsumerState<TicketsPage> {
  String _status = 'Loading…';
  List<TicketSummary> _rows = [];
  bool _busy = false;
  String? _selected;
  String? _assignUser;
  List<Map<String, dynamic>> _people = [];
  final _subject = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _subject.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _status = 'Loading…';
    });
    try {
      final repo = ref.read(trackerRepoProvider);
      final result = await repo.listTickets();
      final people = await repo.myTreePeople();
      if (!mounted) return;
      setState(() {
        _rows = result.rows;
        _people = people;
        _assignUser ??= people.isNotEmpty ? '${people.first['user']}' : null;
        _status = 'Connected · ${_rows.length} tickets';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'API error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    final subject = _subject.text.trim();
    if (subject.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(trackerRepoProvider).createTicket(subject);
      _subject.clear();
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  Future<void> _assign() async {
    if (_selected == null || _assignUser == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(trackerRepoProvider)
          .assignTicket(_selected!, _assignUser!);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Assign failed: $e')));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
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
              controller: _subject,
              decoration: const InputDecoration(
                labelText: 'New ticket subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _assignUser,
              decoration: const InputDecoration(
                labelText: 'Assign to',
                border: OutlineInputBorder(),
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
            Row(
              children: [
                FilledButton(
                  onPressed: _busy ? null : _create,
                  child: const Text('Create'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _busy || _selected == null || _assignUser == null
                      ? null
                      : _assign,
                  child: const Text('Assign selected'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final row in _rows)
              ListTile(
                selected: _selected == row.name,
                title: Text(row.title),
                subtitle: Text(row.project ?? '—'),
                trailing: StatusChip(label: row.status ?? '—'),
                onTap: () => setState(() => _selected = row.name),
              ),
          ],
        ),
      ),
    );
  }
}
