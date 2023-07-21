import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_google_map/directions_model.dart';
import 'package:flutter_google_map/directions_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  late GoogleMapController _controller;
  Set<Marker> markers = {};
  late Marker _origin;
  late Marker _destination;
  late Directions _info;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void dispose() {
    // TODO: implement dispose
    _controller.dispose();
    super.dispose();
  }
  // static const CameraPosition _kLake = CameraPosition(
  //     bearing: 192.8334901395799,
  //     target: LatLng(37.43296265331129, -122.08832357078792),
  //     tilt: 59.440717697143555,
  //     zoom: 19.151926040649414);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   centerTitle: false,
      //   title: const Text('Google Maps'),
      //   actions: [
      //     if (_origin != null)
      //       TextButton(
      //         onPressed: () => _controller.animateCamera(
      //           CameraUpdate.newCameraPosition(
      //             CameraPosition(
      //               target: _origin.position,
      //               zoom: 14.5,
      //               tilt: 50.0,
      //             ),
      //           ),
      //         ),
      //         style: TextButton.styleFrom(
      //           primary: Colors.green,
      //           textStyle: const TextStyle(fontWeight: FontWeight.w600),
      //         ),
      //         child: const Text('ORIGIN'),
      //       ),
      //     if (_destination != null)
      //       TextButton(
      //         onPressed: () => _controller.animateCamera(
      //           CameraUpdate.newCameraPosition(
      //             CameraPosition(
      //               target: _destination.position,
      //               zoom: 14.5,
      //               tilt: 50.0,
      //             ),
      //           ),
      //         ),
      //         style: TextButton.styleFrom(
      //           primary: Colors.blue,
      //           textStyle: const TextStyle(fontWeight: FontWeight.w600),
      //         ),
      //         child: const Text('DEST'),
      //       )
      //   ],
      // ),
      body: Stack(children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: _kGooglePlex,
          markers: markers,
          onMapCreated: (GoogleMapController controller) {
            _controller = controller;
          },
          polylines: {
            if (_info != null)
              Polyline(
                polylineId: const PolylineId('overview_polyline'),
                color: Colors.red,
                width: 5,
                points: _info.polylinePoints
                    .map((e) => LatLng(e.latitude, e.longitude))
                    .toList(),
              ),
          },
          onLongPress: _addMarker,
        ),
        if (_info != null)
          Positioned(
            top: 20.0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 6.0,
                horizontal: 12.0,
              ),
              decoration: BoxDecoration(
                color: Colors.yellowAccent,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 6.0,
                  )
                ],
              ),
              child: Text(
                '${_info.totalDistance}, ${_info.totalDuration}',
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          Position position = await _currentPosition();
          _controller.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(position.latitude, position.longitude),
                  zoom: 15)));

          markers.add(Marker(
            markerId: const MarkerId("currentPosition"),
            position: LatLng(position.latitude, position.longitude),
          ));
        },
        label: const Text("Current location"),
        icon: const Icon(Icons.location_searching),
      ),
    );
  }

  Future<Position> _currentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error("Service disable");
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error("It's always denied");
    }

    Position position = await Geolocator.getCurrentPosition();

    return position;
  }

  void _addMarker(LatLng pos) async {
    if (_origin == null || (_origin != null && _destination != null)) {
      // Origin is not set OR Origin/Destination are both set
      // Set origin
      setState(() {
        _origin = Marker(
          markerId: const MarkerId('origin'),
          infoWindow: const InfoWindow(title: 'Origin'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          position: pos,
        );
        markers.add(_origin);
        // Reset destination
        _destination = null;

        // Reset info
        _info = null;
      });
    } else {
      setState(() {
        _destination = Marker(
          markerId: const MarkerId('destination'),
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          position: pos,
        );
        markers.add(_destination);
      });

      // Get directions
      final directions = await DirectionsRepository()
          .getDirections(origin: _origin.position, destination: pos);
      setState(() => _info = directions);
    }

    Future<void> _goToTheLake() async {
      final GoogleMapController controller = await _controller.future;
      await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
    }
  }
}
