/// Status do ciclo de vida do pedido.
enum StatusPedido {
  rascunho,
  confirmado,
  emSeparacao,
  enviado,
  entregue,
  cancelado,
}

/// Forma de pagamento escolhida no checkout.
enum FormaPagamento {
  pix,
  cartaoCredito,
  boleto,
  dinheiro,
}

/// Endereço de entrega (valor object aninhado).
class EnderecoEntrega {
  const EnderecoEntrega({
    required this.logradouro,
    required this.numero,
    required this.complemento,
    required this.bairro,
    required this.cidade,
    required this.uf,
    required this.cep,
  });

  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String uf;
  final String cep;

  Map<String, dynamic> toJson() => {
    'logradouro': logradouro,
    'numero': numero,
    'complemento': complemento,
    'bairro': bairro,
    'cidade': cidade,
    'uf': uf,
    'cep': cep,
  };

  factory EnderecoEntrega.fromJson(Map<String, dynamic> json) {
    return EnderecoEntrega(
      logradouro: json['logradouro'] as String,
      numero: json['numero'] as String,
      complemento: json['complemento'] as String,
      bairro: json['bairro'] as String,
      cidade: json['cidade'] as String,
      uf: json['uf'] as String,
      cep: json['cep'] as String,
    );
  }
}

/// Dados de pagamento vinculados ao pedido.
class DadosPagamento {
  const DadosPagamento({
    required this.forma,
    required this.parcelas,
    required this.taxaJuros,
    required this.codigoAutorizacao,
  });

  final FormaPagamento forma;
  final int parcelas;
  final double taxaJuros;
  final String codigoAutorizacao;

  Map<String, dynamic> toJson() => {
    'forma': forma.name,
    'parcelas': parcelas,
    'taxaJuros': taxaJuros,
    'codigoAutorizacao': codigoAutorizacao,
  };

  factory DadosPagamento.fromJson(Map<String, dynamic> json) {
    return DadosPagamento(
      forma: FormaPagamento.values.byName(json['forma'] as String),
      parcelas: json['parcelas'] as int,
      taxaJuros: (json['taxaJuros'] as num).toDouble(),
      codigoAutorizacao: json['codigoAutorizacao'] as String,
    );
  }
}

/// Item de um pedido comercial.
class ItemPedido {
  const ItemPedido({
    required this.sku,
    required this.descricao,
    required this.categoria,
    required this.quantidade,
    required this.precoUnitario,
    required this.pesoKg,
    required this.descontoPercentual,
    required this.fragil,
    required this.tags,
  });

  final String sku;
  final String descricao;
  final String categoria;
  final int quantidade;
  final double precoUnitario;
  final double pesoKg;
  final double descontoPercentual;
  final bool fragil;
  final List<String> tags;

  double get subtotal {
    final bruto = quantidade * precoUnitario;
    return bruto * (1 - descontoPercentual.clamp(0, 0.9));
  }

  Map<String, dynamic> toJson() => {
    'sku': sku,
    'descricao': descricao,
    'categoria': categoria,
    'quantidade': quantidade,
    'precoUnitario': precoUnitario,
    'pesoKg': pesoKg,
    'descontoPercentual': descontoPercentual,
    'fragil': fragil,
    'tags': tags,
  };

  factory ItemPedido.fromJson(Map<String, dynamic> json) {
    return ItemPedido(
      sku: json['sku'] as String,
      descricao: json['descricao'] as String,
      categoria: json['categoria'] as String,
      quantidade: json['quantidade'] as int,
      precoUnitario: (json['precoUnitario'] as num).toDouble(),
      pesoKg: (json['pesoKg'] as num).toDouble(),
      descontoPercentual: (json['descontoPercentual'] as num).toDouble(),
      fragil: json['fragil'] as bool,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
    );
  }
}

/// Entidade de domínio: pedido rico em atributos e regras CPU-bound.
class Pedido {
  Pedido({
    required this.id,
    required this.clienteId,
    required this.clienteNome,
    required this.emailCliente,
    required this.documentoCliente,
    required this.canalVenda,
    required this.status,
    required this.itens,
    required this.enderecoEntrega,
    required this.pagamento,
    required this.frete,
    required this.descontoPedido,
    required this.cuponsAplicados,
    required this.observacoes,
    required this.metadados,
    required this.dataEmissao,
    required this.dataPrometidaEntrega,
  });

