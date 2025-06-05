// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_maps_webservice/places.dart' hide TravelMode;

// class MapPage extends StatefulWidget {
//   final double latitude;
//   final double longitude;
//   final String serviceName;
//   final String address;

//   const MapPage(
//       {super.key,
//       required this.latitude,
//       required this.longitude,
//       required this.serviceName,
//       required this.address});

//   @override
//   State<MapPage> createState() => _MapPageState();
// }

// class _MapPageState extends State<MapPage> {
//   GoogleMapController? mapController;
//   LatLng _currentPosition = const LatLng(18.520430, 73.856743); // Default: Pune
//   LatLng? _destination;
//   LatLng? _providerLocation;
//   double? _distance;
//   final Set<Polyline> _polylines = {};
//   final List<LatLng> _polylineCoordinates = [];
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final TextEditingController _searchController = TextEditingController();
//   final places =
//       GoogleMapsPlaces(apiKey: 'AIzaSyDrX1E6fyKxDLrZAywYgga5XxMBtmeXufs');

//   @override
//   void initState() {
//     super.initState();
//     _getUserLocation();
//     _fetchLocationsFromFirestore();
//   }

//   Future<void> _getUserLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) return;

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.deniedForever) return;
//     }

//     Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);
//     setState(
//         () => _currentPosition = LatLng(position.latitude, position.longitude));
//   }

//   Future<void> _fetchLocationsFromFirestore() async {
//     try {
//       var snapshot = await FirebaseFirestore.instance
//           .collection('request')
//           .where('providerPhoneNumber',
//               isEqualTo: _auth.currentUser?.phoneNumber?.replaceAll('+91', ''))
//           .get();

//       if (snapshot.docs.isNotEmpty) {
//         var data = snapshot.docs.first.data();
//         setState(() {
//           _providerLocation = LatLng(widget.latitude, widget.longitude);
//           _destination = LatLng(data['latitude'], data['longitude']);
//           _calculateDistance();
//           _drawRoute();
//         });
//         mapController?.animateCamera(CameraUpdate.newLatLng(_destination!));
//       }
//     } catch (e) {
//       print('Error fetching destination: $e');
//     }
//   }

//   void _calculateDistance() {
//     if (_destination == null || _providerLocation == null) return;

//     const double radius = 6371; // Earth's radius in km
//     double dlat = (_destination!.latitude - _providerLocation!.latitude) *
//         (math.pi / 180);
//     double dlon = (_destination!.longitude - _providerLocation!.longitude) *
//         (math.pi / 180);

//     double a = math.pow(math.sin(dlat / 2), 2) +
//         math.cos(_providerLocation!.latitude * (math.pi / 180)) *
//             math.cos(_destination!.latitude * (math.pi / 180)) *
//             math.pow(math.sin(dlon / 2), 2);
//     double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

//     setState(() => _distance = radius * c);
//   }

//   Future<void> _drawRoute() async {
//     if (_destination == null || _providerLocation == null) return;

//     PolylinePoints polylinePoints = PolylinePoints();
//     PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
//       'AIzaSyDrX1E6fyKxDLrZAywYgga5XxMBtmeXufs',
//       PointLatLng(_providerLocation!.latitude, _providerLocation!.longitude),
//       PointLatLng(_destination!.latitude, _destination!.longitude),
//       travelMode: TravelMode.driving,
//     );

//     if (result.status == 'OK' && result.points.isNotEmpty) {
//       setState(() {
//         _polylineCoordinates.clear();
//         _polylines.clear();
//         _polylineCoordinates.addAll(result.points
//             .map((point) => LatLng(point.latitude, point.longitude)));
//         _polylines.add(Polyline(
//           polylineId: const PolylineId('route'),
//           points: _polylineCoordinates,
//           color: Colors.blue,
//           width: 5,
//         ));
//       });
//     } else {
//       print('Error fetching route: ${result.errorMessage}');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Provider & Customer Route')),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: _searchController,
//               decoration: const InputDecoration(
//                 labelText: 'Search for a place',
//                 suffixIcon: Icon(Icons.search),
//               ),
//             ),
//           ),
//           Expanded(
//             child: GoogleMap(
//               initialCameraPosition:
//                   CameraPosition(target: _currentPosition, zoom: 13),
//               markers: {
//                 Marker(
//                     markerId: const MarkerId('provider'),
//                     position: _providerLocation ?? _currentPosition,
//                     icon: BitmapDescriptor.defaultMarkerWithHue(
//                         BitmapDescriptor.hueBlue)),
//                 if (_destination != null)
//                   Marker(
//                       markerId: const MarkerId('customer'),
//                       position: _destination!,
//                       icon: BitmapDescriptor.defaultMarkerWithHue(
//                           BitmapDescriptor.hueRed)),
//               },
//               polylines: _polylines,
//               onMapCreated: (controller) => mapController = controller,
//             ),
//           ),
//           if (_distance != null)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Text('Distance: ${_distance!.toStringAsFixed(2)} km'),
//             ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_webservice/places.dart' hide TravelMode;

class MapPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String serviceName;
  final String address;

  const MapPage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.serviceName,
    required this.address,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;
  LatLng _currentPosition = const LatLng(18.520430, 73.856743); // Default: Pune
  LatLng? _destination;
  LatLng? _providerLocation;
  double? _distance;
  final Set<Polyline> _polylines = {};
  final List<LatLng> _polylineCoordinates = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  final places =
      GoogleMapsPlaces(apiKey: 'AIzaSyDrX1E6fyKxDLrZAywYgga5XxMBtmeXufs');

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _fetchLocationsFromFirestore();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(
        () => _currentPosition = LatLng(position.latitude, position.longitude));
  }

  Future<void> _fetchLocationsFromFirestore() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('request')
          .where('providerPhoneNumber',
              isEqualTo: _auth.currentUser?.phoneNumber?.replaceAll('+91', ''))
          .get();

      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data();
        print('Fetched data: $data');

        setState(() {
          _providerLocation = LatLng(widget.latitude, widget.longitude);
          _destination = LatLng(data['latitude'], data['longitude']);
        });
        _calculateDistance();
        _drawRoute();
      } else {
        print('No customer data found.');
      }
    } catch (e) {
      print('Error fetching destination: $e');
    }
  }

  void _calculateDistance() {
    if (_destination == null || _providerLocation == null) return;

    const double radius = 6371; // Earth's radius in km
    double dlat = (_destination!.latitude - _providerLocation!.latitude) *
        (math.pi / 180);
    double dlon = (_destination!.longitude - _providerLocation!.longitude) *
        (math.pi / 180);

    double a = math.pow(math.sin(dlat / 2), 2) +
        math.cos(_providerLocation!.latitude * (math.pi / 180)) *
            math.cos(_destination!.latitude * (math.pi / 180)) *
            math.pow(math.sin(dlon / 2), 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    setState(() => _distance = radius * c);
  }

  Future<void> _drawRoute() async {
    if (_destination == null || _providerLocation == null) return;

    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyDrX1E6fyKxDLrZAywYgga5XxMBtmeXufs',
      PointLatLng(_providerLocation!.latitude, _providerLocation!.longitude),
      PointLatLng(_destination!.latitude, _destination!.longitude),
      travelMode: TravelMode.driving,
    );

    if (result.status == 'OK' && result.points.isNotEmpty) {
      setState(() {
        _polylineCoordinates.clear();
        _polylines.clear();
        _polylineCoordinates.addAll(result.points
            .map((point) => LatLng(point.latitude, point.longitude)));
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: _polylineCoordinates,
          color: Colors.blue,
          width: 5,
        ));
      });
    } else {
      print('Error fetching route: ${result.errorMessage}');
    }
  }

  Future<void> _performSearch(String query) async {
    try {
      final response = await places.searchByText(query);
      if (response.status == "OK" && response.results.isNotEmpty) {
        final place = response.results.first;
        final location = place.geometry?.location;
        if (location != null) {
          final searchedLocation = LatLng(location.lat, location.lng);
          mapController
              ?.animateCamera(CameraUpdate.newLatLngZoom(searchedLocation, 14));
        }
      }
    } catch (e) {
      print('Error performing search: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider & Customer Route')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for a place',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _performSearch(_searchController.text),
                ),
              ),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _currentPosition, zoom: 13),
              markers: {
                Marker(
                  markerId: const MarkerId('provider'),
                  position: _providerLocation ?? _currentPosition,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                ),
                if (_destination != null)
                  Marker(
                    markerId: const MarkerId('customer'),
                    position: _destination!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed),
                  ),
              },
              polylines: _polylines,
              onMapCreated: (controller) => mapController = controller,
            ),
          ),
          if (_distance != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Distance: ${_distance!.toStringAsFixed(2)} km'),
            ),
        ],
      ),
    );
  }
}
