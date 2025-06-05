// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_maps_webservice/directions.dart';
// import 'package:google_maps_webservice/places.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
// import 'package:google_maps_webservice/directions.dart' as directions;

// class MapPage extends StatefulWidget {
//   final String requestId; // Assuming requestId is passed to this page

//   MapPage({required this.requestId});

//   @override
//   _MapPageState createState() => _MapPageState();
// }

// class _MapPageState extends State<MapPage> {
//   String? serviceCategory;
//   LatLng _currentPosition = const LatLng(18.520430, 73.856743); // Default: Pune
//   LatLng? _destination;
//   GoogleMapController? mapController;
//   Set<Marker> _markers = {}; // Set of markers for the map
//   Set<maps.Polyline> _polylines = {}; // Set of polylines for the route
//   String? distance = '';
//   String? duration = '';

//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleMapsDirections _directionsApi = GoogleMapsDirections(
//       apiKey:
//           'AIzaSyDrX1E6fyKxDLrZAywYgga5XxMBtmeXufs'); // Replace with your API Key

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {});
//     _getUserLocation();
//     _fetchLocationsFromFirestore();
//   }

//   // Fetch the user's current location
//   Future<void> _getUserLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.deniedForever) return;
//     }

//     Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);
//     setState(() {
//       _currentPosition = LatLng(position.latitude, position.longitude);
//       _markers.add(Marker(
//         markerId: MarkerId('current_location'),
//         position: _currentPosition,
//         infoWindow: InfoWindow(title: 'Current Location'),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//       ));
//     });
//     _updateProviderLocationInFirestore();
//   }

//   // Update provider location in Firestore
//   Future<void> _updateProviderLocationInFirestore() async {
//     final phoneNumber = _auth.currentUser?.phoneNumber?.replaceFirst('+91', '');
//     if (phoneNumber != null) {
//       await FirebaseFirestore.instance
//           .collection('provider')
//           .doc(phoneNumber)
//           .update({
//         'latitude': _currentPosition.latitude,
//         'longitude': _currentPosition.longitude,
//       });
//     }
//   }

//   // Fetch locations from Firestore (request location)
//   Future<void> _fetchLocationsFromFirestore() async {
//     try {
//       var snapshot = await FirebaseFirestore.instance
//           .collection('requests')
//           .doc(widget.requestId)
//           .get();
//       if (snapshot.exists) {
//         var data = snapshot.data();
//         _destination = LatLng(data!['latitude'], data['longitude']);
//         _calculateDistance();
//       }
//     } catch (e) {
//       print("Error fetching location: $e");
//     }
//   }

//   // Calculate the route and distance
//   void _calculateDistance() async {
//     if (_destination != null) {
//       try {
//         // Instantiate Location objects with required lat and lng parameters
//         Location _currentLocation = Location(
//             lat: _currentPosition.latitude, lng: _currentPosition.longitude);
//         Location _destinationLocation =
//             Location(lat: _destination!.latitude, lng: _destination!.longitude);

//         // Calculate the distance and duration using Directions API
//         final response = await _directionsApi.directions(
//           _currentLocation,
//           _destinationLocation,
//           travelMode:
//               TravelMode.driving, // You can adjust this to walking or biking
//         );

//         if (response.isOkay) {
//           final legs = response.routes[0].legs[0];

//           // Update distance and duration in the state
//           setState(() {
//             distance = legs.distance.text;
//             duration = legs.duration.text;
//           });

//           // Add destination marker to the map
//           setState(() {
//             _markers.add(Marker(
//               markerId: MarkerId('destination'),
//               position: _destination!,
//               infoWindow: InfoWindow(title: 'Destination'),
//               icon: BitmapDescriptor.defaultMarkerWithHue(
//                   BitmapDescriptor.hueRed),
//             ));

//             // Decode the polyline points and create a polyline on the map
//             _polylines.add(maps.Polyline(
//               polylineId: PolylineId('route'),
//               points:
//                   _decodePolyline(response.routes[0].overviewPolyline.points),
//               color: Colors.blue,
//               width: 5,
//             ));
//           });
//         } else {
//           print("Error: ${response.errorMessage}");
//         }
//       } catch (e) {
//         print("Error fetching route: $e");
//       }
//     }
//   }

//   // Function to decode the polyline points from Directions API
//   List<LatLng> _decodePolyline(String encodedPolyline) {
//     List<LatLng> polylinePoints = [];
//     int index = 0;
//     int len = encodedPolyline.length;
//     int lat = 0;
//     int lng = 0;

//     while (index < len) {
//       int b;
//       int shift = 0;
//       int result = 0;
//       do {
//         b = encodedPolyline.codeUnitAt(index) - 63;
//         index++;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);

//       int dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
//       lat += dLat;