  final String id;
  final String clienteId;
  final String clienteNome;
  final String emailCliente;
  final String documentoCliente;
  final String canalVenda;
  final StatusPedido status;
  final List<ItemPedido> itens;
  final EnderecoEntrega enderecoEntrega;
  final DadosPagamento pagamento;
  final double frete;
  final double descontoPedido;
  final List<String> cuponsAplicados;
  final List<String> observacoes;
  final Map<String, String> metadados;
  final DateTime dataEmissao;
  final DateTime dataPrometidaEntrega;

  double get valorItens =>
      itens.fold<double>(0, (total, item) => total + item.subtotal);

  double get pesoTotalKg =>
      itens.fold<double>(0, (total, item) => total + item.pesoKg * item.quantidade);

  double get valorBruto =>
      (valorItens + frete - descontoPedido).clamp(0, double.infinity);

  /// Gera pedidos sintéticos para simular carga de processamento em lote.
  factory Pedido.gerar(int indice) {
    final itemCount = 3 + (indice % 5);
    final categorias = ['Eletrônicos', 'Casa', 'Moda', 'Alimentos', 'Livros'];
    final itens = List.generate(itemCount, (i) {
      final seed = indice * 17 + i * 31;
      return ItemPedido(
        sku: 'SKU-${seed % 10000}',
        descricao: 'Produto ${seed % 500}',
        categoria: categorias[seed % categorias.length],
        quantidade: 1 + (seed % 8),
        precoUnitario: 10 + (seed % 900) + (seed % 7) * 0.99,
        pesoKg: 0.2 + (seed % 50) * 0.1,
        descontoPercentual: (seed % 15) * 0.01,
        fragil: seed % 4 == 0,
        tags: [
          if (seed % 2 == 0) 'promo',
          if (seed % 3 == 0) 'frete-gratis',
          'cat-${seed % 7}',
        ],
      );
    });

    final ufs = ['SP', 'RJ', 'MG', 'RS', 'PR', 'BA', 'SC'];
    final uf = ufs[indice % ufs.length];
    final formas = FormaPagamento.values;
    final forma = formas[indice % formas.length];

    return Pedido(
      id: 'PED-${indice.toString().padLeft(6, '0')}',
      clienteId: 'CLI-${indice % 1200}',
      clienteNome: 'Cliente ${indice % 1200}',
      emailCliente: 'cliente${indice % 1200}@exemplo.com.br',
      documentoCliente: '${(10000000000 + indice % 90000000000)}',
      canalVenda: indice.isEven ? 'marketplace' : 'loja-fisica',
      status: StatusPedido.values[indice % StatusPedido.values.length],
      itens: itens,
      enderecoEntrega: EnderecoEntrega(
        logradouro: 'Rua Exemplo ${indice % 200}',
        numero: '${100 + indice % 900}',
        complemento: indice % 5 == 0 ? 'Apto ${indice % 120}' : '',
        bairro: 'Bairro ${indice % 40}',
        cidade: 'Cidade ${indice % 80}',
        uf: uf,
        cep: '${10000000 + indice % 89999999}',
      ),
      pagamento: DadosPagamento(
        forma: forma,
        parcelas: forma == FormaPagamento.cartaoCredito ? 1 + (indice % 12) : 1,
        taxaJuros: forma == FormaPagamento.cartaoCredito ? (indice % 5) * 0.005 : 0,
        codigoAutorizacao: 'AUTH-${indice.toRadixString(16).padLeft(8, '0')}',
      ),
      frete: 5 + (indice % 40) + pesoSimulado(itens) * 0.5,
      descontoPedido: (indice % 10) * 2.5,
      cuponsAplicados: indice % 3 == 0
          ? ['CUPOM10', 'FRETEGRATIS']
          : indice % 2 == 0
          ? ['BEMVINDO']
          : const [],
      observacoes: [
        if (indice % 4 == 0) 'Entregar após 18h',
        if (indice % 7 == 0) 'Cliente preferencial',
      ],
      metadados: {
        'origemCampanha': 'camp-${indice % 20}',
        'vendedorId': 'VND-${indice % 50}',
        'dispositivo': indice.isEven ? 'web' : 'app',
      },
      dataEmissao: DateTime(2024, 1, 1).add(Duration(hours: indice % 8760)),
      dataPrometidaEntrega: DateTime(2024, 1, 3).add(Duration(hours: indice % 8760)),
    );
  }

