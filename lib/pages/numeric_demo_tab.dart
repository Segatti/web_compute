import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:web_compute/widgets/demo_scaffold.dart';
import 'package:web_compute/workers/heavy_computation.dart';

class NumericDemoTab extends StatefulWidget {
  const NumericDemoTab({super.key});

  @override
  State<NumericDemoTab> createState() => _NumericDemoTabState();
}

class _NumericDemoTabState extends State<NumericDemoTab> {
  static const _iterations = 80_000;

  bool _isLoading = false;
  String _status = 'Pronto para processar';
  int _result = 0;
  int _tick = 0;

  late Timer _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() => _tick++);
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _runOnMainThread() {
    setState(() {
      _isLoading = true;
      _status = 'Processando na thread principal...';
    });

    final result = heavyComputation(iterations: _iterations);

    setState(() {
      _isLoading = false;
      _result = result;
      _status = 'Concluído (UI travou). Resultado: $result';
    });
  }

  Future<void> _runInBackground() async {
    setState(() {
      _isLoading = true;
      _status = 'Processando em Web Worker...';
    });

    await Future<void>.delayed(Duration.zero);

    final result = await IsolateManager.runFunction(
      heavyComputationEntry,
      _iterations,
      workerName: 'heavyComputationEntry',
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _result = result;
      _status = 'Concluído sem travar! Resultado: $result';
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      description:
          'Cálculo numérico pesado (contagem de primos). '
          'Útil para demonstrar bloqueio puro de CPU.',
      status: _status,
      isLoading: _isLoading,
      tick: _tick,
      resultLines: _result > 0 && !_isLoading
          ? ['Primos encontrados: $_result']
          : const [],
      onRunMainThread: _isLoading ? null : _runOnMainThread,
      onRunBackground: _isLoading ? null : _runInBackground,
    );
  }
}