//       shift = 0;
//       result = 0;
//       do {
//         b = encodedPolyline.codeUnitAt(index) - 63;
//         index++;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);

//       int dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
//       lng += dLng;

//       polylinePoints.add(LatLng(lat / 1E5, lng / 1E5));
//     }
//     return polylinePoints;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Map View')),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition:
//                 CameraPosition(target: _currentPosition, zoom: 14.0),
//             markers: _markers,
//             polylines: _polylines, // Add the polylines to the map
//             onMapCreated: (controller) {
//               mapController = controller;
//             },
//           ),
//           Positioned(
//             bottom: 20,
//             left: 10,
//             right: 10,
//             child: Card(
//               elevation: 5,
//               child: Padding(
//                 padding: const EdgeInsets.all(10.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Distance: $distance', style: TextStyle(fontSize: 16)),
//                     Text('Duration: $duration', style: TextStyle(fontSize: 16)),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_maps_webservice/directions.dart';
// import 'package:google_maps_webservice/places.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
// import 'package:google_maps_webservice/directions.dart' as directions;

// class MapPage extends StatefulWidget {
//   final String requestId;

//   MapPage({required this.requestId});

//   @override
//   _MapPageState createState() => _MapPageState();
// }

// class _MapPageState extends State<MapPage> {
//   String? serviceCategory;
//   LatLng _currentPosition = const LatLng(18.520430, 73.856743); // Default: Pune
//   LatLng? _destination;
//   GoogleMapController? mapController;
//   Set<Marker> _markers = {}; // Set of markers for the map
//   Set<maps.Polyline> _polylines = {}; // Set of polylines for the route
//   String? distance = '';
//   String? duration = '';

//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleMapsDirections _directionsApi = GoogleMapsDirections(
//       apiKey:
//           'AIzaSyDrX1E6fyKxDLrZAywYgga5XxMBtmeXufs'); // Replace with your API Key

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {});
//     _getUserLocation();
//     _fetchLocationsFromFirestore();
//   }

//   // Fetch the user's current location
//   Future<void> _getUserLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.deniedForever) return;
//     }

//     Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);
//     setState(() {
//       _currentPosition = LatLng(position.latitude, position.longitude);
//       _markers.add(Marker(
//         markerId: MarkerId('current_location'),
//         position: _currentPosition,
//         infoWindow: InfoWindow(title: 'Current Location'),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//       ));
//       // Update the map camera position
//       mapController?.animateCamera(
//         CameraUpdate.newLatLngZoom(_currentPosition, 14.0),
//       );
//     });
//     _updateProviderLocationInFirestore();
//   }

//   // Update provider location in Firestore
//   Future<void> _updateProviderLocationInFirestore() async {
//     final phoneNumber = _auth.currentUser?.phoneNumber?.replaceFirst('+91', '');
//     if (phoneNumber != null) {
//       await FirebaseFirestore.instance
//           .collection('provider')
//           .doc(phoneNumber)
//           .update({
//         'latitude': _currentPosition.latitude,
//         'longitude': _currentPosition.longitude,
//       });
//     }
//   }

//   // Fetch locations from Firestore (request location)
//   Future<void> _fetchLocationsFromFirestore() async {
//     try {
//       var snapshot = await FirebaseFirestore.instance
//           .collection('requests')
//           .doc(widget.requestId)
//           .get();
//       if (snapshot.exists) {
//         var data = snapshot.data();
//         _destination = LatLng(data!['latitude'], data['longitude']);
//         _calculateDistance();
//       }
//     } catch (e) {
//       print("Error fetching location: $e");
//     }
//   }

//   // Calculate the route and distance
//   void _calculateDistance() async {
//     if (_destination != null) {
//       try {
//         // Instantiate Location objects with required lat and lng parameters
//         Location _currentLocation = Location(
//             lat: _currentPosition.latitude, lng: _currentPosition.longitude);
//         Location _destinationLocation =
//             Location(lat: _destination!.latitude, lng: _destination!.longitude);

//         // Calculate the distance and duration using Directions API
//         final response = await _directionsApi.directions(
//           _currentLocation,
//           _destinationLocation,
//           travelMode:
//               TravelMode.driving, // You can adjust this to walking or biking
//         );

//         if (response.isOkay) {
//           final legs = response.routes[0].legs[0];

//           // Update distance and duration in the state
//           setState(() {
//             distance = legs.distance.text;
//             duration = legs.duration.text;
//           });

//           // Add destination marker to the map
//           setState(() {
//             _markers.add(Marker(
//               markerId: MarkerId('destination'),
//               position: _destination!,
//               infoWindow: InfoWindow(title: 'Destination'),
//               icon: BitmapDescriptor.defaultMarkerWithHue(
//                   BitmapDescriptor.hueRed),
//             ));

