/// Resumo agregado após processar um lote de [Pedido]s.
class PedidoResumo {
  const PedidoResumo({
    required this.totalPedidos,
    required this.pedidosValidos,
    required this.pedidosInvalidos,
    required this.valorLiquidoTotal,
    required this.scoreFraudeMedio,
  });

  final int totalPedidos;
  final int pedidosValidos;
  final int pedidosInvalidos;
  final double valorLiquidoTotal;
  final double scoreFraudeMedio;

  Map<String, dynamic> toJson() => {
    'totalPedidos': totalPedidos,
    'pedidosValidos': pedidosValidos,
    'pedidosInvalidos': pedidosInvalidos,
    'valorLiquidoTotal': valorLiquidoTotal,
    'scoreFraudeMedio': scoreFraudeMedio,
  };

  factory PedidoResumo.fromJson(Map<String, dynamic> json) {
    return PedidoResumo(
      totalPedidos: (json['totalPedidos'] as num).toInt(),
      pedidosValidos: (json['pedidosValidos'] as num).toInt(),
      pedidosInvalidos: (json['pedidosInvalidos'] as num).toInt(),
      valorLiquidoTotal: (json['valorLiquidoTotal'] as num).toDouble(),
      scoreFraudeMedio: (json['scoreFraudeMedio'] as num).toDouble(),
    );
  }

  /// Converte o retorno primitivo do Web Worker.
  factory PedidoResumo.fromWorkerResult(List<dynamic> result) {
    return PedidoResumo(
      totalPedidos: (result[0] as num).toInt(),
      pedidosValidos: (result[1] as num).toInt(),
      pedidosInvalidos: (result[2] as num).toInt(),
      valorLiquidoTotal: (result[3] as num).toDouble(),
      scoreFraudeMedio: (result[4] as num).toDouble(),
    );
  }
}
