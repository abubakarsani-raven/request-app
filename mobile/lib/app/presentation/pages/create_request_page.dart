import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import '../controllers/request_controller.dart';
import '../controllers/ict_request_controller.dart';
import '../controllers/store_request_controller.dart';
import '../controllers/notification_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/map_picker.dart';
import '../widgets/catalog_browser.dart';
import '../widgets/inventory_browser.dart';
import '../widgets/app_drawer.dart';
import '../widgets/loading_overlay.dart';
import '../../../core/utils/validators.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../../core/widgets/bottom_sheet_wrapper.dart';
import '../../data/services/office_service.dart';

class CreateRequestPage extends StatefulWidget {
  final String type;

  const CreateRequestPage({Key? key, required this.type}) : super(key: key);

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _drawerController = AdvancedDrawerController();
  final _tripDateController = TextEditingController();
  final _tripTimeController = TextEditingController();
  final _returnDateController = TextEditingController();
  final _returnTimeController = TextEditingController();
  final _destinationController = TextEditingController();
  final _purposeController = TextEditingController();
  final _startPointController = TextEditingController();
  final _dropOffController = TextEditingController();
  RequestController? _requestController;
  ICTRequestController? _ictController;
  StoreRequestController? _storeController;
  final OfficeService _officeService = OfficeService();
  
  // Getters to safely access controllers
  RequestController get requestController => _requestController ??= Get.find<RequestController>();
  ICTRequestController get ictController => _ictController ??= Get.find<ICTRequestController>();
  StoreRequestController get storeController => _storeController ??= Get.find<StoreRequestController>();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DateTime? _selectedReturnDate;
  TimeOfDay? _selectedReturnTime;
  double? _destinationLatitude;
  double? _destinationLongitude;
  double? _officeLatitude;
  double? _officeLongitude;
  String? _selectedDestinationAddress;
  
  // Start point state
  double? _startLatitude;
  double? _startLongitude;
  String? _startAddress;
  
  // Drop-off point state
  double? _dropOffLatitude;
  double? _dropOffLongitude;
  String? _dropOffAddress;
  
  // Pickup points (waypoints)
  List<Map<String, dynamic>> _pickupPoints = []; // Each has: name, latitude, longitude, address, order
  
  // Route estimation
  double? _estimatedDistance;
  double? _estimatedFuel;
  
  List<Map<String, dynamic>> _selectedItems = [];
  final ValueNotifier<Map<String, dynamic>?> _locationNotifier = ValueNotifier<Map<String, dynamic>?>(null);
  final ValueNotifier<Map<String, dynamic>?> _startLocationNotifier = ValueNotifier<Map<String, dynamic>?>(null);
  final ValueNotifier<Map<String, dynamic>?> _dropOffLocationNotifier = ValueNotifier<Map<String, dynamic>?>(null);
  final List<ValueNotifier<Map<String, dynamic>?>> _pickupLocationNotifiers = [];

  @override
  void initState() {
    super.initState();
    // Use Get.find() - controllers already registered in InitialBinding
    // Initialize only if not already initialized (prevents LateInitializationError on rebuild)
    _requestController ??= Get.find<RequestController>();
    _ictController ??= Get.find<ICTRequestController>();
    _storeController ??= Get.find<StoreRequestController>();
      // Check if we have pre-filled data from repeating a request
      final params = Get.parameters;
      
      if (params.containsKey('tripDate') && params['tripDate'] != null) {
        try {
          _selectedDate = DateTime.parse(params['tripDate']!);
          _tripDateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        } catch (e) {
          _selectedDate = DateTime.now();
          _tripDateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        }
      } else {
        _selectedDate = DateTime.now();
        _tripDateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      }
      
      if (params.containsKey('returnDate') && params['returnDate'] != null) {
        try {
          _selectedReturnDate = DateTime.parse(params['returnDate']!);
          _returnDateController.text = DateFormat('yyyy-MM-dd').format(_selectedReturnDate!);
        } catch (e) {
          _selectedReturnDate = DateTime.now();
          _returnDateController.text = DateFormat('yyyy-MM-dd').format(_selectedReturnDate!);
        }
      } else {
        _selectedReturnDate = DateTime.now();
        _returnDateController.text = DateFormat('yyyy-MM-dd').format(_selectedReturnDate!);
      }
      
      // Pre-fill other fields if provided
      if (params.containsKey('tripTime')) {
        _tripTimeController.text = params['tripTime']!;
      }
      if (params.containsKey('returnTime')) {
        _returnTimeController.text = params['returnTime']!;
      }
      if (params.containsKey('destination')) {
        _destinationController.text = params['destination']!;
      }
      if (params.containsKey('purpose')) {
        _purposeController.text = params['purpose']!;
      }
      
      // Pre-fill location data if provided
      if (params.containsKey('destinationLatitude') && params.containsKey('destinationLongitude')) {
        try {
          _destinationLatitude = double.parse(params['destinationLatitude']!);
          _destinationLongitude = double.parse(params['destinationLongitude']!);
          _selectedDestinationAddress = params['destination'] ?? '';
        } catch (e) {
          print('Error parsing destination location: $e');
        }
      }
      
      if (params.containsKey('startLatitude') && params.containsKey('startLongitude')) {
        try {
          _startLatitude = double.parse(params['startLatitude']!);
          _startLongitude = double.parse(params['startLongitude']!);
          _startAddress = params['startAddress'] ?? 'Start Point';
          _startPointController.text = _startAddress!;
        } catch (e) {
          print('Error parsing start location: $e');
        }
      }
      
      if (params.containsKey('returnLatitude') && params.containsKey('returnLongitude')) {
        try {
          _dropOffLatitude = double.parse(params['returnLatitude']!);
          _dropOffLongitude = double.parse(params['returnLongitude']!);
          _dropOffAddress = params['returnAddress'] ?? 'Return Point';
          _dropOffController.text = _dropOffAddress!;
        } catch (e) {
          print('Error parsing return location: $e');
        }
      }
      
      _initializeOfficeLocation();
  }
  
