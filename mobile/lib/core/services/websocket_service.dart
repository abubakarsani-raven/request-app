import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/app_constants.dart';
import 'storage_service.dart';

class WebSocketService extends GetxService {
  IO.Socket? _socket;
  final RxBool isConnected = false.obs;
  final RxString connectionStatus = 'Disconnected'.obs;

  @override
  void onInit() {
    super.onInit();
    connect();
  }

  void connect() {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return;
      }

      _socket = IO.io(
        '${AppConstants.wsBaseUrl}/updates',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .build(),
      );

      _socket!.onConnect((_) {
        isConnected.value = true;
        connectionStatus.value = 'Connected';
        print('WebSocket Connected');
        _setupNotificationListeners();
      });

      _socket!.onDisconnect((_) {
        isConnected.value = false;
        connectionStatus.value = 'Disconnected';
        print('WebSocket Disconnected');
      });

      _socket!.onError((error) {
        print('WebSocket Error: $error');
        connectionStatus.value = 'Error: $error';
      });

      _socket!.onConnectError((error) {
        print('WebSocket Connect Error: $error');
        connectionStatus.value = 'Connection Error';
      });
    } catch (e) {
      print('WebSocket Connection Error: $e');
    }
  }

  void _setupNotificationListeners() {
    // Listen for new notifications
    _socket?.on('notification:new', (data) {
      print('Received notification:new event: $data');
      // This will be handled by NotificationController if available
      _notifyController('handleWebSocketNotification', data);
    });

    // Listen for workflow progress updates
    _socket?.on('request:progress', (data) {
      print('Received request:progress event: $data');
      // This will be handled by NotificationController if available
      _notifyController('handleWorkflowProgress', data);
    });
  }

  void _notifyController(String method, dynamic data) {
    try {
      // Try to find NotificationController using Get.find
      // Since NotificationController is registered with Get.lazyPut,
      // it will be created when first accessed
      try {
        // Use a type-safe approach by checking if it's registered first
        // We'll use Get.find which will create it if needed (lazyPut with fenix: true)
        final controller = Get.find(tag: 'NotificationController');
        if (controller != null) {
          if (method == 'handleWebSocketNotification') {
            (controller as dynamic).handleWebSocketNotification(data);
          } else if (method == 'handleWorkflowProgress') {
            (controller as dynamic).handleWorkflowProgress(data);
          }
        }
      } catch (e) {
        // Controller might not be registered yet or not accessible
        // This is okay - events will be queued or handled when controller is available
        print('Could not notify NotificationController: $e');
      }
    } catch (e) {
      print('Error in _notifyController: $e');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    isConnected.value = false;
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void joinRequestRoom(String requestId) {
    emit('request:join', {'requestId': requestId});
  }

  void leaveRequestRoom(String requestId) {
    emit('request:leave', {'requestId': requestId});
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}

