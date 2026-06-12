import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits true while the device reports no network connectivity. Plain (non-
/// codegen) provider — no .g.dart needed.
final isOfflineProvider = StreamProvider<bool>((ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((results) =>
          results.every((r) => r == ConnectivityResult.none));
});
