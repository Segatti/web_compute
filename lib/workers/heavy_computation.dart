import 'package:isolate_manager/isolate_manager.dart';

@pragma('vm:entry-point')
@isolateManagerWorker
int heavyComputationEntry(int iterations) {
  return heavyComputation(iterations: iterations);
}

/// Simula CPU-bound work (cálculo de números primos).
int heavyComputation({required int iterations}) {
  var count = 0;
  for (var n = 2; n < iterations; n++) {
    if (isPrime(n)) count++;
  }
  return count;
}

bool isPrime(int n) {
  if (n < 2) return false;
  if (n == 2) return true;
  if (n.isEven) return false;
  final limit = (n / 2).floor();
  for (var i = 3; i <= limit; i += 2) {
    if (n % i == 0) return false;
  }
  return true;
}