  Future<void> _initializeOfficeLocation() async {
    // Fetch head office location from API
    try {
      final headOffice = await _officeService.getHeadOffice();
      if (headOffice != null) {
        setState(() {
          _officeLatitude = headOffice.latitude;
          _officeLongitude = headOffice.longitude;
          _startLatitude = _officeLatitude;
          _startLongitude = _officeLongitude;
          _startAddress = headOffice.name;
          _startPointController.text = _startAddress!;
        });
        return;
      }
    } catch (e) {
      print('Error fetching head office: $e');
    }
    
    // Fallback to default coordinates if API call fails
    setState(() {
      _officeLatitude = 6.5244; // Default Lagos coordinates
      _officeLongitude = 3.3792;
      _startLatitude = _officeLatitude;
      _startLongitude = _officeLongitude;
      _startAddress = 'Office (Default)';
      _startPointController.text = _startAddress!;
    });
  }

  @override
  void dispose() {
    _tripDateController.dispose();
    _tripTimeController.dispose();
    _returnDateController.dispose();
    _returnTimeController.dispose();
    _destinationController.dispose();
    _purposeController.dispose();
    _startPointController.dispose();
    _dropOffController.dispose();
    _locationNotifier.dispose();
    _startLocationNotifier.dispose();
    _dropOffLocationNotifier.dispose();
    for (var notifier in _pickupLocationNotifiers) {
      notifier.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tripDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        // Auto-update return date if it's before trip date
        if (_selectedReturnDate == null || _selectedReturnDate!.isBefore(picked)) {
          _selectedReturnDate = picked;
          _returnDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  Future<void> _selectReturnDate() async {
    // Ensure trip date is selected first
    if (_selectedDate == null) {
      CustomToast.warning(
        'Please select trip date first',
        title: 'Missing Information',
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedReturnDate ?? _selectedDate!,
      firstDate: _selectedDate!, // Return date cannot be before trip date
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _selectedReturnDate) {
      setState(() {
        _selectedReturnDate = picked;
        _returnDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        
        // If return time is already set, validate it's still valid with the new date
        if (_selectedReturnTime != null && _selectedTime != null) {
          final DateTime tripDateTime = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          );
          
          final DateTime returnDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _selectedReturnTime!.hour,
            _selectedReturnTime!.minute,
          );
          
          // If return datetime is now invalid, clear it
          if (returnDateTime.isBefore(tripDateTime) || 
              returnDateTime.isAtSameMomentAs(tripDateTime)) {
            _selectedReturnTime = null;
            _returnTimeController.clear();
            CustomToast.warning(
              'Return time has been cleared. Please select a new return time',
            );
          } else if (picked.year == _selectedDate!.year &&
                     picked.month == _selectedDate!.month &&
                     picked.day == _selectedDate!.day) {
            // Same date: check if still at least 1 hour apart
            final Duration difference = returnDateTime.difference(tripDateTime);
            if (difference.inHours < 1) {
              _selectedReturnTime = null;
              _returnTimeController.clear();
              CustomToast.warning(
                'Return time has been cleared. Please select a new return time at least 1 hour after trip time',
              );
            }
          }
        }
      });
    }
  }

  Future<void> _selectTime() async {
    final DateTime now = DateTime.now();
    final DateTime selectedDate = _selectedDate ?? now;
    
    // Calculate minimum and maximum allowed times
    TimeOfDay? minTime;
    TimeOfDay? maxTime;
    
    // Check if selected date is today
    final bool isToday = selectedDate.year == now.year &&
                         selectedDate.month == now.month &&
                         selectedDate.day == now.day;
    
    if (isToday) {
      // For today: minimum is 1 hour from now, maximum is 2 hours from now
      final DateTime minDateTime = now.add(const Duration(hours: 1));
      final DateTime maxDateTime = now.add(const Duration(hours: 2));
      
      minTime = TimeOfDay.fromDateTime(minDateTime);
      maxTime = TimeOfDay.fromDateTime(maxDateTime);
    } else {
      // For future dates: minimum is start of day, maximum is 2 hours from now (if same day logic needed)
      // For simplicity, allow any time for future dates, but we can add validation if needed
      minTime = const TimeOfDay(hour: 0, minute: 0);
      maxTime = const TimeOfDay(hour: 23, minute: 59);
    }
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? minTime,
      helpText: isToday 
          ? 'Select time between ${minTime.format(context)} and ${maxTime.format(context)}'
          : 'Select trip time',
    );
    
    if (picked != null) {
      // Validate the selected time
      if (isToday) {
        final DateTime pickedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          picked.hour,
          picked.minute,
        );
        final DateTime minDateTime = now.add(const Duration(hours: 1));
        final DateTime maxDateTime = now.add(const Duration(hours: 2));
        
        if (pickedDateTime.isBefore(minDateTime)) {
          CustomToast.warning(
            'You must book at least 1 hour in advance. Minimum time is ${minTime.format(context)}',
            title: 'Invalid Time',
          );
          return;
        }
        
        if (pickedDateTime.isAfter(maxDateTime)) {
          CustomToast.warning(
            'You can only book up to 2 hours in advance. Maximum time is ${maxTime.format(context)}',
            title: 'Invalid Time',
          );
          return;
        }
      }
      
      setState(() {
        _selectedTime = picked;
        _tripTimeController.text = picked.format(context);
        
        // If return date/time is already set, validate it's still valid
        if (_selectedReturnDate != null && _selectedReturnTime != null) {
          final DateTime tripDateTime = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            picked.hour,
            picked.minute,
          );
          
          final DateTime returnDateTime = DateTime(
            _selectedReturnDate!.year,
            _selectedReturnDate!.month,
            _selectedReturnDate!.day,
            _selectedReturnTime!.hour,
            _selectedReturnTime!.minute,
          );
          
          // If return datetime is now invalid, clear it
          if (returnDateTime.isBefore(tripDateTime) || 
              returnDateTime.isAtSameMomentAs(tripDateTime)) {
            _selectedReturnTime = null;
            _returnTimeController.clear();
            CustomToast.warning(
              'Return time has been cleared. Please select a new return time after the trip time',
            );
          } else if (_selectedReturnDate!.year == _selectedDate!.year &&
                     _selectedReturnDate!.month == _selectedDate!.month &&
                     _selectedReturnDate!.day == _selectedDate!.day) {
            // Same date: check if still at least 1 hour apart
            final Duration difference = returnDateTime.difference(tripDateTime);
            if (difference.inHours < 1) {
              _selectedReturnTime = null;
              _returnTimeController.clear();
              CustomToast.warning(
                'Return time has been cleared. Please select a new return time at least 1 hour after trip time',
              );
            }
          }
        }
      });
    }
  }

  Future<void> _selectReturnTime() async {
    // Ensure trip date and time are selected first
    if (_selectedDate == null || _selectedTime == null) {
      CustomToast.warning(
        'Please select trip date and time first',
        title: 'Missing Information',
      );
      return;
    }

    final DateTime selectedReturnDate = _selectedReturnDate ?? _selectedDate!;
    final DateTime tripDate = _selectedDate!;
    
    // Build full datetime objects for comparison
    final DateTime tripDateTime = DateTime(
      tripDate.year,
      tripDate.month,
      tripDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    
    // Calculate minimum allowed time based on date comparison
    TimeOfDay? minTime;
    String helpText;
    
    // Compare dates
    final int dateComparison = selectedReturnDate.compareTo(tripDate);
    
    if (dateComparison < 0) {
      // Return date is before trip date - this should not happen, but handle it
      CustomToast.error(
        'Return date cannot be before trip date',
      );
      return;
    } else if (dateComparison == 0) {
      // Same date: return time must be at least 1 hour after trip time
      final DateTime minReturnDateTime = tripDateTime.add(const Duration(hours: 1));
      minTime = TimeOfDay.fromDateTime(minReturnDateTime);
      helpText = 'Return time must be at least 1 hour after trip time (${_selectedTime!.format(context)})';
    } else {
      // Return date is after trip date: any time is allowed
      minTime = const TimeOfDay(hour: 0, minute: 0);
      helpText = 'Select return time';
    }
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedReturnTime ?? minTime,
      helpText: helpText,
    );
    
    if (picked != null) {
      // Build full return datetime for validation
      final DateTime returnDateTime = DateTime(
        selectedReturnDate.year,
        selectedReturnDate.month,
        selectedReturnDate.day,
        picked.hour,
        picked.minute,
      );
      
      // Validate return datetime is after trip datetime
      if (returnDateTime.isBefore(tripDateTime) || 
          returnDateTime.isAtSameMomentAs(tripDateTime)) {
        CustomToast.error(
          'Return date and time must be after trip date and time',
        );
        return;
      }
      
      // If same date, ensure at least 1 hour difference
      if (dateComparison == 0) {
        final DateTime minReturnDateTime = tripDateTime.add(const Duration(hours: 1));
        if (returnDateTime.isBefore(minReturnDateTime)) {
          CustomToast.error(
            'Return time must be at least 1 hour after trip time',
          );
          return;
        }
      }
      
      setState(() {
        _selectedReturnTime = picked;
        _returnTimeController.text = picked.format(context);
      });
    }
  }

  void _onDestinationSelected(double lat, double lng, String address) {
    setState(() {
      _destinationLatitude = lat;
      _destinationLongitude = lng;
      _selectedDestinationAddress = address;
      _destinationController.text = address;
    });
    _calculateRouteDistance();
  }

  // Haversine formula to calculate distance between two coordinates
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = (dLat / 2) * (dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * (dLon / 2) * (dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  void _calculateRouteDistance() {
    if (_startLatitude == null || _startLongitude == null ||
        _destinationLatitude == null || _destinationLongitude == null ||
        _officeLatitude == null || _officeLongitude == null) {
      setState(() {
        _estimatedDistance = null;
        _estimatedFuel = null;
      });
      return;
    }

    double totalDistance = 0.0;
    double lastLat = _startLatitude!;
    double lastLng = _startLongitude!;

    // Leg 1: Start point to first pickup (or destination if no pickups)
    if (_pickupPoints.isNotEmpty) {
      // Start → Pickup 1
      totalDistance += _calculateDistance(
        lastLat,
        lastLng,
        _pickupPoints[0]['latitude'] as double,
        _pickupPoints[0]['longitude'] as double,
      );
      lastLat = _pickupPoints[0]['latitude'] as double;
      lastLng = _pickupPoints[0]['longitude'] as double;

      // Pickup to Pickup (if multiple)
      for (int i = 1; i < _pickupPoints.length; i++) {
        totalDistance += _calculateDistance(
          lastLat,
          lastLng,
          _pickupPoints[i]['latitude'] as double,
          _pickupPoints[i]['longitude'] as double,
        );
        lastLat = _pickupPoints[i]['latitude'] as double;
        lastLng = _pickupPoints[i]['longitude'] as double;
      }

      // Last pickup → Destination
      totalDistance += _calculateDistance(
        lastLat,
        lastLng,
        _destinationLatitude!,
        _destinationLongitude!,
      );
    } else {
      // Start → Destination (no pickups)
      totalDistance += _calculateDistance(
        lastLat,
        lastLng,
        _destinationLatitude!,
        _destinationLongitude!,
      );
    }

    lastLat = _destinationLatitude!;
    lastLng = _destinationLongitude!;

    // Leg 2: Destination → Drop-off (if set) or Office
    if (_dropOffLatitude != null && _dropOffLongitude != null) {
      // Destination → Drop-off
      totalDistance += _calculateDistance(
        lastLat,
        lastLng,
        _dropOffLatitude!,
        _dropOffLongitude!,
      );
      lastLat = _dropOffLatitude!;
      lastLng = _dropOffLongitude!;
    }

    // Leg 3: Drop-off (or Destination) → Office
    totalDistance += _calculateDistance(
      lastLat,
      lastLng,
      _officeLatitude!,
      _officeLongitude!,
    );

    // Calculate fuel consumption
    // Using realistic fuel economy: 10 km/liter (24 MPG) for mixed city/highway driving
    // This is typical for a Toyota Camry or similar sedan
    const double kmPerLiter = 10.0; // 10 km per liter
    final estimatedFuel = totalDistance / kmPerLiter;

    setState(() {
      _estimatedDistance = totalDistance;
      _estimatedFuel = estimatedFuel;
    });
  }

  Future<Map<String, dynamic>?> _showLocationPicker({
    required String title,
    double? initialLatitude,
    double? initialLongitude,
    required ValueNotifier<Map<String, dynamic>?> locationNotifier,
  }) async {
    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.darkSurface 
                  : theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: isDark 
                      ? AppColors.darkBorderDefined.withOpacity(0.5)
                      : AppColors.border.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? AppColors.darkBorderDefined 
                        : Colors.grey[400],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            height: 1.2,
                            color: isDark 
                                ? AppColors.darkTextPrimary 
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close, 
                          size: 22,
                          color: isDark 
                              ? AppColors.darkTextPrimary 
                              : AppColors.textPrimary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark 
                      ? AppColors.darkBorderDefined.withOpacity(0.5)
                      : AppColors.border.withOpacity(0.5),
                ),
              // Map Picker - Takes remaining space
              Expanded(
                child: MapPicker(
                  initialLatitude: initialLatitude,
                  initialLongitude: initialLongitude,
                  locationNotifier: locationNotifier,
                  onLocationSelected: null, // Don't auto-confirm
                ),
              ),
              // Confirm Button
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? AppColors.darkSurface 
                        : theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: isDark 
                            ? AppColors.darkBorderDefined.withOpacity(0.5)
                            : AppColors.border.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: ValueListenableBuilder<Map<String, dynamic>?>(
                    valueListenable: locationNotifier,
                    builder: (context, locationData, child) {
                      final hasLocation = locationData?['hasLocation'] == true;
                      final isLoading = locationData?['isLoading'] == true;
                      
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: hasLocation && !isLoading
                              ? () {
                                  final lat = locationData!['lat'] as double;
                                  final lng = locationData['lng'] as double;
                                  final address = locationData['address'] as String;
                                  Navigator.pop(context, {
                                    'latitude': lat,
                                    'longitude': lng,
                                    'address': address,
                                  });
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: hasLocation && !isLoading
                                ? theme.colorScheme.primary 
                                : (isDark 
                                    ? AppColors.darkTextDisabled 
                                    : AppColors.textDisabled),
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Confirm Location',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Future<void> _showDestinationPicker() async {
    final result = await _showLocationPicker(
      title: 'Select Destination',
      initialLatitude: _destinationLatitude,
      initialLongitude: _destinationLongitude,
      locationNotifier: _locationNotifier,
    );

    if (result != null) {
      _onDestinationSelected(
        result['latitude'] as double,
        result['longitude'] as double,
        result['address'] as String,
      );
    }
  }

  Future<void> _showStartPointPicker() async {
    final result = await _showLocationPicker(
      title: 'Select Start Point',
      initialLatitude: _startLatitude,
      initialLongitude: _startLongitude,
      locationNotifier: _startLocationNotifier,
    );

    if (result != null) {
      setState(() {
        _startLatitude = result['latitude'] as double;
        _startLongitude = result['longitude'] as double;
        _startAddress = result['address'] as String;
        _startPointController.text = _startAddress!;
      });
      _calculateRouteDistance();
    }
  }

  Future<void> _showDropOffPicker() async {
    final result = await _showLocationPicker(
      title: 'Select Drop-off Point',
      initialLatitude: _dropOffLatitude,
      initialLongitude: _dropOffLongitude,
      locationNotifier: _dropOffLocationNotifier,
    );

    if (result != null) {
      setState(() {
        _dropOffLatitude = result['latitude'] as double;
        _dropOffLongitude = result['longitude'] as double;
        _dropOffAddress = result['address'] as String;
        _dropOffController.text = _dropOffAddress!;
      });
      _calculateRouteDistance();
    }
  }

  Future<void> _showPickupPointPicker(int? index) async {
    // Create a notifier for this pickup point if it doesn't exist
    while (_pickupLocationNotifiers.length <= (index ?? _pickupPoints.length)) {
      _pickupLocationNotifiers.add(ValueNotifier<Map<String, dynamic>?>(null));
    }
    
    final notifierIndex = index ?? _pickupPoints.length;
    final notifier = _pickupLocationNotifiers[notifierIndex];
    
    double? initialLat;
    double? initialLng;
    if (index != null && index < _pickupPoints.length) {
      initialLat = _pickupPoints[index]['latitude'] as double?;
      initialLng = _pickupPoints[index]['longitude'] as double?;
    }

    final result = await _showLocationPicker(
      title: index != null ? 'Edit Pickup Point ${index + 1}' : 'Add Pickup Point',
      initialLatitude: initialLat,
      initialLongitude: initialLng,
      locationNotifier: notifier,
    );

    if (result != null) {
      final pickupPoint = {
        'name': result['address'] as String,
        'latitude': result['latitude'] as double,
        'longitude': result['longitude'] as double,
        'address': result['address'] as String,
        'order': index != null ? _pickupPoints[index]['order'] as int : _pickupPoints.length + 1,
      };

      setState(() {
        if (index != null && index < _pickupPoints.length) {
          _pickupPoints[index] = pickupPoint;
        } else {
          _pickupPoints.add(pickupPoint);
        }
        // Reorder pickup points
        _pickupPoints.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
      });
      _calculateRouteDistance();
    }
  }

  void _removePickupPoint(int index) {
    setState(() {
      _pickupPoints.removeAt(index);
      // Reorder remaining points
      for (int i = 0; i < _pickupPoints.length; i++) {
        _pickupPoints[i]['order'] = i + 1;
      }
    });
    _calculateRouteDistance();
  }

  void _onItemsSelected(List<Map<String, dynamic>> items) {
    setState(() {
      _selectedItems = items;
    });
  }

  Future<void> _submitRequest() async {
    if (widget.type == 'vehicle') {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      if (_destinationLatitude == null || _destinationLongitude == null) {
        CustomToast.warning(
          'Please select a destination on the map',
          title: 'Missing Information',
        );
        return;
      }

      // Validate time constraints
      final DateTime now = DateTime.now();
      final DateTime selectedDate = _selectedDate ?? now;
      final bool isToday = selectedDate.year == now.year &&
                           selectedDate.month == now.month &&
                           selectedDate.day == now.day;
      
      if (isToday && _selectedTime != null) {
        final DateTime tripDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
        
        final DateTime minDateTime = now.add(const Duration(hours: 1));
        final DateTime maxDateTime = now.add(const Duration(hours: 2));
        
        if (tripDateTime.isBefore(minDateTime)) {
          CustomToast.warning(
            'You must book at least 1 hour in advance',
            title: 'Invalid Time',
          );
          return;
        }
        
        if (tripDateTime.isAfter(maxDateTime)) {
          CustomToast.warning(
            'You can only book up to 2 hours in advance',
            title: 'Invalid Time',
          );
          return;
        }
      }

      // Validate return date/time is after trip date/time (combined validation)
      if (_selectedReturnDate == null || _selectedReturnTime == null) {
        CustomToast.error(
          'Please select return date and time',
        );
        return;
      }

      if (_selectedTime == null) {
        CustomToast.error(
          'Please select trip time',
        );
        return;
      }

      // Build full datetime objects for comparison
      final DateTime tripDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      
      final DateTime returnDateTime = DateTime(
        _selectedReturnDate!.year,
        _selectedReturnDate!.month,
        _selectedReturnDate!.day,
        _selectedReturnTime!.hour,
        _selectedReturnTime!.minute,
      );
      
      // Validate return datetime is after trip datetime
      if (returnDateTime.isBefore(tripDateTime) || 
          returnDateTime.isAtSameMomentAs(tripDateTime)) {
        CustomToast.error(
          'Return date and time must be after trip date and time',
        );
        return;
      }
      
      // If same date, ensure at least 1 hour difference
      final bool isSameDate = _selectedReturnDate!.year == _selectedDate!.year &&
                              _selectedReturnDate!.month == _selectedDate!.month &&
                              _selectedReturnDate!.day == _selectedDate!.day;
      
      if (isSameDate) {
        final Duration difference = returnDateTime.difference(tripDateTime);
        if (difference.inHours < 1) {
          CustomToast.error(
            'Return time must be at least 1 hour after trip time',
          );
          return;
        }
      }

      final data = {
        'tripDate': _tripDateController.text,
        'tripTime': _tripTimeController.text,
        'returnDate': _returnDateController.text,
        'returnTime': _returnTimeController.text,
        'destination': _destinationController.text,
        'purpose': _purposeController.text,
        'destinationLatitude': _destinationLatitude,
        'destinationLongitude': _destinationLongitude,
      };

      // Add office location (for reference)
      if (_officeLatitude != null && _officeLongitude != null) {
        data['officeLatitude'] = _officeLatitude;
        data['officeLongitude'] = _officeLongitude;
      }

      // Add start point (if different from office)
      if (_startLatitude != null && _startLongitude != null &&
          (_startLatitude != _officeLatitude || _startLongitude != _officeLongitude)) {
        data['startLatitude'] = _startLatitude;
        data['startLongitude'] = _startLongitude;
      }

      // Add drop-off point (if set)
      if (_dropOffLatitude != null && _dropOffLongitude != null) {
        data['dropOffLatitude'] = _dropOffLatitude;
        data['dropOffLongitude'] = _dropOffLongitude;
      }

      // Add waypoints (pickup points)
      if (_pickupPoints.isNotEmpty) {
        data['waypoints'] = _pickupPoints.map((point) => {
          'name': point['name'] as String,
          'latitude': point['latitude'] as double,
          'longitude': point['longitude'] as double,
          'order': point['order'] as int,
        }).toList();
      }

      final success = await requestController.createVehicleRequest(data);

      if (success) {
        if (Get.isRegistered<NotificationController>()) {
          try {
            final notificationController = Get.find<NotificationController>();
            await notificationController.loadNotifications(unreadOnly: false);
            await notificationController.loadUnreadCount();
          } catch (e) {
            // Non-fatal: continue without refresh
          }
        }
        Get.back();
        CustomToast.success(
          'Vehicle request created successfully',
          title: 'Success',
        );
      } else {
        CustomToast.error(
          requestController.error.value.isNotEmpty
              ? requestController.error.value
              : 'Failed to create request',
          title: 'Error',
        );
      }
    } else if (widget.type == 'ict') {
      if (_selectedItems.isEmpty) {
        CustomToast.warning(
          'Please select at least one catalog item',
          title: 'Missing Items',
        );
        return;
      }

      final success = await ictController.createICTRequest(_selectedItems);

      if (success) {
        if (Get.isRegistered<NotificationController>()) {
          try {
            final notificationController = Get.find<NotificationController>();
            await notificationController.loadNotifications(unreadOnly: false);
            await notificationController.loadUnreadCount();
          } catch (e) {
            // Non-fatal: continue without refresh
          }
        }
        Get.back();
        CustomToast.success(
          'ICT request created successfully',
          title: 'Success',
        );
      } else {
        CustomToast.error(
          ictController.error.value.isNotEmpty
              ? ictController.error.value
              : 'Failed to create request',
          title: 'Error',
        );
      }
    } else if (widget.type == 'store') {
      if (_selectedItems.isEmpty) {
        CustomToast.warning(
          'Please select at least one inventory item',
          title: 'Missing Items',
        );
        return;
      }

      final success = await storeController.createStoreRequest(_selectedItems);

      if (success) {
        if (Get.isRegistered<NotificationController>()) {
          try {
            final notificationController = Get.find<NotificationController>();
            await notificationController.loadNotifications(unreadOnly: false);
            await notificationController.loadUnreadCount();
          } catch (e) {
            // Non-fatal: continue without refresh
          }
        }
        Get.back();
        CustomToast.success(
          'Store request created successfully',
          title: 'Success',
        );
      } else {
        CustomToast.error(
          storeController.error.value.isNotEmpty
              ? storeController.error.value
              : 'Failed to create request',
          title: 'Error',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title;
    Widget body;

    switch (widget.type) {
      case 'vehicle':
        title = 'Create Vehicle Request';
        body = _buildVehicleRequestForm();
        break;
      case 'ict':
        title = 'Create ICT Request';
        body = _buildICTRequestForm();
        break;
      case 'store':
        title = 'Create Store Request';
        body = _buildStoreRequestForm();
        break;
      default:
        title = 'Create Request';
        body = const Center(child: Text('Unknown request type'));
    }

    return AppDrawer(
      controller: _drawerController,
      child: Obx(
        () => LoadingOverlay(
          isLoading: (widget.type == 'vehicle' && requestController.isCreating.value) ||
                     (widget.type == 'ict' && ictController.isCreating.value) ||
                     (widget.type == 'store' && storeController.isCreating.value),
          message: 'Creating request...',
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Get.back(),
              ),
              title: Text(title),
              actions: widget.type == 'ict'
                  ? [
                      Obx(
                        () {
                          if (!Get.isRegistered<ICTRequestController>()) {
                            return const SizedBox.shrink();
                          }
                          final controller = Get.find<ICTRequestController>();
                          final hasActiveFilter = controller.selectedCategory.value.isNotEmpty;
                          return IconButton(
                            icon: Stack(
                              children: [
                                const Icon(Icons.filter_list_rounded),
                                if (hasActiveFilter)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const SizedBox(
                                        width: 8,
                                        height: 8,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onPressed: () => _showICTFilterBottomSheet(),
                            tooltip: 'Filter items',
                          );
                        },
                      ),
                    ]
                  : null,
            ),
            body: body,
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleRequestForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Route Planning',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: -0.5,
                    height: 1.3,
                  ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            
            // Start Point
            CustomTextField(
              label: 'Start Point',
              controller: _startPointController,
              prefixIcon: Icons.place,
              readOnly: true,
              hint: 'Office (default)',
              onTap: _showStartPointPicker,
            ),
            const SizedBox(height: AppConstants.spacingM),
            
            // Pickup Points Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pickup Points',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                ),
                TextButton.icon(
                  onPressed: () => _showPickupPointPicker(null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Pickup'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (_pickupPoints.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
                child: Text(
                  'No pickup points added',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              )
            else
              ..._pickupPoints.asMap().entries.map((entry) {
                final index = entry.key;
                final point = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(AppConstants.spacingS),
                    child: Row(
                      children: [
                        Icon(Icons.place, size: 18, color: AppColors.primary),
                        const SizedBox(width: AppConstants.spacingS),
                        Expanded(
                          child: Text(
                            point['name'] ?? 'Pickup Point ${index + 1}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: AppColors.error,
                          onPressed: () {
                            setState(() {
                              _pickupPoints.removeAt(index);
                              if (index < _pickupLocationNotifiers.length) {
                                _pickupLocationNotifiers[index].dispose();
                                _pickupLocationNotifiers.removeAt(index);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: AppConstants.spacingM),
            
            // Destination
            CustomTextField(
              label: 'Destination Address',
              controller: _destinationController,
              prefixIcon: Icons.location_on,
              validator: Validators.required,
              readOnly: true,
              hint: 'Tap to select destination on map',
              onTap: _showDestinationPicker,
            ),
            const SizedBox(height: AppConstants.spacingM),
            
            // Drop-off Point
            CustomTextField(
              label: 'Drop-off Point (Optional)',
              controller: _dropOffController,
              prefixIcon: Icons.flag,
              readOnly: true,
              hint: _dropOffAddress ?? 'Return to office',
              onTap: _showDropOffPicker,
            ),
            const SizedBox(height: AppConstants.spacingM),
            
            // Route Summary Card (Distance only - fuel shown to DGS/TO/Driver on detail page)
            if (_estimatedDistance != null)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics_outlined, color: AppColors.info, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Route Estimation',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                                fontSize: 16,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Distance',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${_estimatedDistance!.toStringAsFixed(2)} km',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_pickupPoints.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Includes ${_pickupPoints.length} pickup point(s)',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppConstants.spacingM),
            
            // Trip Details Section
            Text(
              'Trip Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: -0.5,
                    height: 1.3,
                  ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            CustomTextField(
              label: 'Trip Date',
              controller: _tripDateController,
              prefixIcon: Icons.calendar_today,
              readOnly: true,
              onTap: _selectDate,
              validator: Validators.required,
            ),
            const SizedBox(height: AppConstants.spacingM),
            CustomTextField(
              label: 'Trip Time',
              controller: _tripTimeController,
              prefixIcon: Icons.access_time,
              readOnly: true,
              onTap: _selectTime,
              validator: Validators.required,
            ),
            const SizedBox(height: AppConstants.spacingM),
            CustomTextField(
              label: 'Return Date',
              controller: _returnDateController,
              prefixIcon: Icons.calendar_today,
              readOnly: true,
              onTap: _selectReturnDate,
              validator: Validators.required,
            ),
            const SizedBox(height: AppConstants.spacingM),
            CustomTextField(
              label: 'Return Time',
              controller: _returnTimeController,
              prefixIcon: Icons.access_time,
              readOnly: true,
              onTap: _selectReturnTime,
              validator: Validators.required,
            ),
            const SizedBox(height: AppConstants.spacingM),
            CustomTextField(
              label: 'Purpose',
              controller: _purposeController,
              prefixIcon: Icons.description,
              maxLines: 3,
              validator: Validators.required,
            ),
            const SizedBox(height: AppConstants.spacingXXL),
            Obx(
              () => CustomButton(
                text: 'Submit Request',
                icon: Icons.send,
                onPressed: requestController.isLoading.value
                    ? null
                    : _submitRequest,
                isLoading: requestController.isLoading.value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFilterContent(
    BuildContext context,
    List<String> categories,
    String selectedCategory,
    ICTRequestController controller,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Category',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildFilterOption(
          context,
          label: 'All Categories',
          icon: Icons.apps_rounded,
          isSelected: selectedCategory.isEmpty,
          onTap: () {
            controller.selectedCategory.value = '';
            controller.loadCatalogItems();
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 8),
        ...categories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildFilterOption(
              context,
              label: category,
              icon: _getCategoryIcon(category),
              isSelected: selectedCategory == category,
              onTap: () {
                controller.selectedCategory.value = category;
                controller.loadCatalogItems(category: category);
                Navigator.pop(context);
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFilterOption(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? null
              : (isDark ? AppColors.darkSurfaceLight : AppColors.surfaceElevation1),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primaryLight.withOpacity(0.1),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.4)
                : (isDark 
                    ? AppColors.darkBorderDefined.withOpacity(0.3)
                    : AppColors.border.withOpacity(0.2)),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryLight,
                        ],
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark ? AppColors.darkSurface : AppColors.surface),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('printer') || lowerCategory.contains('print')) {
      return Icons.print_rounded;
    } else if (lowerCategory.contains('laptop') || lowerCategory.contains('computer')) {
      return Icons.laptop_mac_rounded;
    } else if (lowerCategory.contains('phone') || lowerCategory.contains('mobile')) {
      return Icons.phone_android_rounded;
    } else if (lowerCategory.contains('monitor') || lowerCategory.contains('screen') || lowerCategory.contains('display')) {
      return Icons.monitor_rounded;
    } else if (lowerCategory.contains('network') || lowerCategory.contains('router')) {
      return Icons.router_rounded;
    } else if (lowerCategory.contains('cable') || lowerCategory.contains('wire')) {
      return Icons.cable_rounded;
    } else if (lowerCategory.contains('keyboard') || lowerCategory.contains('mouse') || lowerCategory.contains('accessories')) {
      return Icons.mouse_rounded;
    } else if (lowerCategory.contains('toner') || lowerCategory.contains('cartridge')) {
      return Icons.auto_fix_high_rounded;
    } else if (lowerCategory.contains('storage') || lowerCategory.contains('hard drive')) {
      return Icons.storage_rounded;
    } else {
      return Icons.category_rounded;
    }
  }

  Widget _buildICTRequestForm() {
    return CatalogBrowser(
      onItemsSelected: _onItemsSelected,
      selectedItems: _selectedItems,
      onFilterTap: _showICTFilterBottomSheet,
    );
  }

  void _showICTFilterBottomSheet() {
    if (!Get.isRegistered<ICTRequestController>()) return;
    
    final controller = Get.find<ICTRequestController>();
    final categories = controller.categories;
    final selectedCategory = controller.selectedCategory.value;
    
    if (categories.isEmpty) {
      // Load categories first
      controller.loadCatalogItems().then((_) {
        if (controller.categories.isNotEmpty && mounted) {
          _showFilterSheet(controller, controller.categories, selectedCategory);
        }
      });
      return;
    }
    
    _showFilterSheet(controller, categories, selectedCategory);
  }

  void _showFilterSheet(ICTRequestController controller, List<String> categories, String selectedCategory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        title: 'Filter Items',
        applyText: 'Apply Filters',
        clearText: selectedCategory.isNotEmpty ? 'Clear' : null,
        activeFilterCount: selectedCategory.isNotEmpty ? 1 : 0,
        onApply: () => Navigator.pop(context),
        onClear: () {
          controller.selectedCategory.value = '';
          controller.loadCatalogItems();
          Navigator.pop(context);
        },
        initialChildSize: 0.6,
        child: _buildModernFilterContent(
          context,
          categories,
          selectedCategory,
          controller,
        ),
      ),
    );
  }

  Widget _buildStoreRequestForm() {
    return Column(
      children: [
        Expanded(
          child: InventoryBrowser(
            onItemsSelected: _onItemsSelected,
            selectedItems: _selectedItems,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(
                color: AppColors.border.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Obx(
            () => CustomButton(
              text: 'Submit Request',
              icon: Icons.send,
              onPressed: storeController.isLoading.value || _selectedItems.isEmpty
                  ? null
                  : _submitRequest,
              isLoading: storeController.isLoading.value,
            ),
          ),
        ),
      ],
    );
  }
}
