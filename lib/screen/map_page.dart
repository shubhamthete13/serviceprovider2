import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_place/google_place.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;
  LatLng _currentPosition = const LatLng(18.520430, 73.856743); // Default: Pune
  LatLng? _destination;
  TextEditingController destinationController = TextEditingController();
  double? _distance;
  final Set<Polyline> _polylines = {};
  final List<LatLng> _polylineCoordinates = [];
  List<AutocompletePrediction> predictions = [];
  final String apiKey = "AIzaSyDrX1E6fyKxDLrZAywYgga5XxMBtmeXufs";
  GooglePlace googlePlace =
      GooglePlace("AIzaSyDrX1E6fyKxDLrZAywYgga5XxMBtmeXufs");

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String phoneNumber = "";

  @override
  void initState() {
    super.initState();
    phoneNumber = _auth.currentUser?.phoneNumber ?? "";
    _getUserLocation();
    destinationController.addListener(() {
      autoCompleteSearch(destinationController.text);
    });
  }

  // Get User's Current Location
  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        print("Location permission denied permanently.");
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    String address = placemarks.isNotEmpty
        ? placemarks.first.street ?? "Unknown Address"
        : "Unknown Address";

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    _updateLocationInFirestore(position.latitude, position.longitude);
  }

  // Update Firestore with Current Location
  Future<void> _updateLocationInFirestore(
      double latitude, double longitude) async {
    User? user = _auth.currentUser;
    if (user == null) {
      print("User not logged in.");
      return;
    }

    String phoneNumber = user.phoneNumber ?? "";
    phoneNumber = phoneNumber.replaceAll("+91", "");

    try {
      await FirebaseFirestore.instance
          .collection('provider')
          .doc(phoneNumber)
          .set({
        'latitude': latitude,
        'longitude': longitude,
      }, SetOptions(merge: true));
      print("Location updated successfully.");
    } catch (e) {
      print("Error updating location: $e");
    }
  }

  // Autocomplete Search for Destination
  void autoCompleteSearch(String query) {
    if (query.isEmpty) {
      setState(() => predictions = []);
      return;
    }

    String sessionToken = DateTime.now().millisecondsSinceEpoch.toString();

    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        var result = await googlePlace.autocomplete
            .get(query, sessionToken: sessionToken);
        if (result != null && result.predictions != null) {
          setState(() => predictions = result.predictions!);
        }
      } catch (e) {
        print("Error fetching autocomplete results: $e");
      }
    });
  }

  // Fetch Destination Coordinates from Place ID
  Future<void> _fetchDestinationCoordinates(String placeId) async {
    try {
      var details = await googlePlace.details.get(placeId);
      if (details != null &&
          details.result != null &&
          details.result!.geometry != null &&
          details.result!.geometry!.location != null) {
        double lat = details.result!.geometry!.location!.lat!;
        double lng = details.result!.geometry!.location!.lng!;

        setState(() {
          _destination = LatLng(lat, lng);
          _calculateDistance();
        });

        _drawRoute();
        mapController?.animateCamera(CameraUpdate.newLatLng(_destination!));
      }
    } catch (e) {
      print("Error fetching destination coordinates: $e");
    }
  }

  // Calculate Distance Between Current Location & Destination
  void _calculateDistance() {
    if (_destination == null) return;

    const double radius = 6371; // Earth's radius in km
    double lat1 = _currentPosition.latitude * (math.pi / 180);
    double lon1 = _currentPosition.longitude * (math.pi / 180);
    double lat2 = _destination!.latitude * (math.pi / 180);
    double lon2 = _destination!.longitude * (math.pi / 180);

    double dlat = lat2 - lat1;
    double dlon = lon2 - lon1;
    double a = math.pow(math.sin(dlat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dlon / 2), 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    setState(() {
      _distance = radius * c;
    });
  }

  // Draw Route on Google Map
  Future<void> _drawRoute() async {
    if (_destination == null) return;

    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      apiKey,
      PointLatLng(_currentPosition.latitude, _currentPosition.longitude),
      PointLatLng(_destination!.latitude, _destination!.longitude),
      travelMode: TravelMode.driving,
    );

    if (result.status == "OK" && result.points.isNotEmpty) {
      setState(() {
        _polylineCoordinates.clear();
        _polylines.clear();

        _polylineCoordinates.addAll(result.points
            .map((point) => LatLng(point.latitude, point.longitude)));

        _polylines.add(Polyline(
          polylineId: const PolylineId("route"),
          points: _polylineCoordinates,
          color: Colors.blue,
          width: 5,
        ));
      });
    } else {
      print("Error fetching route: ${result.errorMessage}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Location & Route Finder")),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _currentPosition, zoom: 13),
              markers: {
                Marker(
                    markerId: const MarkerId("current"),
                    position: _currentPosition),
                if (_destination != null)
                  Marker(
                      markerId: const MarkerId("destination"),
                      position: _destination!),
              },
              polylines: _polylines,
              onMapCreated: (controller) => mapController = controller,
            ),
          ),
          if (_distance != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Distance: ${_distance!.toStringAsFixed(2)} km"),
            ),
        ],
      ),
    );
  }
}
