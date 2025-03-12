
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  Position? _currentPosition;
  GoogleMapController? _googleMapController;
  StreamSubscription<Position>? _positionStreamSubscription;
  Set <Marker> _markers = {};
  Set <Polyline> _polyline  = {};
  List<LatLng> _polylinePoints = [];

  Future<void> _getCurrentLocation() async {
    if (await _checkPermission()) {
      if (await _isGpsEnabled()) {
        try {
          Position position = await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );

          setState(() {
            _currentPosition = position;

            // Add first position to the polyline points list
            _polylinePoints.add(LatLng(position.latitude, position.longitude));

            // Update the polyline
            if (_polylinePoints.length >= 2) {
              final polyline = Polyline(
                polylineId: PolylineId('route_polyline'),
                points: _polylinePoints,
                color: Colors.blue,
                width: 5,
              );
              _polyline = {polyline};
            }

            // Add marker for the current location
            _markers.removeWhere((marker) => marker.markerId.value == 'currentLocation');
            _markers.add(
              Marker(
                markerId: MarkerId('currentLocation'),
                position: LatLng(position.latitude, position.longitude),
                infoWindow: InfoWindow(
                    title: 'My Location',
                    snippet: '${position.latitude} ${position.longitude}'
                ),

                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              ),
            );
          });

          if (_googleMapController != null) {
            _googleMapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(position.latitude, position.longitude),
                  zoom: 13,
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint("Error getting current location: $e");
        }
      } else {
        await _requestGpsEnable();
      }
    } else {
      await _requestPermission();
    }
  }



  Future<void> _listenCurrentLocation() async {
    if (await _checkPermission()) {
      if (await _isGpsEnabled()) {

        _positionStreamSubscription = Geolocator.getPositionStream(
            locationSettings: AndroidSettings(
                accuracy: LocationAccuracy.best,
                timeLimit: Duration(seconds: 1),
              forceLocationManager: true,
            )
        ).listen(
                (position) {
              setState(() {
                _currentPosition = position;
                print(position);
              });
              if (_googleMapController != null) {
                _googleMapController!.animateCamera(
                    CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude))
                );
              }
            },
            onError: (e) {
              debugPrint("Error in position stream: $e");
            }
        );
      } else {
        await _requestGpsEnable();
      }
    } else {
      await _requestPermission();
    }
  }




  Future<bool> _checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<bool> _requestPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    // Fixed logical operator (was using && instead of ||)
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<bool> _isGpsEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<void> _requestGpsEnable() async {
    await Geolocator.openLocationSettings();
  }




  void _addMarkerOnClick (LatLng positon) {
    final markerId = MarkerId('marker_${DateTime.now().microsecondsSinceEpoch}');

    final marker = Marker(markerId: markerId ,
        position: positon,
    infoWindow: InfoWindow(
        title: 'Selected Location',
      snippet: '${positon.latitude} ${positon.longitude}'
    )
    );
    setState(() {
      _markers.add(marker);
      print(positon);
    });
  }

  void _addPolylineOnClick(LatLng position) {
    // Add new point to the polyline points list
    setState(() {
      _polylinePoints.add(position);

      // Only create a polyline if we have at least 2 points
      if (_polylinePoints.length >= 2) {
        final polylineId = PolylineId('route_polyline');

        final polyline = Polyline(
          polylineId: polylineId,
          points: _polylinePoints,
          color: Colors.blue,
          width: 5,
        );
        _polyline = {
          polyline
        };
        _addMarkerOnClick(position);
      }
    });
  }



  @override
  void initState() {
    super.initState();
    _listenCurrentLocation();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _googleMapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GoogleMap App'),
      ),
      body: _currentPosition == null
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10), // Adds spacing between widgets
            Text(
              'Click On Location Button',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      )
          : GoogleMap(
        initialCameraPosition: CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
        onMapCreated: (GoogleMapController controller) {
          _googleMapController = controller;
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        markers: _markers ,
        polylines: _polyline,
        onTap: (LatLng position) {
          // Call both functions with the same position
          _addMarkerOnClick(position);
          _addPolylineOnClick(position);
        },

      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _getCurrentLocation();
          setState(() {
            _markers = _markers.where((marker) => marker.markerId.value == 'currentLocation').toSet();
            _polylinePoints = [];
            _polyline = {};
          });
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}


