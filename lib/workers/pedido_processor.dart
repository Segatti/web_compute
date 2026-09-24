import 'package:isolate_manager/isolate_manager.dart';
import 'package:web_compute/domain/pedido_service.dart';

@pragma('vm:entry-point')
@isolateManagerWorker
List<num> processarPedidosEntry(int quantidade) {
  final resumo = processarLotePedidos(quantidade);
  // Lista de primitivos serializa de forma confiável no Web Worker.
  return [
    resumo.totalPedidos,
    resumo.pedidosValidos,
    resumo.pedidosInvalidos,
    resumo.valorLiquidoTotal,
    resumo.scoreFraudeMedio,
  ];
}
