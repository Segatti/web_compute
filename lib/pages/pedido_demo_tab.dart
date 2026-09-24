import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:web_compute/domain/pedido_resumo.dart';
import 'package:web_compute/domain/pedido_service.dart';
import 'package:web_compute/widgets/demo_scaffold.dart';
import 'package:web_compute/workers/pedido_processor.dart';

class PedidoDemoTab extends StatefulWidget {
  const PedidoDemoTab({super.key});

  @override
  State<PedidoDemoTab> createState() => _PedidoDemoTabState();
}

class _PedidoDemoTabState extends State<PedidoDemoTab> {
  static const _quantidadePedidos = 12000;

  bool _isLoading = false;
  String _status = 'Pronto para processar pedidos';
  PedidoResumo? _resumo;
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
      _status = 'Criando e processando $_quantidadePedidos pedidos na main...';
      _resumo = null;
    });

    try {
      final resumo = processarLotePedidos(_quantidadePedidos);
      setState(() {
        _isLoading = false;
        _resumo = resumo;
        _status = 'Lote concluído na main (UI travou).';
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _status = 'Erro na main: $error';
      });
    }
  }

  Future<void> _runInBackground() async {
    setState(() {
      _isLoading = true;
      _status = kIsWeb
          ? 'Criando e processando $_quantidadePedidos pedidos no Web Worker...'
          : 'Criando e processando $_quantidadePedidos pedidos no isolate...';
      _resumo = null;
    });

    await Future<void>.delayed(Duration.zero);

    try {
      final result = await IsolateManager.runFunction(
        processarPedidosEntry,
        _quantidadePedidos,
        workerName: 'processarPedidosEntry',
        workerConverter: (value) => (value as List).cast<num>(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _resumo = PedidoResumo.fromWorkerResult(result);
        _status = 'Lote concluído sem travar a UI.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _status = 'Erro no worker: $error';
      });
    }
  }

  List<String> _resultLines() {
    final resumo = _resumo;
    if (resumo == null || _isLoading) return const [];

    return [
      'Total: ${resumo.totalPedidos}',
      'Válidos: ${resumo.pedidosValidos} | Inválidos: ${resumo.pedidosInvalidos}',
      'Valor líquido: R\$ ${resumo.valorLiquidoTotal.toStringAsFixed(2)}',
      'Score antifraude médio: ${resumo.scoreFraudeMedio.toStringAsFixed(3)}',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      description:
          'Exemplo com modelo de domínio complexo [Pedido]: strings, números, '
          'enums, listas de [ItemPedido], endereço, pagamento, cupons e '
          'metadados — $_quantidadePedidos instâncias com validação, impostos, '
          'antifraude e hash de auditoria.',
      status: _status,
      isLoading: _isLoading,
      tick: _tick,
      resultLines: _resultLines(),
      onRunMainThread: _isLoading ? null : _runOnMainThread,
      onRunBackground: _isLoading ? null : _runInBackground,
    );
  }
}