//             // Decode the polyline points and create a polyline on the map
//             _polylines.add(maps.Polyline(
//               polylineId: PolylineId('route'),
//               points:
//                   _decodePolyline(response.routes[0].overviewPolyline.points),
//               color: Colors.blue,
//               width: 5,
//             ));
//           });
//         } else {
//           print("Error: ${response.errorMessage}");
//         }
//       } catch (e) {
//         print("Error fetching route: $e");
//       }
//     }
//   }

//   // Function to decode the polyline points from Directions API
//   List<LatLng> _decodePolyline(String encodedPolyline) {
//     List<LatLng> polylinePoints = [];
//     int index = 0;
//     int len = encodedPolyline.length;
//     int lat = 0;
//     int lng = 0;

//     while (index < len) {
//       int b;
//       int shift = 0;
//       int result = 0;
//       do {
//         b = encodedPolyline.codeUnitAt(index) - 63;
//         index++;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);

//       int dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
//       lat += dLat;

//       shift = 0;
//       result = 0;
//       do {
//         b = encodedPolyline.codeUnitAt(index) - 63;
//         index++;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);

//       int dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
//       lng += dLng;

//       polylinePoints.add(LatLng(lat / 1E5, lng / 1E5));
//     }
//     return polylinePoints;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Map View')),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition:
//                 CameraPosition(target: _currentPosition, zoom: 14.0),
//             markers: _markers,
//             polylines: _polylines, // Add the polylines to the map
//             onMapCreated: (controller) {
//               mapController = controller;
//             },
//           ),
//           Positioned(
//             bottom: 20,
//             left: 10,
//             right: 10,
//             child: Card(
//               elevation: 5,
//               child: Padding(
//                 padding: const EdgeInsets.all(10.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Distance: $distance', style: TextStyle(fontSize: 16)),
//                     Text('Duration: $duration', style: TextStyle(fontSize: 16)),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_maps_webservice/directions.dart';
// import 'package:google_maps_webservice/places.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
// import 'package:google_maps_webservice/directions.dart' as directions;

// class MapPage extends StatefulWidget {
//   final String requestId;

//   MapPage({required this.requestId});

//   @override
//   _MapPageState createState() => _MapPageState();
// }

// class _MapPageState extends State<MapPage> {
//   LatLng? _currentPosition;
//   LatLng? _destination;
//   GoogleMapController? mapController;
//   Set<Marker> _markers = {}; // Set of markers for the map
//   Set<maps.Polyline> _polylines = {}; // Set of polylines for the route
//   String? distance = '';
//   String? duration = '';

//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleMapsDirections _directionsApi = GoogleMapsDirections(
//       apiKey:
//           'AIzaSyDrX1E6fyKxDLrZAywYgga5XxMBtmeXufs'); // Replace with your API Key

//   @override
//   void initState() {
//     super.initState();
//     _getUserLocation();
//     _fetchLocationsFromFirestore();
//   }

//   // Fetch the user's current location
//   Future<void> _getUserLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.deniedForever) return;
//     }

//     Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);
//     setState(() {
//       _currentPosition = LatLng(position.latitude, position.longitude);
//       _markers.add(Marker(
//         markerId: MarkerId('current_location'),
//         position: _currentPosition!,
//         infoWindow: InfoWindow(title: 'Current Location'),
//         icon: BitmapDescriptor.defaultMarkerWithHue(
//             BitmapDescriptor.hueRed), // Red marker for current location
//       ));
//       // Update the map camera position
//       mapController?.animateCamera(
//         CameraUpdate.newLatLngZoom(_currentPosition!, 14.0),
//       );
//     });
//     _updateProviderLocationInFirestore();
//   }

//   // Update provider location in Firestore
//   Future<void> _updateProviderLocationInFirestore() async {
//     final phoneNumber = _auth.currentUser?.phoneNumber?.replaceFirst('+91', '');
//     if (phoneNumber != null) {
//       await FirebaseFirestore.instance
//           .collection('provider')
//           .doc(phoneNumber)
//           .update({
//         'latitude': _currentPosition!.latitude,
//         'longitude': _currentPosition!.longitude,
//       });
//     }
//   }

//   // Fetch locations from Firestore (request location)
//   Future<void> _fetchLocationsFromFirestore() async {
//     try {
//       var snapshot = await FirebaseFirestore.instance
//           .collection(
//               'requests') // Ensure you're fetching from the correct collection
//           .doc(widget.requestId) // Fetch the document using the requestId
//           .get();

//       if (snapshot.exists) {
//         var data = snapshot.data();
//         if (data != null &&
//             data['latitude'] != null &&
//             data['longitude'] != null) {
//           double latitude = data['latitude'];
//           double longitude = data['longitude'];

