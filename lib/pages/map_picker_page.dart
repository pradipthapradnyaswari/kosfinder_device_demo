
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/device_location_service.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final DeviceLocationService _location = DeviceLocationService();

  LatLng? _selectedPoint;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final position = await _location.getPosition();

      if (!mounted) return;

      setState(() {
        _selectedPoint = LatLng(
          position.latitude,
          position.longitude,
        );
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _loading = false;
      });
    }
  }

  void _confirmLocation() {
    if (_selectedPoint == null) return;

    Navigator.pop(context, _selectedPoint);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi pada Peta'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_off,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadLocation,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: _selectedPoint!,
                          initialZoom: 16,
                          onTap: (tapPosition, point) {
                            setState(() {
                              _selectedPoint = point;
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.example.kosfinder_device_demo',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedPoint!,
                                width: 50,
                                height: 50,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 45,
                                ),
                              ),
                            ],
                          ),
                          RichAttributionWidget(
                            attributions: [
                              TextSourceAttribution(
                                'OpenStreetMap contributors',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Geser atau ketuk peta untuk '
                            'memindahkan marker.',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lat: ${_selectedPoint!.latitude.toStringAsFixed(6)}\n'
                            'Lng: ${_selectedPoint!.longitude.toStringAsFixed(6)}',
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _confirmLocation,
                            icon: const Icon(Icons.check),
                            label: const Text('Konfirmasi Lokasi'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
