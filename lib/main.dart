import 'package:flutter/material.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:web_compute/pages/numeric_demo_tab.dart';
import 'package:web_compute/pages/pedido_demo_tab.dart';
import 'package:web_compute/workers/heavy_computation.dart';
import 'package:web_compute/workers/pedido_processor.dart';

void main() {
  _registerWebWorkers();
  runApp(const MyApp());
}

void _registerWebWorkers() {
  IsolateManager.addWorkerMapping(
    heavyComputationEntry,
    'heavyComputationEntry',
  );
  IsolateManager.addWorkerMapping(
    processarPedidosEntry,
    'processarPedidosEntry',
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web Compute Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Demo: UI bloqueada vs Web Worker'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Numérico'),
              Tab(text: 'Domínio (Pedido)'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            NumericDemoTab(),
            PedidoDemoTab(),
          ],
        ),
      ),
    );
  }
}
