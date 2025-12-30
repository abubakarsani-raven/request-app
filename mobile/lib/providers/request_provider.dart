import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../models/request_model.dart';

class RequestProvider with ChangeNotifier {
  final ApiService apiService;
  List<RequestModel> _vehicleRequests = [];
  List<RequestModel> _ictRequests = [];
  List<RequestModel> _storeRequests = [];
  bool _isLoading = false;

  RequestProvider({required this.apiService});

  List<RequestModel> get vehicleRequests => _vehicleRequests;
  List<RequestModel> get ictRequests => _ictRequests;
  List<RequestModel> get storeRequests => _storeRequests;
  bool get isLoading => _isLoading;

  Future<void> loadVehicleRequests({bool myRequests = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.get(
        '/vehicles/requests',
        queryParameters: myRequests ? {'myRequests': 'true'} : null,
      );
      _vehicleRequests = (response.data as List)
          .map((json) => RequestModel.fromJson(json, RequestType.VEHICLE))
          .toList();
    } catch (e) {
      debugPrint('Error loading vehicle requests: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadICTRequests({bool myRequests = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.get(
        '/ict/requests',
        queryParameters: myRequests ? {'myRequests': 'true'} : null,
      );
      _ictRequests = (response.data as List)
          .map((json) => RequestModel.fromJson(json, RequestType.ICT))
          .toList();
    } catch (e) {
      debugPrint('Error loading ICT requests: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadStoreRequests({bool myRequests = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.get(
        '/store/requests',
        queryParameters: myRequests ? {'myRequests': 'true'} : null,
      );
      _storeRequests = (response.data as List)
          .map((json) => RequestModel.fromJson(json, RequestType.STORE))
          .toList();
    } catch (e) {
      debugPrint('Error loading store requests: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}

