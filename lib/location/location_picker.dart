import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:livraisonb2b/services/location_service.dart';

class LocationPicker extends StatefulWidget {
  final Function(Map<String, dynamic>) onLocationSelected;
  final String? initialAddress;
  final GeoPoint? initialLocation;

  const LocationPicker({
    Key? key,
    required this.onLocationSelected,
    this.initialAddress,
    this.initialLocation,
  }) : super(key: key);

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  LatLng? _selectedLocation;
  String? _address;
  bool _isLoading = false;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.initialAddress ?? '';

    if (widget.initialLocation != null) {
      _selectedLocation = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      // Vérification des services et permissions
      if (!await LocationService.isLocationServiceEnabled()) {
        throw Exception('Activez les services de localisation');
      }

      final permission = await LocationService.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Permissions de localisation requises');
      }

      // Récupération de la position
      final position = await LocationService.getCurrentPosition();
      final address = await LocationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _address = address;
        _addressController.text = address;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchAddress() async {
    if (_addressController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final location = await LocationService.getCoordinatesFromAddress(
        _addressController.text,
      );

      if (location != null) {
        setState(() {
          _selectedLocation = LatLng(location.latitude, location.longitude);
          _address = _addressController.text;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adresse introuvable: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Bouton de localisation actuelle
          ElevatedButton.icon(
            icon:
                _isLoading
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.my_location),
            label: const Text('Ma position actuelle'),
            onPressed: _isLoading ? null : _getCurrentLocation,
          ),

          const SizedBox(height: 20),

          // Champ de recherche d'adresse
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Adresse',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _searchAddress,
              ),
            ),
            onSubmitted: (_) => _searchAddress(),
          ),

          const SizedBox(height: 20),

          // Carte interactive
          if (_selectedLocation != null)
            SizedBox(
              height: 300,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _selectedLocation!,
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('selected'),
                    position: _selectedLocation!,
                  ),
                },
                onTap: (LatLng pos) async {
                  setState(() => _selectedLocation = pos);
                  _address = await LocationService.getAddressFromCoordinates(
                    pos.latitude,
                    pos.longitude,
                  );
                  _addressController.text = _address!;
                },
              ),
            ),

          const SizedBox(height: 20),

          // Notes
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes (optionnel)'),
            maxLines: 3,
          ),

          const SizedBox(height: 20),

          // Bouton de confirmation
          ElevatedButton(
            onPressed: () async {
              if (_addressController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez saisir une adresse')),
                );
                return;
              }

              // Créer le GeoPoint
              GeoPoint? geoPoint;
              if (_selectedLocation != null) {
                geoPoint = GeoPoint(
                  _selectedLocation!.latitude,
                  _selectedLocation!.longitude,
                );
              }

              // Appeler le callback
              widget.onLocationSelected({
                'address': _addressController.text,
                'location': geoPoint, // GeoPoint directement
                'notes': _notesController.text,
              });

              // Fermer avec les données
              Navigator.of(context).pop({
                'address': _addressController.text,
                'location': geoPoint,
                'notes': _notesController.text,
              });
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
