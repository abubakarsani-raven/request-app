import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/bottom_sheet_wrapper.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/animations/sheet_animations.dart';
import '../custom_text_field.dart';
import '../map_picker.dart';
import '../catalog_browser.dart';
import '../inventory_browser.dart';
import '../../controllers/request_controller.dart';
import '../../controllers/ict_request_controller.dart';
import '../../controllers/store_request_controller.dart';
import '../../controllers/notification_controller.dart';

/// Bottom sheet for creating requests (vehicle, ICT, store)
class CreateRequestBottomSheet extends StatefulWidget {
  final String type;

  const CreateRequestBottomSheet({
    Key? key,
    required this.type,
  }) : super(key: key);

  /// Helper method to show the bottom sheet
  static Future<void> show(BuildContext context, String type) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateRequestBottomSheet(type: type),
    );
  }

  @override
  State<CreateRequestBottomSheet> createState() => _CreateRequestBottomSheetState();
}

class _CreateRequestBottomSheetState extends State<CreateRequestBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tripDateController = TextEditingController();
  final _tripTimeController = TextEditingController();
  final _returnDateController = TextEditingController();
  final _returnTimeController = TextEditingController();
  final _destinationController = TextEditingController();
  final _purposeController = TextEditingController();
  final _startPointController = TextEditingController();
  final _dropOffController = TextEditingController();
  final _requestController = Get.find<RequestController>();
  final _ictController = Get.find<ICTRequestController>();
  final _storeController = Get.find<StoreRequestController>();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DateTime? _selectedReturnDate;
  TimeOfDay? _selectedReturnTime;
  double? _destinationLatitude;
  double? _destinationLongitude;
  double? _officeLatitude;
  double? _officeLongitude;
  String? _selectedDestinationAddress;
  
  double? _startLatitude;
  double? _startLongitude;
  String? _startAddress;
  
  double? _dropOffLatitude;
  double? _dropOffLongitude;
  String? _dropOffAddress;
  
  List<Map<String, dynamic>> _pickupPoints = [];
  double? _estimatedDistance;
  
  List<Map<String, dynamic>> _selectedItems = [];
  final ValueNotifier<Map<String, dynamic>?> _locationNotifier = ValueNotifier<Map<String, dynamic>?>(null);
  final ValueNotifier<Map<String, dynamic>?> _startLocationNotifier = ValueNotifier<Map<String, dynamic>?>(null);
  final ValueNotifier<Map<String, dynamic>?> _dropOffLocationNotifier = ValueNotifier<Map<String, dynamic>?>(null);
  final List<ValueNotifier<Map<String, dynamic>?>> _pickupLocationNotifiers = [];

  @override
  void initState() {
    super.initState();
    if (widget.type == 'vehicle') {
      _selectedDate = DateTime.now();
      _tripDateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      _selectedReturnDate = DateTime.now();
      _returnDateController.text = DateFormat('yyyy-MM-dd').format(_selectedReturnDate!);
      _initializeOfficeLocation();
    }
  }
  
  Future<void> _initializeOfficeLocation() async {
    setState(() {
      _officeLatitude = 6.5244;
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

  // Date and time selection methods (same as original)
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
        if (_selectedReturnDate == null || _selectedReturnDate!.isBefore(picked)) {
          _selectedReturnDate = picked;
          _returnDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
      SheetHaptics.lightImpact();
    }
  }

  Future<void> _selectReturnDate() async {
    if (_selectedDate == null) {
      CustomToast.warning('Please select trip date first', title: 'Missing Information');
      return;
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedReturnDate ?? _selectedDate!,
      firstDate: _selectedDate!,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedReturnDate) {
      setState(() {
        _selectedReturnDate = picked;
        _returnDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
      SheetHaptics.lightImpact();
    }
  }

  Future<void> _selectTime() async {
    final DateTime now = DateTime.now();
    final DateTime selectedDate = _selectedDate ?? now;
    final bool isToday = selectedDate.year == now.year &&
                         selectedDate.month == now.month &&
                         selectedDate.day == now.day;
    
    TimeOfDay? minTime;
    if (isToday) {
      final DateTime minDateTime = now.add(const Duration(hours: 1));
      minTime = TimeOfDay.fromDateTime(minDateTime);
    } else {
      minTime = const TimeOfDay(hour: 0, minute: 0);
    }
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? minTime,
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _tripTimeController.text = picked.format(context);
      });
      SheetHaptics.lightImpact();
    }
  }

  Future<void> _selectReturnTime() async {
    if (_selectedDate == null || _selectedTime == null) {
      CustomToast.warning('Please select trip date and time first', title: 'Missing Information');
      return;
    }
    final DateTime tripDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final DateTime minReturnDateTime = tripDateTime.add(const Duration(hours: 1));
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedReturnTime ?? TimeOfDay.fromDateTime(minReturnDateTime),
    );
    
    if (picked != null) {
      setState(() {
        _selectedReturnTime = picked;
        _returnTimeController.text = picked.format(context);
      });
      SheetHaptics.lightImpact();
    }
  }

  // Location picker methods (simplified, using existing _showLocationPicker pattern)
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
            ),
            child: Column(
              children: [
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
              Expanded(
                child: MapPicker(
                  initialLatitude: initialLatitude,
                  initialLongitude: initialLongitude,
                  locationNotifier: locationNotifier,
                  onLocationSelected: null,
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Confirm Location',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onPrimary,
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
      setState(() {
        _destinationLatitude = result['latitude'] as double;
        _destinationLongitude = result['longitude'] as double;
        _selectedDestinationAddress = result['address'] as String;
        _destinationController.text = _selectedDestinationAddress!;
      });
      _calculateRouteDistance();
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
        _pickupPoints.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
      });
      _calculateRouteDistance();
    }
  }

  void _removePickupPoint(int index) {
    setState(() {
      _pickupPoints.removeAt(index);
      for (int i = 0; i < _pickupPoints.length; i++) {
        _pickupPoints[i]['order'] = i + 1;
      }
    });
    _calculateRouteDistance();
  }

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
      });
      return;
    }

    double totalDistance = 0.0;
    double lastLat = _startLatitude!;
    double lastLng = _startLongitude!;

    if (_pickupPoints.isNotEmpty) {
      for (var point in _pickupPoints) {
        totalDistance += _calculateDistance(
          lastLat, lastLng,
          point['latitude'] as double,
          point['longitude'] as double,
        );
        lastLat = point['latitude'] as double;
        lastLng = point['longitude'] as double;
      }
    }

    totalDistance += _calculateDistance(
      lastLat, lastLng,
      _destinationLatitude!,
      _destinationLongitude!,
    );

    if (_dropOffLatitude != null && _dropOffLongitude != null) {
      totalDistance += _calculateDistance(
        _destinationLatitude!, _destinationLongitude!,
        _dropOffLatitude!,
        _dropOffLongitude!,
      );
      lastLat = _dropOffLatitude!;
      lastLng = _dropOffLongitude!;
    } else {
      lastLat = _destinationLatitude!;
      lastLng = _destinationLongitude!;
    }

    totalDistance += _calculateDistance(
      lastLat, lastLng,
      _officeLatitude!,
      _officeLongitude!,
    );

    setState(() {
      _estimatedDistance = totalDistance;
    });
  }

  void _onItemsSelected(List<Map<String, dynamic>> items) {
    setState(() {
      _selectedItems = items;
    });
  }

  Future<void> _submitRequest() async {
    SheetHaptics.mediumImpact();
    
    if (widget.type == 'vehicle') {
      if (!_formKey.currentState!.validate()) return;
      if (_destinationLatitude == null || _destinationLongitude == null) {
        CustomToast.warning('Please select a destination on the map', title: 'Missing Information');
        return;
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

      if (_officeLatitude != null && _officeLongitude != null) {
        data['officeLatitude'] = _officeLatitude;
        data['officeLongitude'] = _officeLongitude;
      }

      if (_startLatitude != null && _startLongitude != null &&
          (_startLatitude != _officeLatitude || _startLongitude != _officeLongitude)) {
        data['startLatitude'] = _startLatitude;
        data['startLongitude'] = _startLongitude;
      }

      if (_dropOffLatitude != null && _dropOffLongitude != null) {
        data['dropOffLatitude'] = _dropOffLatitude;
        data['dropOffLongitude'] = _dropOffLongitude;
      }

      if (_pickupPoints.isNotEmpty) {
        data['waypoints'] = _pickupPoints.map((point) => {
          'name': point['name'] as String,
          'latitude': point['latitude'] as double,
          'longitude': point['longitude'] as double,
          'order': point['order'] as int,
        }).toList();
      }

      final success = await _requestController.createVehicleRequest(data);
      if (success) {
        try {
          final notificationController = Get.find<NotificationController>();
          await notificationController.loadNotifications(unreadOnly: false);
          await notificationController.loadUnreadCount();
        } catch (e) {
          print('Error refreshing notifications: $e');
        }
        Navigator.of(context).pop();
        CustomToast.success('Vehicle request created successfully', title: 'Success');
      } else {
        CustomToast.error(
          _requestController.error.value.isNotEmpty
              ? _requestController.error.value
              : 'Failed to create request',
          title: 'Error',
        );
      }
    } else if (widget.type == 'ict') {
      if (_selectedItems.isEmpty) {
        CustomToast.warning('Please select at least one catalog item', title: 'Missing Items');
        return;
      }
      final success = await _ictController.createICTRequest(_selectedItems);
      if (success) {
        try {
          final notificationController = Get.find<NotificationController>();
          await notificationController.loadNotifications(unreadOnly: false);
          await notificationController.loadUnreadCount();
        } catch (e) {
          print('Error refreshing notifications: $e');
        }
        Navigator.of(context).pop();
        CustomToast.success('ICT request created successfully', title: 'Success');
      } else {
        CustomToast.error(
          _ictController.error.value.isNotEmpty
              ? _ictController.error.value
              : 'Failed to create request',
          title: 'Error',
        );
      }
    } else if (widget.type == 'store') {
      if (_selectedItems.isEmpty) {
        CustomToast.warning('Please select at least one inventory item', title: 'Missing Items');
        return;
      }
      final success = await _storeController.createStoreRequest(_selectedItems);
      if (success) {
        try {
          final notificationController = Get.find<NotificationController>();
          await notificationController.loadNotifications(unreadOnly: false);
          await notificationController.loadUnreadCount();
        } catch (e) {
          print('Error refreshing notifications: $e');
        }
        Navigator.of(context).pop();
        CustomToast.success('Store request created successfully', title: 'Success');
      } else {
        CustomToast.error(
          _storeController.error.value.isNotEmpty
              ? _storeController.error.value
              : 'Failed to create request',
          title: 'Error',
        );
      }
    }
  }

  String get _title {
    switch (widget.type) {
      case 'vehicle':
        return 'Create Vehicle Request';
      case 'ict':
        return 'Create ICT Request';
      case 'store':
        return 'Create Store Request';
      default:
        return 'Create Request';
    }
  }

  bool get _isLoading {
    switch (widget.type) {
      case 'vehicle':
        return _requestController.isLoading.value;
      case 'ict':
        return _ictController.isLoading.value;
      case 'store':
        return _storeController.isLoading.value;
      default:
        return false;
    }
  }

  bool get _canSubmit {
    if (widget.type == 'vehicle') {
      return _destinationLatitude != null && _destinationLongitude != null;
    } else {
      return _selectedItems.isNotEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    
    switch (widget.type) {
      case 'vehicle':
        content = _buildVehicleRequestForm();
        break;
      case 'ict':
        content = _buildICTRequestForm();
        break;
      case 'store':
        content = _buildStoreRequestForm();
        break;
      default:
        content = const Center(child: Text('Unknown request type'));
    }

    return FormBottomSheet(
      title: _title,
      submitText: 'Submit Request',
      cancelText: 'Cancel',
      onSubmit: _submitRequest,
      onCancel: () => Navigator.of(context).pop(),
      isLoading: _isLoading,
      isSubmitEnabled: _canSubmit,
      initialChildSize: widget.type == 'vehicle' ? BottomSheetSizes.large : BottomSheetSizes.full,
      child: content,
    );
  }

  Widget _buildVehicleRequestForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Route Planning',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          CustomTextField(
            label: 'Start Point',
            controller: _startPointController,
            prefixIcon: Icons.place,
            readOnly: true,
            hint: 'Office (default)',
            onTap: _showStartPointPicker,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pickup Points',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              TextButton.icon(
                onPressed: () => _showPickupPointPicker(null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Pickup'),
              ),
            ],
          ),
          if (_pickupPoints.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
              child: Text(
                'No pickup points added',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 16,
                      child: Text(
                        '${point['order']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      point['address'] as String,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _showPickupPointPicker(index),
                          color: AppColors.primary,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: () => _removePickupPoint(index),
                          color: AppColors.error,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: AppConstants.spacingM),
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
          CustomTextField(
            label: 'Drop-off Point (Optional)',
            controller: _dropOffController,
            prefixIcon: Icons.flag,
            readOnly: true,
            hint: _dropOffAddress ?? 'Return to office',
            onTap: _showDropOffPicker,
          ),
          if (_estimatedDistance != null) ...[
            const SizedBox(height: AppConstants.spacingM),
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
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  Text(
                    'Total Distance: ${_estimatedDistance!.toStringAsFixed(2)} km',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Trip Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: -0.5,
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
        ],
      ),
    );
  }

  Widget _buildICTRequestForm() {
    return CatalogBrowser(
      onItemsSelected: _onItemsSelected,
      selectedItems: _selectedItems,
    );
  }

  Widget _buildStoreRequestForm() {
    return InventoryBrowser(
      onItemsSelected: _onItemsSelected,
      selectedItems: _selectedItems,
    );
  }
}

