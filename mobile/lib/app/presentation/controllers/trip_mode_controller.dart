import 'package:get/get.dart';
import '../../data/models/request_model.dart';

enum TripViewMode {
  navigation, // Simplified UI for active driving
  monitoring, // Full information display
}

class TripModeController extends GetxController {
  final Rx<TripViewMode> currentMode = TripViewMode.monitoring.obs;
  
  /// Auto-switch to navigation mode when trip starts
  void updateModeBasedOnTrip(VehicleRequestModel? trip) {
    if (trip == null) {
      currentMode.value = TripViewMode.monitoring;
      return;
    }
    
    // Auto-switch to navigation mode when trip is active
    if (trip.tripStarted && !trip.tripCompleted) {
      currentMode.value = TripViewMode.navigation;
    } else {
      // Default to monitoring for viewing completed trips or not started
      currentMode.value = TripViewMode.monitoring;
    }
  }
  
  /// Manually toggle between modes
  void toggleMode() {
    currentMode.value = currentMode.value == TripViewMode.navigation
        ? TripViewMode.monitoring
        : TripViewMode.navigation;
  }
  
  /// Set mode explicitly
  void setMode(TripViewMode mode) {
    currentMode.value = mode;
  }
  
  bool get isNavigationMode => currentMode.value == TripViewMode.navigation;
  bool get isMonitoringMode => currentMode.value == TripViewMode.monitoring;
}
