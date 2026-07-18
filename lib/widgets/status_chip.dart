import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.tone});

  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = tone ?? scheme.secondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

Color? ragColor(String? rag, ColorScheme scheme) {
  switch ((rag ?? '').toLowerCase()) {
    case 'red':
      return scheme.errorContainer;
    case 'amber':
    case 'yellow':
      return const Color(0xFFFFE8C2);
    case 'green':
      return scheme.primaryContainer;
    default:
      return null;
  }
}
