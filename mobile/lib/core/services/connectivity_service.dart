import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

/// Exposes network connectivity state. Listen to [isOnline] to show offline banner or skip auto-refresh.
class ConnectivityService extends GetxService {
  final RxBool isOnline = true.obs;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    try {
      final result = await Connectivity().checkConnectivity();
      isOnline.value = _hasConnection(result);
      _subscription = Connectivity().onConnectivityChanged.listen((result) {
        isOnline.value = _hasConnection(result);
      });
    } catch (_) {
      isOnline.value = true;
    }
  }

  bool _hasConnection(List<ConnectivityResult> result) {
    if (result.isEmpty) return true;
    return result.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn ||
        r == ConnectivityResult.other);
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
