import 'package:web_compute/domain/pedido.dart';
import 'package:web_compute/domain/pedido_resumo.dart';

/// Cria e processa um lote de pedidos de domínio (operação CPU-bound).
PedidoResumo processarLotePedidos(int quantidade) {
  var validos = 0;
  var invalidos = 0;
  var valorLiquidoTotal = 0.0;
  var scoreAcumulado = 0.0;

  for (var i = 0; i < quantidade; i++) {
    final pedido = Pedido.gerar(i);
    final resultado = pedido.processarCompleto();

    if (resultado.valido) {
      validos++;
      valorLiquidoTotal += resultado.valorLiquido;
    } else {
      invalidos++;
    }

    scoreAcumulado += resultado.scoreFraude;
  }

  return PedidoResumo(
    totalPedidos: quantidade,
    pedidosValidos: validos,
    pedidosInvalidos: invalidos,
    valorLiquidoTotal: valorLiquidoTotal,
    scoreFraudeMedio: quantidade == 0 ? 0 : scoreAcumulado / quantidade,
  );
}