  static double pesoSimulado(List<ItemPedido> itens) {
    return itens.fold<double>(
      0,
      (total, item) => total + item.pesoKg * item.quantidade,
    );
  }

  /// Processamento pesado: validação + impostos + score antifraude.
  ResultadoProcessamentoPedido processarCompleto() {
    final erros = <String>[];

    if (status == StatusPedido.cancelado) {
      erros.add('Pedido cancelado');
    }
    if (itens.isEmpty) {
      erros.add('Pedido sem itens');
    }
    if (valorBruto <= 0) {
      erros.add('Valor inválido');
    }
    if (clienteNome.trim().isEmpty) {
      erros.add('Cliente inválido');
    }
    if (!_emailValido(emailCliente)) {
      erros.add('E-mail inválido');
    }
    if (documentoCliente.length < 11) {
      erros.add('Documento inválido');
    }
    if (!_cepValido(enderecoEntrega.cep)) {
      erros.add('CEP inválido');
    }
    if (dataPrometidaEntrega.isBefore(dataEmissao)) {
      erros.add('Data de entrega inconsistente');
    }
    if (pagamento.parcelas < 1) {
      erros.add('Parcelas inválidas');
    }

    for (final item in itens) {
      if (!_validarSku(item.sku)) {
        erros.add('SKU inválido: ${item.sku}');
      }
      if (item.quantidade <= 0) {
        erros.add('Quantidade inválida: ${item.sku}');
      }
      if (item.categoria.trim().isEmpty) {
        erros.add('Categoria ausente: ${item.sku}');
      }
    }

    final impostos = _calcularImpostos();
    final scoreFraude = _calcularScoreAntifraude();
    final hashAuditoria = _gerarHashAuditoria();

    return ResultadoProcessamentoPedido(
      pedidoId: id,
      valido: erros.isEmpty,
      erros: erros,
      valorBruto: valorBruto,
      impostos: impostos,
      valorLiquido: valorBruto + impostos,
      scoreFraude: scoreFraude,
      hashAuditoria: hashAuditoria,
    );
  }

  bool _emailValido(String email) {
    return email.contains('@') && email.contains('.');
  }

  bool _cepValido(String cep) {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    return digits.length == 8;
  }

  bool _validarSku(String sku) {
    if (!sku.startsWith('SKU-')) return false;

    var checksum = 0;
    for (var i = 0; i < sku.length; i++) {
      checksum = (checksum * 31 + sku.codeUnitAt(i)) & 0x7fffffff;
    }
    return checksum % 17 != 0;
  }

  /// Simula cálculo tributário complexo (CPU-bound).
  double _calcularImpostos() {
    var total = 0.0;
    final fatorUf = 1 + enderecoEntrega.uf.hashCode.abs() % 9 * 0.01;

    for (final item in itens) {
      for (var faixa = 0; faixa < 400; faixa++) {
        final aliquota = 0.05 + (faixa % 12) * 0.0025;
        final fatorCategoria = 1 + (item.categoria.hashCode.abs() % 5) * 0.008;
        final fatorRegiao = 1 + ((faixa + item.sku.hashCode) % 7) * 0.01;
        total +=
            item.subtotal * aliquota * fatorRegiao * fatorCategoria * fatorUf * 0.001;
      }
    }

    if (pagamento.forma == FormaPagamento.cartaoCredito) {
      total += valorBruto * pagamento.taxaJuros * 0.1;
    }

    return total;
  }