//           setState(() {
//             // Set the destination location
//             _destination = LatLng(latitude, longitude);

//             // Add the destination marker to the map
//             _markers.add(Marker(
//               markerId: MarkerId('destination'),
//               position: _destination!,
//               infoWindow: InfoWindow(title: 'Destination'),
//               icon: BitmapDescriptor.defaultMarkerWithHue(
//                   BitmapDescriptor.hueBlue), // Blue marker for destination
//             ));
//           });

//           // Call to calculate distance and show the route after fetching the location
//           _calculateDistance();
//         }
//       } else {
//         print("Request document does not exist");
//       }
//     } catch (e) {
//       print("Error fetching location from Firestore: $e");
//     }
//   }

//   // Calculate the route and distance
//   // void _calculateDistance() async {
//   //   if (_destination != null && _currentPosition != null) {
//   //     try {
//   //       // Instantiate Location objects with required lat and lng parameters
//   //       Location currentLocation = Location(
//   //           lat: _currentPosition!.latitude, lng: _currentPosition!.longitude);
//   //       Location destinationLocation =
//   //           Location(lat: _destination!.latitude, lng: _destination!.longitude);

//   //       // Calculate the distance and duration using Directions API
//   //       final response = await _directionsApi.directions(
//   //         currentLocation,
//   //         destinationLocation,
//   //         travelMode:
//   //             TravelMode.driving, // You can adjust this to walking or biking
//   //       );

//   //       if (response.isOkay) {
//   //         // Log the response for debugging
//   //         print(
//   //             "Directions API response: ${response.routes[0].overviewPolyline.points}");

//   //         final legs = response.routes[0].legs[0];

//   //         // Update distance and duration in the state
//   //         setState(() {
//   //           distance = legs.distance.text;
//   //           duration = legs.duration.text;
//   //         });

//   //         // Decode the polyline points and create a polyline on the map
//   //         List<LatLng> routePoints =
//   //             _decodePolyline(response.routes[0].overviewPolyline.points);

//   //         setState(() {
//   //           _polylines.add(maps.Polyline(
//   //             polylineId: PolylineId('route'),
//   //             points: routePoints,
//   //             color: Colors.blue, // Set the polyline color to blue
//   //             width: 5,
//   //           ));
//   //         });
//   //       } else {
//   //         print("Error: ${response.errorMessage}");
//   //       }
//   //     } catch (e) {
//   //       print("Error fetching route: $e");
//   //     }
//   //   }
//   // }

//   void _calculateDistance() async {
//     if (_destination != null && _currentPosition != null) {
//       try {
//         // Instantiate Location objects with the required lat and lng parameters
//         Location _currentLocation = Location(
//             lat: _currentPosition!.latitude, lng: _currentPosition!.longitude);
//         Location _destinationLocation =
//             Location(lat: _destination!.latitude, lng: _destination!.longitude);

//         // Calculate the distance and duration using the Directions API
//         final response = await _directionsApi.directions(
//           _currentLocation,
//           _destinationLocation,
//           travelMode:
//               TravelMode.driving, // You can adjust this to walking or biking
//         );

//         if (response.isOkay) {
//           final legs = response.routes[0].legs[0];

//           // Update distance and duration in the state
//           setState(() {
//             distance = legs.distance.text;
//             duration = legs.duration.text;
//           });

//           // Decode the polyline points and create a polyline on the map
//           setState(() {
//             _polylines.add(maps.Polyline(
//               polylineId: PolylineId('route'),
//               points:
//                   _decodePolyline(response.routes[0].overviewPolyline.points),
//               color: Colors.blue, // Set the polyline color to blue
//               width: 5,
//             ));
//           });
//         } else {
//           print("Error: ${response.errorMessage}");
//         }
//       } catch (e) {
//         print("Error fetching route: $e");
//       }
//     }
//   }

//   // Function to decode the polyline points from Directions API
//   List<LatLng> _decodePolyline(String encodedPolyline) {
//     List<LatLng> polylinePoints = [];
//     int index = 0;
//     int len = encodedPolyline.length;
//     int lat = 0;
//     int lng = 0;

//     while (index < len) {
//       int b;
//       int shift = 0;
//       int result = 0;
//       do {
//         b = encodedPolyline.codeUnitAt(index) - 63;
//         index++;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);

//       int dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
//       lat += dLat;

//       shift = 0;
//       result = 0;
//       do {
//         b = encodedPolyline.codeUnitAt(index) - 63;
//         index++;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);

//       int dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
//       lng += dLng;

