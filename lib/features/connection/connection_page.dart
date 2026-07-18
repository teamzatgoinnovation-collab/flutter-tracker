import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/tracker_repo.dart';
import '../../services/push_registration.dart';
import '../../services/session.dart';
import '../../widgets/sign_out_action.dart';

class ConnectionPage extends ConsumerStatefulWidget {
  const ConnectionPage({super.key});

  @override
  ConsumerState<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends ConsumerState<ConnectionPage> {
  bool _busy = false;
  String _probe = '';

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(trackerSessionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection'),
        actions: const [SignOutAction()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ERPNext session for Tracker APIs.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.connected
                          ? 'Signed in as ${session.fullName ?? session.user}'
                          : 'Not signed in',
                    ),
                    const SizedBox(height: 4),
                    Text(session.baseUrl, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () async {
                                  setState(() => _busy = true);
                                  await session.logout();
                                  if (!mounted) return;
                                  setState(() => _busy = false);
                                  context.go('/login');
                                },
                          child: const Text('Sign out'),
                        ),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () async {
                                  setState(() => _busy = true);
                                  final r = await session.ping();
                                  if (!mounted) return;
                                  setState(() => _busy = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(r.message)),
                                  );
                                },
                          child: const Text('Test site'),
                        ),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () async {
                                  setState(() {
                                    _busy = true;
                                    _probe = 'Probing…';
                                  });
                                  try {
                                    final result = await ref
                                        .read(trackerRepoProvider)
                                        .listProjects(pageSize: 5);
                                    if (!mounted) return;
                                    setState(() {
                                      _probe =
                                          'OK · ${result.rows.length} projects (total ${result.total ?? '—'})';
                                    });
                                  } catch (e) {
                                    if (!mounted) return;
                                    setState(() => _probe = 'Probe failed: $e');
                                  } finally {
                                    if (mounted) setState(() => _busy = false);
                                  }
                                },
                          child: const Text('Probe PT'),
                        ),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () async {
                                  setState(() => _busy = true);
                                  final msg = await PushRegistration(
                                    session,
                                  ).registerIfPossible();
                                  if (!mounted) return;
                                  setState(() => _busy = false);
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text(msg)));
                                },
                          child: const Text('Register FCM'),
                        ),
                      ],
                    ),
                    if (_probe.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(_probe),
                    ],
                  ],
                ),
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
