import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.tone});

  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = tone ?? scheme.secondaryContainer;
    final border = (tone ?? scheme.outline).withValues(alpha: 0.35);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: tone == null ? 1 : 0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
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