//       polylinePoints.add(LatLng(lat / 1E5, lng / 1E5));
//     }
//     return polylinePoints;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Map View')),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: CameraPosition(
//                 target: _currentPosition ?? LatLng(0.0, 0.0), zoom: 14.0),
//             markers: _markers,
//             polylines: _polylines, // Add the polylines to the map
//             onMapCreated: (controller) {
//               mapController = controller;
//             },
//           ),
//           Positioned(
//             bottom: 20,
//             left: 10,
//             right: 10,
//             child: Card(
//               elevation: 5,
//               child: Padding(
//                 padding: const EdgeInsets.all(10.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Distance: $distance', style: TextStyle(fontSize: 16)),
//                     Text('Duration: $duration', style: TextStyle(fontSize: 16)),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_maps_webservice/directions.dart';
// import 'package:google_maps_webservice/places.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;

// class MapPage extends StatefulWidget {
//   final String requestId;

//   MapPage({required this.requestId});

//   @override
//   _MapPageState createState() => _MapPageState();
// }

// class _MapPageState extends State<MapPage> {
//   LatLng? _currentPosition;
//   LatLng? _destination;
//   GoogleMapController? mapController;
//   Set<Marker> _markers = {}; // Set of markers for the map
//   Set<maps.Polyline> _polylines = {}; // Set of polylines for the route
//   String? distance = '';
//   String? duration = '';

//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleMapsDirections _directionsApi =
//       GoogleMapsDirections(apiKey: 'YOUR_API_KEY'); // Replace with your API Key

//   @override
//   void initState() {
//     super.initState();
//     _getUserLocation();
//     _fetchLocationsFromFirestore();
//   }

//   // Fetch the user's current location
//   Future<void> _getUserLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.deniedForever) return;
//     }

//     Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);
//     setState(() {
//       _currentPosition = LatLng(position.latitude, position.longitude);
//       _markers.add(Marker(
//         markerId: MarkerId('current_location'),
//         position: _currentPosition!,
//         infoWindow: InfoWindow(title: 'Current Location'),
//         icon: BitmapDescriptor.defaultMarkerWithHue(
//             BitmapDescriptor.hueRed), // Red marker for current location
//       ));
//       // Update the map camera position
//       mapController?.animateCamera(
//         CameraUpdate.newLatLngZoom(_currentPosition!, 14.0),
//       );
//     });
//     _updateProviderLocationInFirestore();
//   }

//   // Update provider location in Firestore
//   Future<void> _updateProviderLocationInFirestore() async {
//     final phoneNumber = _auth.currentUser?.phoneNumber?.replaceFirst('+91', '');
//     if (phoneNumber != null) {
//       await FirebaseFirestore.instance
//           .collection('provider')
//           .doc(phoneNumber)
//           .update({
//         'latitude': _currentPosition!.latitude,
//         'longitude': _currentPosition!.longitude,
//       });
//     }
//   }

//   // Fetch locations from Firestore (request location)
//   Future<void> _fetchLocationsFromFirestore() async {
//     try {
//       var snapshot = await FirebaseFirestore.instance
//           .collection(
//               'requests') // Ensure you're fetching from the correct collection
//           .doc(widget.requestId) // Fetch the document using the requestId
//           .get();

//       if (snapshot.exists) {
//         var data = snapshot.data();
//         if (data != null &&
//             data['latitude'] != null &&
//             data['longitude'] != null) {
//           double latitude = data['latitude'];
//           double longitude = data['longitude'];

//           setState(() {
//             // Set the destination location
//             _destination = LatLng(latitude, longitude);

//             // Add the destination marker to the map
//             _markers.add(Marker(
//               markerId: MarkerId('destination'),
//               position: _destination!,
//               infoWindow: InfoWindow(title: 'Destination'),
//               icon: BitmapDescriptor.defaultMarkerWithHue(
//                   BitmapDescriptor.hueBlue), // Blue marker for destination
//             ));
//           });

//           // Call to calculate distance and show the route after fetching the location
//           _calculateDistance();
//         }
//       } else {
//         print("Request document does not exist");
//       }
//     } catch (e) {
//       print("Error fetching location from Firestore: $e");
//     }
//   }

//   // Calculate the route and distance
//   void _calculateDistance() async {
//     if (_destination != null && _currentPosition != null) {
//       try {
//         // Instantiate Location objects with the required lat and lng parameters
//         Location _currentLocation = Location(
//             lat: _currentPosition!.latitude, lng: _currentPosition!.longitude);
//         Location _destinationLocation =
//             Location(lat: _destination!.latitude, lng: _destination!.longitude);

//         // Calculate the distance and duration using Directions API
//         final response = await _directionsApi.directions(
//           _currentLocation,
//           _destinationLocation,
//           travelMode:
//               TravelMode.driving, // You can adjust this to walking or biking
//         );

//         if (response.isOkay) {
//           final legs = response.routes[0].legs[0];

