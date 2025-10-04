import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/maps_service.dart';

class LocationPickerWidget extends StatefulWidget {
  final Position? initialPosition;
  final Function(Position) onLocationSelected;
  final String? initialAddress;

  const LocationPickerWidget({
    Key? key,
    this.initialPosition,
    required this.onLocationSelected,
    this.initialAddress,
  }) : super(key: key);

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  String? _selectedAddress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _selectedPosition = LatLng(
        widget.initialPosition!.latitude,
        widget.initialPosition!.longitude,
      );
      _selectedAddress = widget.initialAddress;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTapped(LatLng position) async {
    setState(() {
      _isLoading = true;
      _selectedPosition = position;
    });

    try {
      // Convertir la position en adresse
      final address = await MapsService.getAddressFromPosition(
        Position(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        ),
      );

      setState(() {
        _selectedAddress = address;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la récupération de l\'adresse: $e'),
        ),
      );
    }
  }

  void _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final position = await MapsService.getCurrentPosition();
      if (position != null) {
        final latLng = LatLng(position.latitude, position.longitude);
        setState(() {
          _selectedPosition = latLng;
        });

        // Animer la caméra vers la position
        _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));

        // Obtenir l'adresse
        final address = await MapsService.getAddressFromPosition(position);
        setState(() {
          _selectedAddress = address;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'obtenir votre position')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  void _confirmLocation() {
    if (_selectedPosition != null) {
      final position = Position(
        latitude: _selectedPosition!.latitude,
        longitude: _selectedPosition!.longitude,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
      widget.onLocationSelected(position);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner la localisation'),
        backgroundColor: const Color(0xFF1CBF3F),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedPosition != null)
            TextButton(
              onPressed: _confirmLocation,
              child: const Text(
                'Confirmer',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target:
                  _selectedPosition ??
                  const LatLng(5.3600, -4.0083), // Abidjan par défaut
              zoom: 15.0,
            ),
            onTap: _onMapTapped,
            markers:
                _selectedPosition != null
                    ? {
                      Marker(
                        markerId: const MarkerId('selected_location'),
                        position: _selectedPosition!,
                        infoWindow: InfoWindow(
                          title: 'Position sélectionnée',
                          snippet: _selectedAddress,
                        ),
                      ),
                    }
                    : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              backgroundColor: const Color(0xFF1CBF3F),
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          if (_selectedAddress != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adresse sélectionnée:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedAddress!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
