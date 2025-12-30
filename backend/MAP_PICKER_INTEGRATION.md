# Google Maps Destination Picker Integration

## Overview

Users can select a destination point on the map (like Uber/Bolt) when creating a vehicle request. The selected coordinates are stored in the request and used for trip tracking.

## Backend Support

The backend now accepts destination coordinates when creating a vehicle request:

```typescript
POST /vehicles/requests
{
  "tripDate": "2024-01-15",
  "tripTime": "09:00",
  "destination": "123 Main Street", // Address/name
  "purpose": "Official meeting",
  "destinationLatitude": 40.7580,  // From map picker
  "destinationLongitude": -73.9855, // From map picker
  "officeLatitude": 40.7128,        // Optional: office location
  "officeLongitude": -74.0060       // Optional: office location
}
```

## Flutter Implementation

### Required Packages

```yaml
dependencies:
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  google_maps_flutter_platform_interface: ^2.3.0
  geocoding: ^2.1.1  # For reverse geocoding (coordinates to address)
```

### Map Picker Widget

```dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class DestinationPickerMap extends StatefulWidget {
  final Function(LatLng position, String address) onLocationSelected;

  const DestinationPickerMap({
    Key? key,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<DestinationPickerMap> createState() => _DestinationPickerMapState();
}

class _DestinationPickerMapState extends State<DestinationPickerMap> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  LatLng _currentLocation = LatLng(40.7128, -74.0060); // Default (NYC)

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_currentLocation),
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _onMapTap(LatLng location) async {
    setState(() {
      _selectedLocation = location;
    });

    // Reverse geocode to get address
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = _formatAddress(place);
        setState(() {
          _selectedAddress = address;
        });
        widget.onLocationSelected(location, address);
      }
    } catch (e) {
      print('Error geocoding: $e');
      widget.onLocationSelected(location, 'Selected Location');
    }
  }

  String _formatAddress(Placemark place) {
    List<String> parts = [];
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentLocation,
            zoom: 14.0,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          onTap: _onMapTap,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: MapType.normal,
          markers: _selectedLocation != null
              ? {
                  Marker(
                    markerId: MarkerId('destination'),
                    position: _selectedLocation!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed,
                    ),
                    infoWindow: InfoWindow(
                      title: 'Destination',
                      snippet: _selectedAddress ?? 'Selected Location',
                    ),
                  ),
                }
              : {},
        ),
        // Center crosshair indicator
        Center(
          child: Icon(
            Icons.place,
            color: Colors.red,
            size: 48,
          ),
        ),
        // Selected location info card
        if (_selectedLocation != null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Selected Destination',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _selectedAddress ?? 'Loading address...',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
```

### Usage in Request Form

```dart
class CreateVehicleRequestScreen extends StatefulWidget {
  @override
  _CreateVehicleRequestScreenState createState() =>
      _CreateVehicleRequestScreenState();
}

class _CreateVehicleRequestScreenState
    extends State<CreateVehicleRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  LatLng? _destinationLocation;
  String? _destinationAddress;
  DateTime? _tripDate;
  TimeOfDay? _tripTime;
  final _purposeController = TextEditingController();

  void _onDestinationSelected(LatLng location, String address) {
    setState(() {
      _destinationLocation = location;
      _destinationAddress = address;
    });
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a destination on the map')),
      );
      return;
    }

    final requestData = {
      'tripDate': _tripDate!.toIso8601String().split('T')[0],
      'tripTime': '${_tripTime!.hour.toString().padLeft(2, '0')}:${_tripTime!.minute.toString().padLeft(2, '0')}',
      'destination': _destinationAddress,
      'purpose': _purposeController.text,
      'destinationLatitude': _destinationLocation!.latitude,
      'destinationLongitude': _destinationLocation!.longitude,
    };

    // Call API to create request
    // await apiService.post('/vehicles/requests', data: requestData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Vehicle Request')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: DestinationPickerMap(
                onLocationSelected: _onDestinationSelected,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _purposeController,
                    decoration: InputDecoration(
                      labelText: 'Purpose',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter purpose';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitRequest,
                    child: Text('Submit Request'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Enhanced Map Picker with Search

For a better UX (like Uber), you can add a search bar:

```dart
class EnhancedDestinationPicker extends StatefulWidget {
  @override
  State<EnhancedDestinationPicker> createState() =>
      _EnhancedDestinationPickerState();
}

class _EnhancedDestinationPickerState
    extends State<EnhancedDestinationPicker> {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;

  void _searchLocation(String query) async {
    if (query.isEmpty) return;

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        LatLng latLng = LatLng(location.latitude, location.longitude);
        
        setState(() {
          _selectedLocation = latLng;
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 15.0),
        );
      }
    } catch (e) {
      print('Error searching location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          // ... map configuration
        ),
        // Search bar at top
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Card(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search destination...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              onSubmitted: _searchLocation,
            ),
          ),
        ),
      ],
    );
  }
}
```

## Features

1. **Tap to Select**: Users tap anywhere on the map to select destination
2. **Visual Indicator**: Red marker shows selected location
3. **Address Display**: Selected coordinates are reverse geocoded to show address
4. **Current Location**: Map centers on user's current location
5. **Search Integration**: Optional search bar to find locations by name/address

## Backend Storage

The selected destination coordinates are stored in:
- `requestedDestinationLocation`: { latitude, longitude } - The coordinates selected on the map
- `destination`: string - The address/name of the destination

When the trip starts and reaches destination, these coordinates are used for:
- Distance calculation
- Fuel estimation
- Route tracking

## API Integration

When creating a request, include the coordinates:

```dart
final response = await apiService.post('/vehicles/requests', data: {
  'tripDate': '2024-01-15',
  'tripTime': '09:00',
  'destination': selectedAddress,
  'purpose': 'Official meeting',
  'destinationLatitude': selectedLocation.latitude,
  'destinationLongitude': selectedLocation.longitude,
});
```

The backend will store these coordinates and use them for trip tracking calculations.

