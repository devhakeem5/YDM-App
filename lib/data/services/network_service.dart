import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:ydm/core/utils/logger.dart';

class NetworkService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final Rx<ConnectivityResult> connectionStatus = ConnectivityResult.none.obs;

  bool get isConnected => connectionStatus.value != ConnectivityResult.none;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      LogService.error("Failed to get initial connectivity status", e);
      connectionStatus.value = ConnectivityResult.none;
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final status = result.isNotEmpty ? result.first : ConnectivityResult.none;

    if (connectionStatus.value != status) {
      LogService.info("Network status changed: ${connectionStatus.value} -> $status");
    }

    connectionStatus.value = status;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