//           // Update distance and duration in the state
//           setState(() {
//             distance = legs.distance.text;
//             duration = legs.duration.text;
//           });

//           // Decode the polyline points and create a polyline on the map
//           setState(() {
//             _polylines.add(maps.Polyline(
//               polylineId: PolylineId('route'),
//               points:
//                   _decodePolyline(response.routes[0].overviewPolyline.points),
//               color: Colors.blue, // Set the polyline color to blue
//               width: 5,
//             ));
//           });
//         } else {
//           print("Error: ${response.errorMessage}");
//         }
//       } catch (e) {
//         print("Error fetching route: $e");
//       }
//     }
//   }

//   // Function to decode the polyline points from Directions API
//   List<LatLng> _decodePolyline(String encodedPolyline) {
//     List<LatLng> polylinePoints = [];
//     int index = 0;
//     int len = encodedPolyline.length;
//     int lat = 0;
//     int lng = 0;

//     while (index < len) {
//       int b;
//       int shift = 0;
//       int result = 0;
//       do {
//         b = encodedPolyline.codeUnitAt(index) - 63;
//         index++;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);

//       int dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
//       lat += dLat;

//       shift = 0;
//       result = 0;
//       do {
//         b = encodedPolyline.codeUnitAt(index) - 63;
//         index++;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);

//       int dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
//       lng += dLng;

//       polylinePoints.add(LatLng(lat / 1E5, lng / 1E5));
//     }
//     return polylinePoints;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Map View')),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: CameraPosition(
//                 target: _currentPosition ?? LatLng(0.0, 0.0), zoom: 14.0),
//             markers: _markers,
//             polylines: _polylines, // Add the polylines to the map
//             onMapCreated: (controller) {
//               mapController = controller;
//             },
//           ),
//           Positioned(
//             bottom: 20,
//             left: 10,
//             right: 10,
//             child: Card(
//               elevation: 5,
//               child: Padding(
//                 padding: const EdgeInsets.all(10.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Distance: $distance', style: TextStyle(fontSize: 16)),
//                     Text('Duration: $duration', style: TextStyle(fontSize: 16)),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:convert';
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:http/http.dart' as http;
// import 'package:google_maps_webservice/directions.dart';
// import 'package:google_maps_webservice/places.dart';

// import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;

// class MapPage extends StatefulWidget {
//   final String requestId;

//   MapPage({required this.requestId});

//   @override
//   _MapPageState createState() => _MapPageState();
// }

// class _MapPageState extends State<MapPage> {
//   LatLng? _currentPosition;
//   LatLng? _destination;
//   GoogleMapController? mapController;
//   Set<Marker> _markers = {}; // Set of markers for the map
//   Set<maps.Polyline> _polylines = {}; // Set of polylines for the route
//   String? distance = '';
//   String? duration = '';
//   LatLng? _providerLocation; // Provider location

//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleMapsDirections _directionsApi = GoogleMapsDirections(
//       apiKey:
//           'AIzaSyDrX1E6fyKxDLrZAywYgga5XxMBtmeXufs'); // Replace with your API Key

//   @override
//   void initState() {
//     super.initState();
//     _getUserLocation();
//     _fetchLocationsFromFirestore();
//   }

//   // Fetch the user's current location
//   Future<void> _getUserLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.deniedForever) return;
//     }

//     Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);
//     setState(() {
//       _currentPosition = LatLng(position.latitude, position.longitude);
//       _markers.add(Marker(
//         markerId: MarkerId('current_location'),
//         position: _currentPosition!,
//         infoWindow: InfoWindow(title: 'Current Location'),
//         icon: BitmapDescriptor.defaultMarkerWithHue(
//             BitmapDescriptor.hueRed), // Red marker for current location
//       ));
//       // Update the map camera position
//       mapController?.animateCamera(
//         CameraUpdate.newLatLngZoom(_currentPosition!, 14.0),
//       );
//     });
//     _updateProviderLocationInFirestore();
//   }

//   // Update provider location in Firestore
//   Future<void> _updateProviderLocationInFirestore() async {
//     final phoneNumber = _auth.currentUser?.phoneNumber?.replaceFirst('+91', '');
//     if (phoneNumber != null) {
//       await FirebaseFirestore.instance
//           .collection('provider')
//           .doc(phoneNumber)
//           .update({
//         'latitude': _currentPosition!.latitude,
//         'longitude': _currentPosition!.longitude,
//       });
//     }
//   }

//   // Fetch locations from Firestore (request location)
//   Future<void> _fetchLocationsFromFirestore() async {
//     try {
//       var snapshot = await FirebaseFirestore.instance
//           .collection(
//               'requests') // Ensure you're fetching from the correct collection
//           .doc(widget.requestId) // Fetch the document using the requestId
//           .get();

