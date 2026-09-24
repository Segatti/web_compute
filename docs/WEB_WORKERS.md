# Processamento pesado no Flutter Web com Web Workers

Guia prático baseado no projeto `web_compute`. Objetivo: rodar trabalho **CPU-bound** (cálculos, validações, processamento de models de domínio) **sem travar a UI** no browser.

---

## O problema

No Flutter Web, a UI roda na **thread principal**. Quando você executa algo pesado de forma síncrona nessa thread:

- o spinner de loading **não anima**;
- animações e timers **congelam**;
- a página parece travada.

Isso acontece mesmo se você usar `async/await`, `Future` ou chamar `setState` antes do trabalho: o `setState` só agenda o rebuild; se o trabalho pesado começa na mesma função, nenhum frame é pintado até o fim.

### O que **não** resolve no Web

| API | Comportamento no Web |
|-----|----------------------|
| `compute()` do Flutter | Roda na **main thread** |
| `Isolate.run()` | Roda na **main thread** |
| `async/await` com laço CPU-bound | Continua na **main thread** |

> Referência: [Flutter docs — Concurrency and isolates](https://docs.flutter.dev/perf/isolates) e [Web FAQ](https://docs.flutter.dev/platform-integration/web/faq).

### O que resolve

**Web Workers** — threads JavaScript separadas do browser. No Flutter, o pacote [`isolate_manager`](https://pub.dev/packages/isolate_manager) compila funções Dart anotadas para arquivos `.js` em `web/` e se comunica via `postMessage`.

---

## Arquitetura adotada neste projeto

```
lib/
├── domain/                    # Regras de negócio (sem Flutter)
│   ├── pedido.dart            # Entidade de domínio
│   ├── pedido_resumo.dart     # DTO de saída
│   └── pedido_service.dart    # Orquestra o lote pesado
├── workers/                   # Entry points dos Web Workers
│   ├── heavy_computation.dart
│   └── pedido_processor.dart
├── pages/                     # UI Flutter
└── main.dart                  # Registro dos worker mappings

web/
├── heavyComputationEntry.js   # Gerado — não editar manualmente
└── processarPedidosEntry.js   # Gerado — não editar manualmente
```

**Regra de ouro:** código que roda no worker **não pode** importar `flutter`, `dart:ui`, `material`, etc. Mantenha domínio e workers em arquivos Dart puros.

---

## Passo a passo para replicar em outro projeto

### 1. Adicionar dependências

No `pubspec.yaml`:

```yaml
dependencies:
  isolate_manager: ^6.3.2

dev_dependencies:
  isolate_manager_generator: ^0.4.2
```

```bash
flutter pub get
```

### 2. Criar a lógica pesada (domínio)

Separe a regra de negócio da UI. Exemplo simplificado:

```dart
// lib/domain/meu_service.dart
import 'package:meu_app/domain/minha_entidade.dart';

MeuResumo processarLote(int quantidade) {
  for (var i = 0; i < quantidade; i++) {
    final item = MinhaEntidade.gerar(i);
    item.processarCompleto(); // CPU-bound
  }
  return MeuResumo(...);
}
```

### 3. Criar o entry point do worker

Arquivo em `lib/workers/`, com anotações obrigatórias:

```dart
// lib/workers/meu_processor.dart
import 'package:isolate_manager/isolate_manager.dart';
import 'package:meu_app/domain/meu_service.dart';

@pragma('vm:entry-point')
@isolateManagerWorker
List<num> processarEntry(int quantidade) {
  final resumo = processarLote(quantidade);
  return [
    resumo.total,
    resumo.valor,
    // ... apenas primitivos (num, String, bool)
  ];
}
```

**Requisitos da função worker:**

- `@pragma('vm:entry-point')` — evita tree-shaking
- `@isolateManagerWorker` — marca para o gerador
- Função **top-level** ou **estática** (não método de instância)
- Sem imports do Flutter
- Parâmetros e retorno transferíveis: `num`, `String`, `bool`, `null`, `List`/`Map` só com esses tipos

### 4. Gerar os arquivos JavaScript

```bash
dart run isolate_manager:generate
```

Saída esperada:

```
Function: processarEntry => Compiled: web/processarEntry.js
```

**Commitar** os `.js` gerados em `web/`. Eles são necessários no deploy.

> Rode o comando de novo sempre que alterar funções anotadas com `@isolateManagerWorker`.

### 5. Registrar o mapping no `main()`

**Obrigatório no Web.** Sem isso, o `IsolateManager` cai no fallback e roda na main thread (UI trava).

```dart
// lib/main.dart
import 'package:isolate_manager/isolate_manager.dart';
import 'package:meu_app/workers/meu_processor.dart';

void main() {
  _registerWebWorkers();
  runApp(const MyApp());
}

void _registerWebWorkers() {
  IsolateManager.addWorkerMapping(
    processarEntry,
    'processarEntry', // nome do arquivo em web/ (sem .js)
  );
}
```

O nome deve coincidir com o arquivo gerado: `web/processarEntry.js` → `'processarEntry'`.

### 6. Chamar da UI

```dart
Future<void> _runInBackground() async {
  setState(() => _isLoading = true);

  // Permite a UI pintar o loading antes de enviar ao worker
  await Future<void>.delayed(Duration.zero);

  try {
    final result = await IsolateManager.runFunction(
      processarEntry,
      quantidade,
      workerName: 'processarEntry',
      workerConverter: (value) => (value as List).cast<num>(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _resumo = MeuResumo.fromWorkerResult(result);
    });
  } catch (error) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _status = 'Erro no worker: $error';
    });
  }
}
```

Para comparação (travando de propósito, ex.: demo ou teste):

```dart
void _runOnMainThread() {
  setState(() => _isLoading = true);
  final resumo = processarLote(quantidade); // síncrono na main
  setState(() {
    _isLoading = false;
    _resumo = resumo;
  });
}
```

---

## Exemplo 1 — Cálculo numérico simples

| Arquivo | Função |
|---------|--------|
| `lib/workers/heavy_computation.dart` | Contagem de primos |
| Worker gerado | `web/heavyComputationEntry.js` |
| Retorno | `int` |

```dart
@pragma('vm:entry-point')
@isolateManagerWorker
int heavyComputationEntry(int iterations) {
  return heavyComputation(iterations: iterations);
}
```

Chamada:

```dart
final result = await IsolateManager.runFunction(
  heavyComputationEntry,
  80_000,
  workerName: 'heavyComputationEntry',
);
```

---

## Exemplo 2 — Model de domínio (`Pedido`)

Fluxo completo deste repositório:

1. **`Pedido`** (`lib/domain/pedido.dart`) — entidade com validação, impostos, antifraude e hash (CPU-bound).
2. **`processarLotePedidos()`** (`lib/domain/pedido_service.dart`) — cria N pedidos e agrega resultado.
3. **`processarPedidosEntry()`** (`lib/workers/pedido_processor.dart`) — entry point do worker.
4. **`PedidoResumo.fromWorkerResult()`** — reconstrói o DTO a partir de `List<num>`.

### Por que retornar `List<num>` e não `Map` ou `Pedido`?

Objetos de domínio **não atravessam** o worker. Só passam dados serializáveis.

| Tipo de retorno | Recomendação |
|-----------------|--------------|
| `int`, `double`, `String`, `bool` | OK |
| `List<num>` com campos do resumo | **Recomendado** para DTOs |
| `Map<String, dynamic>` | Funciona, mas no Web os valores podem chegar como `double`/`Map<dynamic, dynamic>` e quebrar casts |
| Instâncias de classes | **Não usar** |

Conversão segura no app:

```dart
factory PedidoResumo.fromWorkerResult(List<dynamic> result) {
  return PedidoResumo(
    totalPedidos: (result[0] as num).toInt(),
    pedidosValidos: (result[1] as num).toInt(),
    pedidosInvalidos: (result[2] as num).toInt(),
    valorLiquidoTotal: (result[3] as num).toDouble(),
    scoreFraudeMedio: (result[4] as num).toDouble(),
  );
}
```

Use `(valor as num).toInt()` — nunca `as int` direto em dados vindos do worker.

---

## Armadilhas comuns

### 1. Esquecer `addWorkerMapping`

**Sintoma:** segundo botão trava igual ao primeiro; spinner congela.

**Correção:** registrar no `main()` e passar `workerName` na chamada.

### 2. Loading infinito

**Sintoma:** loading nunca termina, sem mensagem de erro.

**Causas frequentes:**

- Worker mapping ausente (worker nunca responde corretamente)
- Cast inválido no retorno (`Map<String, dynamic>` vindo como `Map<dynamic, dynamic>`)
- Exceção após `await` sem `try/catch`, com `_isLoading` preso em `true`

**Correção:** retornar primitivos/`List<num>`, usar `workerConverter`, sempre `try/catch/finally` na UI.

### 3. Importar Flutter no worker

**Sintoma:** falha na compilação do `.js` ou worker que não inicializa.

**Correção:** mover lógica para `lib/domain/` sem dependências de UI.

### 4. Não regenerar o `.js` após mudança

**Sintoma:** comportamento antigo ou worker desatualizado.

**Correção:**

```bash
dart run isolate_manager:generate
```

Depois, hot **restart** (`R`), não apenas hot reload.

### 5. Worker não encontrado no deploy

**Sintoma:** funciona em dev, falha em produção.

**Correção:** garantir que `web/*.js` gerados estão no repositório e no build. Verifique no DevTools → Network se `processarPedidosEntry.js` retorna HTTP 200.

---

## Comportamento por plataforma

| Plataforma | `IsolateManager.runFunction` |
|------------|------------------------------|
| **Web** | Web Worker (`.js` em `web/`) |
| **Android / iOS / Desktop** | Isolate nativo do Dart |

A mesma API funciona em todas as plataformas — o pacote escolhe a implementação correta.

---

## Checklist de replicação

- [ ] Dependências `isolate_manager` + `isolate_manager_generator`
- [ ] Lógica pesada em `lib/domain/` (sem Flutter)
- [ ] Entry point em `lib/workers/` com `@pragma` + `@isolateManagerWorker`
- [ ] Retorno apenas com tipos serializáveis (preferir `List<num>`)
- [ ] `dart run isolate_manager:generate` executado
- [ ] Arquivos `web/<nome>.js` commitados
- [ ] `IsolateManager.addWorkerMapping()` no `main()`
- [ ] `workerName` passado em `runFunction`
- [ ] `workerConverter` quando o retorno for `List` ou `Map`
- [ ] `try/catch` na UI para não deixar loading infinito
- [ ] `await Future.delayed(Duration.zero)` após ativar loading (opcional, melhora UX)
- [ ] Testado com `flutter run -d chrome`

---

## Comandos úteis

```bash
# Instalar deps
flutter pub get

# Gerar Web Workers
dart run isolate_manager:generate

# Rodar no Chrome
flutter run -d chrome

# Analisar o projeto
flutter analyze
```

---

## Referências no repositório

| Conceito | Arquivo |
|----------|---------|
| Registro dos workers | `lib/main.dart` |
| Worker numérico | `lib/workers/heavy_computation.dart` |
| Worker com domínio | `lib/workers/pedido_processor.dart` |
| Entidade de domínio | `lib/domain/pedido.dart` |
| Serviço de lote | `lib/domain/pedido_service.dart` |
| Chamada na UI | `lib/pages/pedido_demo_tab.dart` |
| JS gerados | `web/*.js` |

---

## Resumo em uma frase

**Separe a lógica pesada do Flutter, anote um entry point com `@isolateManagerWorker`, gere o `.js`, registre o mapping no `main()` e chame com `IsolateManager.runFunction` retornando apenas dados primitivos.**
