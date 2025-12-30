import 'package:get/get.dart';

class AssignmentSelectionController extends GetxController {
  final Rxn<String> selectedVehicleId = Rxn<String>();
  final Rxn<String> selectedDriverId = Rxn<String>();
  final RxString vehicleSearchQuery = ''.obs;
  final RxString driverSearchQuery = ''.obs;

  void selectVehicle(String? id) {
    selectedVehicleId.value = selectedVehicleId.value == id ? null : id;
  }

  void selectDriver(String? id) {
    selectedDriverId.value = selectedDriverId.value == id ? null : id;
  }

  void clearVehicleSelection() {
    selectedVehicleId.value = null;
  }

  void clearDriverSelection() {
    selectedDriverId.value = null;
  }

  void clearVehicleSearch() {
    vehicleSearchQuery.value = '';
  }

  void clearDriverSearch() {
    driverSearchQuery.value = '';
  }
}