//       if (snapshot.exists) {
//         var data = snapshot.data();
//         if (data != null &&
//             data['latitude'] != null &&
//             data['longitude'] != null) {
//           double latitude = data['latitude'];
//           double longitude = data['longitude'];

//           setState(() {
//             // Set the destination location
//             _destination = LatLng(latitude, longitude);

//             // Add the destination marker to the map
//             _markers.add(Marker(
//               markerId: MarkerId('destination'),
//               position: _destination!,
//               infoWindow: InfoWindow(title: 'Destination'),
//               icon: BitmapDescriptor.defaultMarkerWithHue(
//                   BitmapDescriptor.hueBlue), // Blue marker for destination
//             ));
//           });

//           // Call to calculate distance and show the route after fetching the location
//           _calculateDistance();
//           _updateRoute();
//         }
//       } else {
//         print("Request document does not exist");
//       }
//     } catch (e) {
//       print("Error fetching location from Firestore: $e");
//     }
//   }

//   // Calculate the route and distance
//   void _calculateDistance() async {
//     if (_destination != null && _currentPosition != null) {
//       try {
//         // Instantiate Location objects with the required lat and lng parameters
//         Location _currentLocation = Location(
//             lat: _currentPosition!.latitude, lng: _currentPosition!.longitude);
//         Location _destinationLocation =
//             Location(lat: _destination!.latitude, lng: _destination!.longitude);

//         // Calculate the distance and duration using Directions API
//         final response = await _directionsApi.directions(
//           _currentLocation,
//           _destinationLocation,
//           travelMode:
//               TravelMode.driving, // You can adjust this to walking or biking
//         );

//         if (response.isOkay) {
//           final legs = response.routes[0].legs[0];

//           // Update distance and duration in the state
//           setState(() {
//             distance = legs.distance.text;
//             duration = legs.duration.text;
//           });

//           // Decode the polyline points and create a polyline on the map
//           setState(() {
//             _polylines.add(maps.Polyline(
//               polylineId: PolylineId('route'),
//               points:
//                   _decodePolyline(response.routes[0].overviewPolyline.points),
//               color: Colors.blue, // Set the polyline color to blue
//               width: 5,
//             ));
//           });
//         } else {
//           print("Error: ${response.errorMessage}");
//         }
//       } catch (e) {
//         print("Error fetching route: $e");
//       }
//     }
//   }

//   // Function to decode the polyline points from Directions API
//   List<LatLng> _decodePolyline(String encodedPolyline) {
//     List<LatLng> polylinePoints = [];
//     int index = 0;
//     int len = encodedPolyline.length;
//     int lat = 0;
//     int lng = 0;

//     while (index < len) {
//       int b;
//       int shift = 0;
//       int result = 0;
//       do {
//         b = encodedPolyline.codeUnitAt(index) - 63;
//         index++;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);

//       int dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
//       lat += dLat;

//       shift = 0;
//       result = 0;
//       do {
//         b = encodedPolyline.codeUnitAt(index) - 63;
//         index++;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);

//       int dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
//       lng += dLng;

//       polylinePoints.add(LatLng(lat / 1E5, lng / 1E5));
//     }
//     return polylinePoints;
//   }

//   // Update route method for provider location and camera adjustment
//   Future<void> _updateRoute() async {
//     if (_providerLocation == null || _currentPosition == null) return;

//     String googleAPIKey =
//         "AIzaSyDrX1E6fyKxDLrZAywYgga5XxMBtmeXufs"; // Replace with your API Key
//     String url =
//         "https://maps.googleapis.com/maps/api/directions/json?origin=${_providerLocation!.latitude},${_providerLocation!.longitude}&destination=${_currentPosition!.latitude},${_currentPosition!.longitude}&key=$googleAPIKey";

//     final response = await http.get(Uri.parse(url));
//     final data = jsonDecode(response.body);

//     if (data['status'] == 'OK') {
//       List<LatLng> routePoints =
//           _decodePolyline(data['routes'][0]['overview_polyline']['points']);
//       setState(() {
//         _polylines = {
//           maps.Polyline(
//             polylineId: const PolylineId('route'),
//             points: routePoints,
//             color: Colors.blue,
//             width: 5,
//           ),
//         };
//         distance = data['routes'][0]['legs'][0]['distance']['text'];
//         duration = data['routes'][0]['legs'][0]['duration']['text'];
//       });

