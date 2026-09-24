import 'package:flutter/material.dart';

class DemoScaffold extends StatelessWidget {
  const DemoScaffold({
    super.key,
    required this.description,
    required this.status,
    required this.isLoading,
    required this.tick,
    required this.resultLines,
    required this.onRunMainThread,
    required this.onRunBackground,
  });

  final String description;
  final String status;
  final bool isLoading;
  final int tick;
  final List<String> resultLines;
  final VoidCallback? onRunMainThread;
  final VoidCallback? onRunBackground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(description, style: theme.textTheme.bodyMedium),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                if (isLoading)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Carregando...'),
                    ],
                  )
                else
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                const SizedBox(height: 16),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                if (resultLines.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final line in resultLines)
                    Text(line, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          const Spacer(),
          Card(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined, color: theme.colorScheme.secondary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Relógio da UI (100ms)',
                        style: theme.textTheme.labelLarge,
                      ),
                      Text(
                        'Ticks: $tick',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        'Congela só no botão vermelho.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: onRunMainThread,
            icon: const Icon(Icons.block),
            label: const Text('Processar na thread principal (trava)'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRunBackground,
            icon: const Icon(Icons.bolt),
            label: const Text('Processar com Web Worker (não trava)'),
          ),
        ],
      ),
    );
  }
}