  /// Simula motor antifraude com múltiplas heurísticas.
  double _calcularScoreAntifraude() {
    var score = 0.0;

    for (var regra = 0; regra < 300; regra++) {
      final peso = (regra % 11 + 1) * 0.01;
      final sinal = (clienteId.hashCode + regra * 13) % 100;
      score += peso * (sinal / 100);
    }

    if (valorBruto > 5000) score += 0.15;
    if (itens.length > 6) score += 0.08;
    if (pagamento.parcelas > 6) score += 0.05;
    if (cuponsAplicados.length > 1) score += 0.03;
    if (canalVenda == 'marketplace' && pesoTotalKg > 30) score += 0.04;
    if (metadados['dispositivo'] == 'web' && observacoes.isEmpty) score += 0.02;

    return score.clamp(0, 1);
  }

  /// Simula geração de hash de auditoria (laço intencionalmente pesado).
  String _gerarHashAuditoria() {
    var acc = id.hashCode ^
        clienteId.hashCode ^
        dataEmissao.millisecondsSinceEpoch ^
        enderecoEntrega.cep.hashCode ^
        pagamento.codigoAutorizacao.hashCode;

    for (final cupom in cuponsAplicados) {
      acc = (acc * 1103515245 + cupom.hashCode) & 0x7fffffff;
    }

    for (final item in itens) {
      for (var round = 0; round < 200; round++) {
        acc = (acc * 1103515245 + item.sku.hashCode + round) & 0x7fffffff;
        for (final tag in item.tags) {
          acc = (acc + tag.hashCode) & 0x7fffffff;
        }
      }
    }

    return acc.toRadixString(16).padLeft(8, '0');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clienteId': clienteId,
    'clienteNome': clienteNome,
    'emailCliente': emailCliente,
    'documentoCliente': documentoCliente,
    'canalVenda': canalVenda,
    'status': status.name,
    'itens': itens.map((item) => item.toJson()).toList(),
    'enderecoEntrega': enderecoEntrega.toJson(),
    'pagamento': pagamento.toJson(),
    'frete': frete,
    'descontoPedido': descontoPedido,
    'cuponsAplicados': cuponsAplicados,
    'observacoes': observacoes,
    'metadados': metadados,
    'dataEmissao': dataEmissao.toIso8601String(),
    'dataPrometidaEntrega': dataPrometidaEntrega.toIso8601String(),
  };

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: json['id'] as String,
      clienteId: json['clienteId'] as String,
      clienteNome: json['clienteNome'] as String,
      emailCliente: json['emailCliente'] as String,
      documentoCliente: json['documentoCliente'] as String,
      canalVenda: json['canalVenda'] as String,
      status: StatusPedido.values.byName(json['status'] as String),
      itens: (json['itens'] as List<dynamic>)
          .map((item) => ItemPedido.fromJson(item as Map<String, dynamic>))
          .toList(),
      enderecoEntrega: EnderecoEntrega.fromJson(
        json['enderecoEntrega'] as Map<String, dynamic>,
      ),
      pagamento: DadosPagamento.fromJson(
        json['pagamento'] as Map<String, dynamic>,
      ),
      frete: (json['frete'] as num).toDouble(),
      descontoPedido: (json['descontoPedido'] as num).toDouble(),
      cuponsAplicados: (json['cuponsAplicados'] as List<dynamic>).cast<String>(),
      observacoes: (json['observacoes'] as List<dynamic>).cast<String>(),
      metadados: Map<String, String>.from(json['metadados'] as Map),
      dataEmissao: DateTime.parse(json['dataEmissao'] as String),
      dataPrometidaEntrega: DateTime.parse(
        json['dataPrometidaEntrega'] as String,
      ),
    );
  }
}

/// Resultado do processamento de um único pedido.
class ResultadoProcessamentoPedido {
  const ResultadoProcessamentoPedido({
    required this.pedidoId,
    required this.valido,
    required this.erros,
    required this.valorBruto,
    required this.impostos,
    required this.valorLiquido,
    required this.scoreFraude,
    required this.hashAuditoria,
  });

  final String pedidoId;
  final bool valido;
  final List<String> erros;
  final double valorBruto;
  final double impostos;
  final double valorLiquido;
  final double scoreFraude;
  final String hashAuditoria;
}