//       // Adjust the camera to fit both user and provider locations
//       mapController?.animateCamera(
//         CameraUpdate.newLatLngBounds(
//           LatLngBounds(
//             southwest: LatLng(
//               routePoints
//                   .map((point) => point.latitude)
//                   .reduce((a, b) => a < b ? a : b),
//               routePoints
//                   .map((point) => point.longitude)
//                   .reduce((a, b) => a < b ? a : b),
//             ),
//             northeast: LatLng(
//               routePoints
//                   .map((point) => point.latitude)
//                   .reduce((a, b) => a > b ? a : b),
//               routePoints
//                   .map((point) => point.longitude)
//                   .reduce((a, b) => a > b ? a : b),
//             ),
//           ),
//           100.0, // Padding for the map (optional)
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Map View')),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: CameraPosition(
//                 target: _currentPosition ?? LatLng(0.0, 0.0), zoom: 14.0),
//             markers: _markers,
//             polylines: _polylines, // Add the polylines to the map
//             onMapCreated: (controller) {
//               mapController = controller;
//             },
//           ),
//           Positioned(
//             bottom: 20,
//             left: 10,
//             right: 10,
//             child: Card(
//               elevation: 5,
//               child: Padding(
//                 padding: const EdgeInsets.all(10.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Distance: $distance', style: TextStyle(fontSize: 16)),
//                     Text('Duration: $duration', style: TextStyle(fontSize: 16)),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  final String requestId;

  MapPage({required this.requestId});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? _providerLocation;
  LatLng? _destination;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String? _distance = '';
  String? _duration = '';
  StreamSubscription<DocumentSnapshot>? _locationSubscription;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _apiKey =
      "AIzaSyDrX1E6fyKxDLrZAywYgga5XxMBtmeXufs"; // Replace with your API key

  @override
  void initState() {
    super.initState();
    _fetchDestination();
    _trackProviderLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _fetchDestination() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .get();

      if (snapshot.exists) {
        var data = snapshot.data();
        if (data != null &&
            data['latitude'] != null &&
            data['longitude'] != null) {
          setState(() {
            _destination = LatLng(data['latitude'], data['longitude']);
            _markers.add(
              Marker(
                markerId: MarkerId('destination'),
                position: _destination!,
                infoWindow: InfoWindow(title: 'Customer Location'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue),
              ),
            );
          });
        }
      }
    } catch (e) {
      print("Error fetching destination: $e");
    }
  }

  void _trackProviderLocation() {
    final phoneNumber = _auth.currentUser?.phoneNumber?.replaceFirst('+91', '');
    if (phoneNumber == null) return;

    _locationSubscription = FirebaseFirestore.instance
        .collection('provider')
        .doc(phoneNumber)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data();
        if (data != null &&
            data['latitude'] != null &&
            data['longitude'] != null) {
          setState(() {
            _providerLocation = LatLng(data['latitude'], data['longitude']);
            _markers.add(
              Marker(
                markerId: MarkerId('provider'),
                position: _providerLocation!,
                infoWindow: InfoWindow(title: 'Provider Location'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
              ),
            );
          });
          _updateRoute();
        }
      }
    });
  }

  void _updateRoute() async {
    if (_providerLocation == null || _destination == null) return;

    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${_providerLocation!.latitude},${_providerLocation!.longitude}&destination=${_destination!.latitude},${_destination!.longitude}&key=$_apiKey";

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data['status'] == 'OK') {
      List<LatLng> routePoints =
          _decodePolyline(data['routes'][0]['overview_polyline']['points']);
      setState(() {
        _polylines = {
          Polyline(
            polylineId: PolylineId('route'),
            points: routePoints,
            color: Colors.blue,
            width: 5,
          ),
        };
        _distance = data['routes'][0]['legs'][0]['distance']['text'];
        _duration = data['routes'][0]['legs'][0]['duration']['text'];
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              routePoints
                  .map((point) => point.latitude)
                  .reduce((a, b) => a < b ? a : b),
              routePoints
                  .map((point) => point.longitude)
                  .reduce((a, b) => a < b ? a : b),
            ),
            northeast: LatLng(
              routePoints
                  .map((point) => point.latitude)
                  .reduce((a, b) => a > b ? a : b),
              routePoints
                  .map((point) => point.longitude)
                  .reduce((a, b) => a > b ? a : b),
            ),
          ),
          100.0,
        ),
      );
    }
  }

  List<LatLng> _decodePolyline(String encodedPolyline) {
    List<LatLng> polylinePoints = [];
    int index = 0, lat = 0, lng = 0;

    while (index < encodedPolyline.length) {
      int b, shift = 0, result = 0;
      do {
        b = encodedPolyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encodedPolyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      polylinePoints.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polylinePoints;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map View')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: LatLng(0.0, 0.0), zoom: 14.0),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) => _mapController = controller,
          ),
          Positioned(
            bottom: 20,
            left: 10,
            right: 10,
            child: Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Text('Distance: $_distance'),
                    Text('Duration: $_duration'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
