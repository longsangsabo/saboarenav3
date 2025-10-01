import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class MapViewWidget extends StatefulWidget() {
  final List<Map<String, dynamic>> players;
  final Function(Map<String, dynamic>)? onPlayerTap;

  const MapViewWidget({
    super.key,
    required this.players,
    this.onPlayerTap,
  });

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async() {
    try() {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      _createMarkers();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _createMarkers() {
    final markers = <Marker>{};

    // Add current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Vị trí của bạn',
            snippet: 'Bạn đang ở đây',
          ),
        ),
      );
    }

    // Add player markers
    for (int i = 0; i < widget.players.length; i++) {
      final player = widget.players[i];
      final lat = player["latitude"] as double;
      final lng = player["longitude"] as double;
      final rank = player["rank"] as String;

      markers.add(
        Marker(
          markerId: MarkerId('player_$i'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(_getRankHue(rank)),
          infoWindow: InfoWindow(
            title: player["name"] as String,
            snippet: 'Rank $rank • ${player["distance"]} km',
          ),
          onTap: () {
            if (widget.onPlayerTap != null) {
              widget.onPlayerTap!(player);
            }
          },
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  double _getRankHue(String rank) {
    switch (rank.toUpperCase()) {
      case 'A':
        return BitmapDescriptor.hueYellow; // Gold
      case 'B':
        return BitmapDescriptor.hueViolet; // Silver
      case 'C':
        return BitmapDescriptor.hueOrange; // Bronze
      case 'D':
        return BitmapDescriptor.hueGreen;
      case 'E':
        return BitmapDescriptor.hueBlue;
      case 'F':
        return BitmapDescriptor.hueMagenta;
      case 'G':
        return BitmapDescriptor.hueOrange;
      case 'H':
        return BitmapDescriptor.hueRose;
      case 'I':
        return BitmapDescriptor.hueCyan;
      case 'J':
        return BitmapDescriptor.hueAzure;
      default: // K
        return BitmapDescriptor.hueRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return SizedBox(
        height: 100.h - 20.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
              SizedBox(height: 2.h),
              Text(
                'Đang tải bản đồ...',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_currentPosition == null) {
      return SizedBox(
        height: 100.h - 20.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'location_off',
                color: theme.colorScheme.onSurfaceVariant,
                size: 48,
              ),
              SizedBox(height: 2.h),
              Text(
                'Không thể truy cập vị trí',
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: 1.h),
              Text(
                'Vui lòng bật GPS và cấp quyền truy cập vị trí',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: _getCurrentLocation,
                child: Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 100.h - 20.h,
      child: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 14.0,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        mapToolbarEnabled: false,
        compassEnabled: true,
        buildingsEnabled: true,
        trafficEnabled: false,
        mapType: MapType.normal,
        onTap: (LatLng position) {
          // Handle map tap if needed
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
