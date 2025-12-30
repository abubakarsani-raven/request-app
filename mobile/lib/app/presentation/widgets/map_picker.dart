import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

// Dark map style for Google Maps
const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#242f3e"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#746855"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#242f3e"
      }
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#263c3f"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#6b9a76"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#38414e"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#212a37"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9ca5b3"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#746855"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#1f2835"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#f3d19c"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#2f3948"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#17263c"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#515c6d"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#17263c"
      }
    ]
  }
]
''';

class MapPicker extends StatefulWidget {
  final Function(double latitude, double longitude, String address)? onLocationSelected;
  final double? initialLatitude;
  final double? initialLongitude;
  final ValueNotifier<Map<String, dynamic>?>? locationNotifier;

  const MapPicker({
    Key? key,
    this.onLocationSelected,
    this.initialLatitude,
    this.initialLongitude,
    this.locationNotifier,
  }) : super(key: key);

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = 'Loading location...';
  bool _isLoadingAddress = false;
  bool _isMapMoving = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _showSearchResults = false;
  bool _isSearching = false;
  Timer? _searchDebounce;
  Timer? _addressUpdateDebounce;
  static const String _googlePlacesApiKey = 'AIzaSyD3apWjzMf9iPAdZTSGR4ln2pU7U6Lo7_I';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() {
          _showSearchResults = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _addressUpdateDebounce?.cancel();
    _searchDebounce = null;
    _addressUpdateDebounce = null;
    // Don't dispose map controller - let Flutter handle it
    // _mapController?.dispose(); // This can cause crashes
    _mapController = null;
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      setState(() {
        _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      });
      if (mounted && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation!, 16.0),
        );
      }
      await _getAddressFromCoordinates(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
    } else {
      // Set a default location (Lagos, Nigeria) immediately so map can render
      setState(() {
        _selectedLocation = const LatLng(6.5244, 3.3792); // Lagos, Nigeria
        _selectedAddress = 'Lagos, Nigeria';
      });
      // Then try to get current location
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _selectedAddress = 'Location services disabled. Tap map to select location.';
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _selectedAddress = 'Location permission denied. Tap map to select location.';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _selectedAddress = 'Location permission denied. Tap map to select location.';
          });
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_selectedLocation!, 16.0),
          );
        }

        await _getAddressFromCoordinates(position.latitude, position.longitude);
      }
    } catch (e) {
      // If getting current location fails, keep the default location
      if (mounted) {
        setState(() {
          _selectedAddress = 'Unable to get current location. Tap map to select location.';
        });
      }
      print('Error getting current location: $e');
    }
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    _addressUpdateDebounce?.cancel();
    
    _addressUpdateDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      
    setState(() {
      _isLoadingAddress = true;
    });
      
      // Notify listener that we're loading
      if (widget.locationNotifier != null) {
        widget.locationNotifier!.value = {
          'isLoading': true,
          'hasLocation': false,
        };
      }

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        String address = _formatAddress(place);
        setState(() {
          _selectedAddress = address;
          _isLoadingAddress = false;
          _selectedLocation = LatLng(lat, lng);
        });
        
        // Notify listener if provided
        if (widget.locationNotifier != null) {
          widget.locationNotifier!.value = {
            'lat': lat,
            'lng': lng,
            'address': address,
            'hasLocation': true,
            'isLoading': false,
          };
        }
        
        // Auto-update location callback only if provided
        if (widget.onLocationSelected != null) {
          widget.onLocationSelected!(lat, lng, address);
        }
        } else if (mounted) {
        setState(() {
          _selectedAddress = 'Address not found';
          _isLoadingAddress = false;
        });
          if (widget.locationNotifier != null) {
            widget.locationNotifier!.value = {
              'hasLocation': false,
              'isLoading': false,
            };
          }
      }
    } catch (e) {
        if (mounted) {
      setState(() {
        _selectedAddress = 'Error getting address';
        _isLoadingAddress = false;
      });
          if (widget.locationNotifier != null) {
            widget.locationNotifier!.value = {
              'hasLocation': false,
              'isLoading': false,
            };
          }
        }
      }
    });
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
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }
    return parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
  }

  Future<void> _searchAddress(String query) async {
    _searchDebounce?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        // Use Google Places Autocomplete API for better suggestions
        final autocompleteUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&key=$_googlePlacesApiKey'
          '&components=country:ng', // Restrict to Nigeria, remove if you want global
        );

        final response = await http.get(autocompleteUrl);
        
        if (response.statusCode == 200 && mounted) {
          final data = json.decode(response.body);
          
          if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
            List<Map<String, dynamic>> results = [];
            
            if (data['predictions'] != null) {
              // Get place details for each prediction
              for (var prediction in data['predictions']) {
                final placeId = prediction['place_id'];
                final description = prediction['description'] as String;
                
                // Get place details to get coordinates
                try {
                  final detailsUrl = Uri.parse(
                    'https://maps.googleapis.com/maps/api/place/details/json'
                    '?place_id=$placeId'
                    '&fields=geometry,formatted_address'
                    '&key=$_googlePlacesApiKey',
                  );
                  
                  final detailsResponse = await http.get(detailsUrl);
                  if (detailsResponse.statusCode == 200) {
                    final detailsData = json.decode(detailsResponse.body);
                    if (detailsData['result'] != null) {
                      final geometry = detailsData['result']['geometry'];
                      final location = geometry['location'];
                      final lat = location['lat'] as double;
                      final lng = location['lng'] as double;
                      final formattedAddress = detailsData['result']['formatted_address'] ?? description;
                      
                      results.add({
                        'placeId': placeId,
                        'address': formattedAddress,
                        'description': description,
                        'lat': lat,
                        'lng': lng,
                      });
                    }
                  }
                } catch (e) {
                  // Skip this result if details fetch fails
                  continue;
                }
              }
            }
            
            // Fallback to geocoding if Places API returns no results
            if (results.isEmpty) {
              try {
                List<Location> locations = await locationFromAddress(query);
                for (var location in locations) {
                  try {
                    List<Placemark> placemarks = await placemarkFromCoordinates(
                      location.latitude,
                      location.longitude,
                    );
                    if (placemarks.isNotEmpty) {
                      results.add({
                        'address': _formatAddress(placemarks[0]),
                        'lat': location.latitude,
                        'lng': location.longitude,
                      });
                    } else {
                      results.add({
                        'address': '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                        'lat': location.latitude,
                        'lng': location.longitude,
                      });
                    }
                  } catch (e) {
                    results.add({
                      'address': '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                      'lat': location.latitude,
                      'lng': location.longitude,
                    });
                  }
                }
              } catch (e) {
                // Geocoding also failed
              }
            }
            
            if (mounted) {
              setState(() {
                _searchResults = results;
                _showSearchResults = true;
                _isSearching = false;
              });
            }
          } else {
            // API error, fallback to geocoding
            _fallbackSearch(query);
          }
        } else {
          // HTTP error, fallback to geocoding
          _fallbackSearch(query);
        }
      } catch (e) {
        // Network error, fallback to geocoding
        _fallbackSearch(query);
      }
    });
  }

  Future<void> _fallbackSearch(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (mounted) {
        List<Map<String, dynamic>> results = [];
        for (var location in locations) {
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              location.latitude,
              location.longitude,
            );
            if (placemarks.isNotEmpty) {
              results.add({
                'address': _formatAddress(placemarks[0]),
                'lat': location.latitude,
                'lng': location.longitude,
              });
            } else {
              results.add({
                'address': '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                'lat': location.latitude,
                'lng': location.longitude,
              });
            }
          } catch (e) {
            results.add({
              'address': '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
              'lat': location.latitude,
              'lng': location.longitude,
            });
          }
        }
        
        if (mounted) {
          setState(() {
            _searchResults = results;
            _showSearchResults = true;
            _isSearching = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _showSearchResults = false;
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _moveToFirstResult() async {
    if (_searchResults.isEmpty) return;
    
    final firstResult = _searchResults[0];
    await _selectSearchResult(firstResult);
  }

  Future<void> _selectSearchResult(Map<String, dynamic> result) async {
    final lat = result['lat'] as double;
    final lng = result['lng'] as double;

    setState(() {
      _selectedLocation = LatLng(lat, lng);
      _showSearchResults = false;
      _searchController.clear();
      _searchFocusNode.unfocus();
    });

    if (mounted && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16.0),
      );
    }

    await _getAddressFromCoordinates(lat, lng);
  }

  void _onCameraMove(CameraPosition position) {
    if (!mounted) return;
    setState(() {
      _isMapMoving = true;
      _selectedLocation = position.target;
    });
  }

  void _onCameraIdle() {
    if (!mounted || _selectedLocation == null) return;
    _isMapMoving = false;
    _getAddressFromCoordinates(
      _selectedLocation!.latitude,
      _selectedLocation!.longitude,
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        // Search Bar (Bolt/Chowdeck style)
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Search for a place or address...',
                        hintStyle: TextStyle(
                          color: isDark 
                              ? AppColors.darkTextSecondary 
                              : AppColors.textSecondary,
                        ),
                        prefixIcon: Icon(
                          Icons.search, 
                          color: theme.colorScheme.primary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear, 
                                  size: 20,
                                  color: isDark 
                                      ? AppColors.darkTextSecondary 
                                      : AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchResults = [];
                                    _showSearchResults = false;
                                    _isSearching = false;
                                  });
                                },
                              )
                            : _isSearching
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  )
                                : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark 
                          ? AppColors.darkBorderDefined.withOpacity(0.5)
                          : AppColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark 
                          ? AppColors.darkBorderDefined.withOpacity(0.5)
                          : AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary, 
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: isDark 
                      ? AppColors.darkSurface 
                      : theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: _searchAddress,
                      onTap: () {
                        setState(() {
                          if (_searchResults.isNotEmpty) {
                            _showSearchResults = true;
                          }
                        });
                      },
                      onSubmitted: (value) {
                        // When user presses enter/search, move to first result
                        if (_searchResults.isNotEmpty) {
                          _moveToFirstResult();
                        }
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty && _searchResults.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ElevatedButton.icon(
                        onPressed: _moveToFirstResult,
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Search'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Search Results Dropdown
              if (_showSearchResults && _searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? AppColors.darkSurface 
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark 
                          ? AppColors.darkBorderDefined.withOpacity(0.5)
                          : AppColors.border.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                            ? Colors.black.withOpacity(0.5)
                            : Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          result['address'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark 
                                ? AppColors.darkTextPrimary 
                                : AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectSearchResult(result),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        // Map with Centered Pin (Bolt/Chowdeck style)
        Expanded(
          child: Stack(
            children: [
              _selectedLocation == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation!,
                        zoom: 16.0,
                  ),
                  onMapCreated: (GoogleMapController controller) async {
                        if (mounted) {
                          _mapController = controller;
                          // Apply dark mode style if needed
                          if (isDark) {
                            try {
                              await controller.setMapStyle(_darkMapStyle);
                            } catch (e) {
                              print('Error setting map style: $e');
                            }
                          }
                          // Ensure camera is positioned correctly
                          if (_selectedLocation != null) {
                            controller.animateCamera(
                              CameraUpdate.newLatLngZoom(_selectedLocation!, 16.0),
                            );
                          }
                        }
                      },
                      onCameraMove: _onCameraMove,
                      onCameraIdle: _onCameraIdle,
                      myLocationButtonEnabled: false,
                      myLocationEnabled: true,
                      mapType: MapType.normal,
                      zoomControlsEnabled: true,
                      compassEnabled: false,
                      rotateGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      tiltGesturesEnabled: false,
                      zoomGesturesEnabled: true,
                    ),
              // Centered Pin (Bolt/Chowdeck style) - Always in center
              // Use IgnorePointer to ensure pin doesn't block map gestures
              IgnorePointer(
                ignoring: true,
                child: Center(
                  child: SizedBox(
                    width: 50,
                    height: 70,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pin Head
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark 
                                  ? AppColors.darkSurface 
                                  : theme.colorScheme.surface,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark 
                                    ? Colors.black.withOpacity(0.6)
                                    : Colors.black.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: theme.colorScheme.onPrimary,
                            size: 28,
                          ),
                        ),
                        // Pin Tail
                        CustomPaint(
                          size: const Size(20, 20),
                          painter: _PinTailPainter(theme.colorScheme.primary),
                        ),
                      ],
                          ),
                  ),
                ),
              ),
              // My Location Button
              Positioned(
                bottom: 20,
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: isDark 
                      ? AppColors.darkSurface 
                      : theme.colorScheme.surface,
                  onPressed: _getCurrentLocation,
                  child: Icon(
                    Icons.my_location, 
                    color: theme.colorScheme.primary,
                  ),
                ),
        ),
            ],
          ),
        ),
        // Address Display (Bolt/Chowdeck style)
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          decoration: BoxDecoration(
            color: isDark 
                ? AppColors.darkSurface 
                : theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: isDark 
                    ? AppColors.darkBorderDefined.withOpacity(0.5)
                    : AppColors.border.withOpacity(0.5),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoadingAddress || _isMapMoving)
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      else
                        Text(
                          _selectedAddress,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isDark 
                                ? AppColors.darkTextPrimary 
                                : AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (_selectedLocation != null && !_isLoadingAddress && !_isMapMoving) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark 
                                ? AppColors.darkTextSecondary 
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  }

// Custom painter for pin tail (Bolt/Chowdeck style)
class _PinTailPainter extends CustomPainter {
  final Color color;
  
  _PinTailPainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, size.height);
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
