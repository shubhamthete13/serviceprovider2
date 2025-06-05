import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:serviceprovider/screen/provider_booking_page.dart';
import 'package:serviceprovider/screen/provider_history_page.dart';
import 'package:serviceprovider/screen/profile_page.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:serviceprovider/screen/review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;
  String? serviceCategory;
  int _currentIndex = 0;
  final List<DocumentSnapshot> _temporaryRequests = [];
  Timer? _requestTimer;
  Timer? _locationUpdateTimer;
  String? providerId;
  bool hasReviews = true;

  GoogleMapController? mapController;
  LatLng _currentPosition = const LatLng(18.520430, 73.856743); // Default: Pune
  LatLng? _destination;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final places = GoogleMapsPlaces(
      apiKey:
          'AIzaSyDrX1E6fyKxDLrZAywYgga5XxMBtmeXufs'); // Replace with your API Key

  Set<Marker> _markers = {}; // Set of markers for the map

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowPopup();
      _checkAndShowUserDetailsDialog();
      _listenForIncomingRequests();
      _checkLocationPermission();
    });
    _getUserLocation();
    // _fetchLocationsFromFirestore();
    _startLocationUpdates();
    getCurrentProviderId();
  }

// Fetch current provider ID
  Future<void> getCurrentProviderId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      providerId = user.uid;
      checkProviderReviews(providerId!);
    }
  }

  // Check if provider has reviews
  Future<void> checkProviderReviews(String providerId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('provider_id', isEqualTo: providerId)
        .get();

    setState(() {
      hasReviews = querySnapshot.docs.isNotEmpty;
    });
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationDialog();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: _currentPosition,
          infoWindow: InfoWindow(title: 'Current Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
    _updateProviderLocationInFirestore();
  }

  Future<void> _updateProviderLocationInFirestore() async {
    final phoneNumber = user?.phoneNumber?.replaceFirst('+91', '');
    if (phoneNumber != null) {
      await FirebaseFirestore.instance
          .collection('provider')
          .doc(phoneNumber)
          .update({
        'latitude': _currentPosition.latitude,
        'longitude': _currentPosition.longitude,
      });
    }
  }

  // Future<void> _fetchLocationsFromFirestore() async {
  //   try {
  //     var snapshot = await FirebaseFirestore.instance
  //         .collection('requests')
  //         .where('providerPhoneNumber',
  //             isEqualTo: _auth.currentUser?.phoneNumber?.replaceAll('+91', ''))
  //         .get();

  //     if (snapshot.docs.isNotEmpty) {
  //       var data = snapshot.docs.first.data();
  //       _destination = LatLng(data['latitude'], data['longitude']);
  //       _calculateDistance();
  //     }
  //   } catch (e) {
  //     print("Error fetching provider location: $e");
  //   }
  // }

  // void _calculateDistance() {
  //   if (_destination != null) {
  //     setState(() {
  //       _markers.add(
  //         Marker(
  //           markerId: MarkerId('destination'),
  //           position: _destination!,
  //           infoWindow: InfoWindow(title: 'Destination'),
  //           icon:
  //               BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
  //         ),
  //       );
  //     });
  //   }
  // }

  Future<void> _checkLocationPermission() async {
    bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationEnabled) {
      _showLocationDialog();
    }
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Location Required"),
          content:
              const Text("Please turn on your device's location to proceed."),
          actions: [
            TextButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                Navigator.of(context).pop();
                _checkLocationPermission();
              },
              child: const Text("Turn On"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _getUserLocation();
    });
  }

  Future<void> _listenForIncomingRequests() async {
    final phoneNumber = user?.phoneNumber?.replaceFirst('+91', '');

    if (phoneNumber == null) return;

    try {
      final providerDoc = await FirebaseFirestore.instance
          .collection('provider')
          .doc(phoneNumber)
          .get();

      if (!providerDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Provider not registered.')),
        );
        return;
      }

      final providerCategory = providerDoc.data()?['service_category'] ?? '';

      if (providerCategory.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service category not found.')),
        );
        return;
      }

      FirebaseFirestore.instance
          .collection('requests')
          .where('status', isEqualTo: 'pending')
          .where('category_name', isEqualTo: providerCategory)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          _temporaryRequests.clear();
          _temporaryRequests.addAll(snapshot.docs);
          _restartRequestTimer();
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _restartRequestTimer() {
    _requestTimer?.cancel();
    _requestTimer = Timer(const Duration(minutes: 2), () {
      setState(() {
        _temporaryRequests.clear();
      });
    });
  }

  @override
  void dispose() {
    _requestTimer?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAndShowPopup() async {
    final prefs = await SharedPreferences.getInstance();
    bool showPopup = prefs.getBool('showPopup') ?? true;

    if (showPopup) {
      _showPopupDialog();
      prefs.setBool('showPopup', false);
    }
  }

  void _showPopupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("New Request Available"),
          content: const Text("You have a new service request."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Ok"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkAndShowUserDetailsDialog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String phoneNumber = currentUser.phoneNumber ?? "";

      if (phoneNumber.startsWith("+91")) {
        phoneNumber = phoneNumber.substring(3);
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('provider')
          .doc(phoneNumber)
          .get();

      if (!userDoc.exists ||
          userDoc.data()?['name'] == '' ||
          userDoc.data()?['gender'] == '' ||
          userDoc.data()?['serviceCategories'] == '') {
        _showUserDetailsDialog(phoneNumber);
      }
    }
  }

  void _acceptRequest(Map<String, dynamic> request, String requestId) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({
      'status': 'accepted',
      'providerPhoneNumber': user?.phoneNumber?.replaceFirst('+91', ''),
      'accepted_by': user?.phoneNumber?.replaceFirst('+91', ''),
    });

    setState(() {
      _temporaryRequests.removeWhere((doc) => doc.id == requestId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request accepted successfully!")),
    );
  }

  void _showUserDetailsDialog(String phoneNumber) {
    final TextEditingController nameController = TextEditingController();
    String selectedGender = '';
    String? selectedServiceCategory;
    List<String> serviceCategories = [];

    FirebaseFirestore.instance
        .collection('serviceCategories')
        .get()
        .then((snapshot) {
      setState(() {
        serviceCategories = snapshot.docs.map((doc) => doc.id).toList();
      });
    }).catchError((error) {
      print("Error fetching service categories: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching service categories: $error")),
      );
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Complete Your Profile"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Enter your name",
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedGender.isEmpty ? null : selectedGender,
                onChanged: (value) {
                  setState(() {
                    selectedGender = value!;
                  });
                },
                items: const [
                  DropdownMenuItem(value: "Male", child: Text("Male")),
                  DropdownMenuItem(value: "Female", child: Text("Female")),
                  DropdownMenuItem(value: "Other", child: Text("Other")),
                ],
                decoration: const InputDecoration(
                  labelText: "Select Gender",
                ),
              ),
              const SizedBox(height: 16),
              if (serviceCategories.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: selectedServiceCategory,
                  onChanged: (value) {
                    setState(() {
                      selectedServiceCategory = value!;
                    });
                  },
                  items: serviceCategories
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: "Select Service Category",
                    border: OutlineInputBorder(),
                  ),
                )
              else
                const Text("Loading service categories..."),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    selectedGender.isNotEmpty &&
                    selectedServiceCategory != null) {
                  FirebaseFirestore.instance
                      .collection('provider')
                      .doc(phoneNumber)
                      .set({
                    'name': nameController.text.trim(),
                    'gender': selectedGender,
                    'service_category': selectedServiceCategory,
                    'phone_number': phoneNumber,
                  }, SetOptions(merge: true)).then((_) {
                    Navigator.pop(context);
                  }).catchError((error) {
                    print("Error updating user details: $error");
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("All fields are required!")),
                  );
                }
              },
              child: const Text("OK"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text(
      //     "Service Provider",
      //     style: TextStyle(fontWeight: FontWeight.bold),
      //   ),
      //   backgroundColor: const Color.fromARGB(255, 50, 111, 255),
      // ),
      body: _buildPageContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        backgroundColor: const Color.fromARGB(
            255, 0, 0, 0), // Set your desired background color here
        selectedItemColor: const Color.fromARGB(
            255, 0, 146, 250), // Set the color for selected items
        unselectedItemColor: const Color.fromARGB(255, 0, 0, 0),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Request Service',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          // const BottomNavigationBarItem(
          //   // Always visible
          //   icon: Icon(Icons.reviews),
          //   label: "Reviews",
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_currentIndex) {
      case 1:
        return const ProviderRequestPage();
      case 2:
        return const ProviderHistoryPage();
      // case 3:
      //   if (hasReviews && providerId != null) {
      //     return ReviewPage(providerId: providerId!);
      //   } else {
      //     return const Center(child: Text("No reviews available"));
      //   }
      case 3:
        return const ProfilePage();
      default:
        return Stack(
          children: [
            Column(
              children: [
                if (_temporaryRequests.isNotEmpty)
                  Expanded(
                    flex: 4, // 40% of the screen for incoming requests
                    child: Container(
                      width: double.infinity,
                      color: const Color.fromARGB(255, 255, 255, 255),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Incoming Requests",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _temporaryRequests.length,
                              itemBuilder: (context, index) {
                                var request = _temporaryRequests[index].data()
                                    as Map<String, dynamic>;
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  elevation: 2,
                                  child: ListTile(
                                    title:
                                        Text(request['user_name'] ?? "Unknown"),
                                    subtitle: Text(
                                        request['service_name'] ?? "Service"),
                                    trailing: ElevatedButton(
                                      onPressed: () {
                                        _acceptRequest(request,
                                            _temporaryRequests[index].id);
                                      },
                                      child: const Text("Accept"),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  flex: 6, // 60% of the screen for Google Map
                  child: GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition,
                      zoom: 14,
                    ),
                    markers: _markers,
                    onCameraMove: (position) {
                      setState(() {
                        _currentPosition = position.target;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}
  


// import 'dart:async';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:serviceprovider/screen/provider_booking_page.dart';
// import 'package:serviceprovider/screen/provider_history_page.dart';
// import 'package:serviceprovider/screen/profile_page.dart';
// import 'package:google_maps_webservice/places.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final user = FirebaseAuth.instance.currentUser;
//   String? serviceCategory;
//   int _currentIndex = 0;
//   final List<DocumentSnapshot> _temporaryRequests = [];
//   Timer? _requestTimer;
//   Timer? _locationUpdateTimer;

//   GoogleMapController? mapController;
//   LatLng _currentPosition = const LatLng(18.520430, 73.856743); // Default: Pune
//   LatLng? _destination;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final places = GoogleMapsPlaces(
//       apiKey:
//           'AIzaSyDrX1E6fyKxDLrZAywYgga5XxMBtmeXufs'); // Replace with your API Key

//   Set<Marker> _markers = {}; // Set of markers for the map

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _checkAndShowPopup();
//       _checkAndShowUserDetailsDialog();
//       _listenForIncomingRequests();
//       _checkLocationPermission();
//     });
//     _getUserLocation();
//     _fetchLocationsFromFirestore();
//     _startLocationUpdates();
//   }

//   Future<void> _getUserLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showLocationDialog();
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
//       _markers.add(
//         Marker(
//           markerId: MarkerId('current_location'),
//           position: _currentPosition,
//           infoWindow: InfoWindow(title: 'Current Location'),
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//         ),
//       );
//     });
//     _updateProviderLocationInFirestore();
//   }

//   Future<void> _updateProviderLocationInFirestore() async {
//     final phoneNumber = user?.phoneNumber?.replaceFirst('+91', '');
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

//   Future<void> _fetchLocationsFromFirestore() async {
//     try {
//       var snapshot = await FirebaseFirestore.instance
//           .collection('requests')
//           .where('providerPhoneNumber',
//               isEqualTo: _auth.currentUser?.phoneNumber?.replaceAll('+91', ''))
//           .get();

//       if (snapshot.docs.isNotEmpty) {
//         var data = snapshot.docs.first.data();
//         _destination = LatLng(data['latitude'], data['longitude']);
//         _calculateDistance();
//       }
//     } catch (e) {
//       print("Error fetching provider location: $e");
//     }
//   }

//   void _calculateDistance() {
//     if (_destination != null) {
//       setState(() {
//         _markers.add(
//           Marker(
//             markerId: MarkerId('destination'),
//             position: _destination!,
//             infoWindow: InfoWindow(title: 'Destination'),
//             icon:
//                 BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//           ),
//         );
//       });
//     }
//   }

//   Future<void> _checkLocationPermission() async {
//     bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!isLocationEnabled) {
//       _showLocationDialog();
//     }
//   }

//   void _showLocationDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text("Location Required"),
//           content:
//               const Text("Please turn on your device's location to proceed."),
//           actions: [
//             TextButton(
//               onPressed: () async {
//                 await Geolocator.openLocationSettings();
//                 Navigator.of(context).pop();
//                 _checkLocationPermission();
//               },
//               child: const Text("Turn On"),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text("Cancel"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _startLocationUpdates() {
//     _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
//       _getUserLocation();
//     });
//   }

//   Future<void> _listenForIncomingRequests() async {
//     final phoneNumber = user?.phoneNumber?.replaceFirst('+91', '');

//     if (phoneNumber == null) return;

//     try {
//       final providerDoc = await FirebaseFirestore.instance
//           .collection('provider')
//           .doc(phoneNumber)
//           .get();

//       if (!providerDoc.exists) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Provider not registered.')),
//         );
//         return;
//       }

//       final providerCategory = providerDoc.data()?['service_category'] ?? '';

//       if (providerCategory.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Service category not found.')),
//         );
//         return;
//       }

//       FirebaseFirestore.instance
//           .collection('requests')
//           .where('status', isEqualTo: 'pending')
//           .where('category_name', isEqualTo: providerCategory)
//           .snapshots()
//           .listen((snapshot) {
//         setState(() {
//           _temporaryRequests.clear();
//           _temporaryRequests.addAll(snapshot.docs);
//           _restartRequestTimer();
//         });
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   void _restartRequestTimer() {
//     _requestTimer?.cancel();
//     _requestTimer = Timer(const Duration(minutes: 5), () {
//       setState(() {
//         _temporaryRequests.clear();
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _requestTimer?.cancel();
//     _locationUpdateTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _checkAndShowPopup() async {
//     final prefs = await SharedPreferences.getInstance();
//     bool showPopup = prefs.getBool('showPopup') ?? true;

//     if (showPopup) {
//       _showPopupDialog();
//       prefs.setBool('showPopup', false);
//     }
//   }

//   void _showPopupDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text("New Request Available"),
//           content: const Text("You have a new service request."),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text("Ok"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _checkAndShowUserDetailsDialog() async {
//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser != null) {
//       String phoneNumber = currentUser.phoneNumber ?? "";

//       if (phoneNumber.startsWith("+91")) {
//         phoneNumber = phoneNumber.substring(3);
//       }

//       final userDoc = await FirebaseFirestore.instance
//           .collection('provider')
//           .doc(phoneNumber)
//           .get();

//       if (!userDoc.exists ||
//           userDoc.data()?['name'] == '' ||
//           userDoc.data()?['gender'] == '' ||
//           userDoc.data()?['serviceCategories'] == '') {
//         _showUserDetailsDialog(phoneNumber);
//       }
//     }
//   }

//   void _showUserDetailsDialog(String phoneNumber) {
//     final TextEditingController nameController = TextEditingController();
//     String selectedGender = '';
//     String? selectedServiceCategory;
//     List<String> serviceCategories = [];

//     FirebaseFirestore.instance
//         .collection('serviceCategories')
//         .get()
//         .then((snapshot) {
//       setState(() {
//         serviceCategories = snapshot.docs.map((doc) => doc.id).toList();
//       });
//     }).catchError((error) {
//       print("Error fetching service categories: $error");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error fetching service categories: $error")),
//       );
//     });

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) => AlertDialog(
//           title: const Text("Complete Your Profile"),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: nameController,
//                 decoration: const InputDecoration(
//                   labelText: "Enter your name",
//                 ),
//               ),
//               const SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: selectedGender.isEmpty ? null : selectedGender,
//                 onChanged: (value) {
//                   setState(() {
//                     selectedGender = value!;
//                   });
//                 },
//                 items: const [
//                   DropdownMenuItem(value: "Male", child: Text("Male")),
//                   DropdownMenuItem(value: "Female", child: Text("Female")),
//                   DropdownMenuItem(value: "Other", child: Text("Other")),
//                 ],
//                 decoration: const InputDecoration(
//                   labelText: "Select Gender",
//                 ),
//               ),
//               const SizedBox(height: 16),
//               if (serviceCategories.isNotEmpty)
//                 DropdownButtonFormField<String>(
//                   value: selectedServiceCategory,
//                   onChanged: (value) {
//                     setState(() {
//                       selectedServiceCategory = value!;
//                     });
//                   },
//                   items: serviceCategories
//                       .map((category) => DropdownMenuItem(
//                             value: category,
//                             child: Text(category),
//                           ))
//                       .toList(),
//                   decoration: const InputDecoration(
//                     labelText: "Select Service Category",
//                     border: OutlineInputBorder(),
//                   ),
//                 )
//               else
//                 const Text("Loading service categories..."),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 if (nameController.text.isNotEmpty &&
//                     selectedGender.isNotEmpty &&
//                     selectedServiceCategory != null) {
//                   FirebaseFirestore.instance
//                       .collection('provider')
//                       .doc(phoneNumber)
//                       .set({
//                     'name': nameController.text.trim(),
//                     'gender': selectedGender,
//                     'service_category': selectedServiceCategory,
//                     'phone_number': phoneNumber,
//                   }, SetOptions(merge: true)).then((_) {
//                     Navigator.pop(context);
//                   }).catchError((error) {
//                     print("Error updating user details: $error");
//                   });
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("All fields are required!")),
//                   );
//                 }
//               },
//               child: const Text("OK"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Service Provider",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.green,
//       ),
//       body: _buildPageContent(),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.history),
//             label: 'History',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPageContent() {
//     switch (_currentIndex) {
//       case 1:
//         return const ProviderHistoryPage();
//       case 2:
//         return const ProfilePage();
//       default:
//         return Stack(
//           children: [
//             GoogleMap(
//               onMapCreated: (GoogleMapController controller) {
//                 mapController = controller;
//               },
//               initialCameraPosition: CameraPosition(
//                 target: _currentPosition,
//                 zoom: 14,
//               ),
//               markers: _markers,
//               onCameraMove: (position) {
//                 setState(() {
//                   _currentPosition = position.target;
//                 });
//               },
//             ),
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: ElevatedButton(
//                   onPressed: () {
//                     // Action for button click
//                   },
//                   child: const Text("Request Service"),
//                 ),
//               ),
//             ),
//           ],
//         );
//     }
//   }
// }


// import 'dart:async';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:serviceprovider/screen/provider_booking_page.dart';
// import 'package:serviceprovider/screen/provider_history_page.dart';
// import 'package:serviceprovider/screen/profile_page.dart';
// import 'package:google_maps_webservice/places.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final user = FirebaseAuth.instance.currentUser;
//   String? serviceCategory;
//   int _currentIndex = 0;
//   final List<DocumentSnapshot> _temporaryRequests = [];
//   Timer? _requestTimer;
//   Timer? _locationUpdateTimer;

//   GoogleMapController? mapController;
//   LatLng _currentPosition = const LatLng(18.520430, 73.856743); // Default: Pune
//   LatLng? _destination;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final places = GoogleMapsPlaces(
//       apiKey:
//           'AIzaSyDrX1E6fyKxDLrZAywYgga5XxMBtmeXufs'); // Replace with your API Key

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _checkAndShowPopup();
//       _checkAndShowUserDetailsDialog();
//       _listenForIncomingRequests();
//       _checkLocationPermission();
//     });
//     _getUserLocation();
//     _fetchLocationsFromFirestore();
//     _startLocationUpdates();
//   }

//   Future<void> _getUserLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showLocationDialog();
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
//     });
//     _updateProviderLocationInFirestore();
//   }

//   Future<void> _updateProviderLocationInFirestore() async {
//     final phoneNumber = user?.phoneNumber?.replaceFirst('+91', '');
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

//   Future<void> _fetchLocationsFromFirestore() async {
//     try {
//       var snapshot = await FirebaseFirestore.instance
//           .collection('requests')
//           .where('providerPhoneNumber',
//               isEqualTo: _auth.currentUser?.phoneNumber?.replaceAll('+91', ''))
//           .get();

//       if (snapshot.docs.isNotEmpty) {
//         var data = snapshot.docs.first.data();
//         _destination = LatLng(data['latitude'], data['longitude']);
//         _calculateDistance();
//       }
//     } catch (e) {
//       print("Error fetching provider location: $e");
//     }
//   }

//   void _calculateDistance() {
//     if (_destination != null) {
//       setState(() {});
//     }
//   }

//   Future<void> _checkLocationPermission() async {
//     bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!isLocationEnabled) {
//       _showLocationDialog();
//     }
//   }

//   void _showLocationDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text("Location Required"),
//           content:
//               const Text("Please turn on your device's location to proceed."),
//           actions: [
//             TextButton(
//               onPressed: () async {
//                 await Geolocator.openLocationSettings();
//                 Navigator.of(context).pop();
//                 _checkLocationPermission();
//               },
//               child: const Text("Turn On"),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text("Cancel"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _startLocationUpdates() {
//     _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
//       _getUserLocation();
//     });
//   }

//   Future<void> _listenForIncomingRequests() async {
//     final phoneNumber = user?.phoneNumber?.replaceFirst('+91', '');

//     if (phoneNumber == null) return;

//     try {
//       final providerDoc = await FirebaseFirestore.instance
//           .collection('provider')
//           .doc(phoneNumber)
//           .get();

//       if (!providerDoc.exists) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Provider not registered.')),
//         );
//         return;
//       }

//       final providerCategory = providerDoc.data()?['service_category'] ?? '';

//       if (providerCategory.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Service category not found.')),
//         );
//         return;
//       }

//       FirebaseFirestore.instance
//           .collection('requests')
//           .where('status', isEqualTo: 'pending')
//           .where('category_name', isEqualTo: providerCategory)
//           .snapshots()
//           .listen((snapshot) {
//         setState(() {
//           _temporaryRequests.clear();
//           _temporaryRequests.addAll(snapshot.docs);
//           _restartRequestTimer();
//         });
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   void _restartRequestTimer() {
//     _requestTimer?.cancel();
//     _requestTimer = Timer(const Duration(minutes: 5), () {
//       setState(() {
//         _temporaryRequests.clear();
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _requestTimer?.cancel();
//     _locationUpdateTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _checkAndShowPopup() async {
//     final prefs = await SharedPreferences.getInstance();
//     bool showPopup = prefs.getBool('showPopup') ?? true;

//     if (showPopup) {
//       _showPopupDialog();
//       prefs.setBool('showPopup', false);
//     }
//   }

//   void _showPopupDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text("New Request Available"),
//           content: const Text("You have a new service request."),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text("Ok"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _checkAndShowUserDetailsDialog() async {
//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser != null) {
//       String phoneNumber = currentUser.phoneNumber ?? "";

//       if (phoneNumber.startsWith("+91")) {
//         phoneNumber = phoneNumber.substring(3);
//       }

//       final userDoc = await FirebaseFirestore.instance
//           .collection('provider')
//           .doc(phoneNumber)
//           .get();

//       if (!userDoc.exists ||
//           userDoc.data()?['name'] == '' ||
//           userDoc.data()?['gender'] == '' ||
//           userDoc.data()?['serviceCategories'] == '') {
//         _showUserDetailsDialog(phoneNumber);
//       }
//     }
//   }

//   void _showUserDetailsDialog(String phoneNumber) {
//     final TextEditingController nameController = TextEditingController();
//     String selectedGender = '';
//     String? selectedServiceCategory;
//     List<String> serviceCategories = [];

//     FirebaseFirestore.instance
//         .collection('serviceCategories')
//         .get()
//         .then((snapshot) {
//       setState(() {
//         serviceCategories = snapshot.docs.map((doc) => doc.id).toList();
//       });
//     }).catchError((error) {
//       print("Error fetching service categories: $error");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error fetching service categories: $error")),
//       );
//     });

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) => AlertDialog(
//           title: const Text("Complete Your Profile"),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: nameController,
//                 decoration: const InputDecoration(
//                   labelText: "Enter your name",
//                 ),
//               ),
//               const SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: selectedGender.isEmpty ? null : selectedGender,
//                 onChanged: (value) {
//                   setState(() {
//                     selectedGender = value!;
//                   });
//                 },
//                 items: const [
//                   DropdownMenuItem(value: "Male", child: Text("Male")),
//                   DropdownMenuItem(value: "Female", child: Text("Female")),
//                   DropdownMenuItem(value: "Other", child: Text("Other")),
//                 ],
//                 decoration: const InputDecoration(
//                   labelText: "Select Gender",
//                 ),
//               ),
//               const SizedBox(height: 16),
//               if (serviceCategories.isNotEmpty)
//                 DropdownButtonFormField<String>(
//                   value: selectedServiceCategory,
//                   onChanged: (value) {
//                     setState(() {
//                       selectedServiceCategory = value!;
//                     });
//                   },
//                   items: serviceCategories
//                       .map((category) => DropdownMenuItem(
//                             value: category,
//                             child: Text(category),
//                           ))
//                       .toList(),
//                   decoration: const InputDecoration(
//                     labelText: "Select Service Category",
//                     border: OutlineInputBorder(),
//                   ),
//                 )
//               else
//                 const Text("Loading service categories..."),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 if (nameController.text.isNotEmpty &&
//                     selectedGender.isNotEmpty &&
//                     selectedServiceCategory != null) {
//                   FirebaseFirestore.instance
//                       .collection('provider')
//                       .doc(phoneNumber)
//                       .set({
//                     'name': nameController.text.trim(),
//                     'gender': selectedGender,
//                     'service_category': selectedServiceCategory,
//                     'phone_number': phoneNumber,
//                   }, SetOptions(merge: true)).then((_) {
//                     Navigator.pop(context);
//                   }).catchError((error) {
//                     print("Error updating user details: $error");
//                   });
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("All fields are required!")),
//                   );
//                 }
//               },
//               child: const Text("OK"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Service Provider",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.green,
//       ),
//       body: _buildPageContent(),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.history),
//             label: 'History',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPageContent() {
//     switch (_currentIndex) {
//       case 1:
//         return const ProviderHistoryPage();
//       case 2:
//         return const ProfilePage();
//       default:
//         return Stack(
//           children: [
//             GoogleMap(
//               onMapCreated: (GoogleMapController controller) {
//                 mapController = controller;
//               },
//               initialCameraPosition: CameraPosition(
//                 target: _currentPosition,
//                 zoom: 14,
//               ),
//               markers: _destination != null
//                   ? {
//                       Marker(
//                         markerId: const MarkerId('destination'),
//                         position: _destination!,
//                         infoWindow: const InfoWindow(title: 'Destination'),
//                       ),
//                     }
//                   : {},
//               onCameraMove: (position) {
//                 setState(() {
//                   _currentPosition = position.target;
//                 });
//               },
//             ),
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: ElevatedButton(
//                   onPressed: () {
//                     // Action for button click
//                   },
//                   child: const Text("Request Service"),
//                 ),
//               ),
//             ),
//           ],
//         );
//     }
//   }
// }


// import 'dart:async';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:serviceprovider/screen/provider_booking_page.dart';
// import 'package:serviceprovider/screen/provider_history_page.dart';
// import 'package:serviceprovider/screen/profile_page.dart';
// import 'package:google_maps_webservice/places.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final user = FirebaseAuth.instance.currentUser;
//   String? serviceCategory;
//   int _currentIndex = 0;
//   final List<DocumentSnapshot> _temporaryRequests = [];
//   Timer? _requestTimer;
//   Timer? _locationUpdateTimer;

//   GoogleMapController? mapController;
//   LatLng _currentPosition = const LatLng(18.520430, 73.856743); // Default: Pune
//   LatLng? _destination;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final places = GoogleMapsPlaces(
//       apiKey:
//           'AIzaSyDrX1E6fyKxDLrZAywYgga5XxMBtmeXufs'); // Replace with your API Key

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _checkAndShowPopup();
//       _checkAndShowUserDetailsDialog();
//       _listenForIncomingRequests();
//       _checkLocationPermission();
//     });
//     _getUserLocation();
//     _fetchLocationsFromFirestore();
//     _startLocationUpdates();
//   }

//   Future<void> _getUserLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showLocationDialog();
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
//     });
//     _updateProviderLocationInFirestore();
//   }

//   Future<void> _updateProviderLocationInFirestore() async {
//     final phoneNumber = user?.phoneNumber?.replaceFirst('+91', '');
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

//   Future<void> _fetchLocationsFromFirestore() async {
//     try {
//       var snapshot = await FirebaseFirestore.instance
//           .collection('requests')
//           .where('providerPhoneNumber',
//               isEqualTo: _auth.currentUser?.phoneNumber?.replaceAll('+91', ''))
//           .get();

//       if (snapshot.docs.isNotEmpty) {
//         var data = snapshot.docs.first.data();
//         _destination = LatLng(data['latitude'], data['longitude']);
//         _calculateDistance();
//       }
//     } catch (e) {
//       print("Error fetching provider location: $e");
//     }
//   }

//   void _calculateDistance() {
//     if (_destination != null) {
//       setState(() {});
//     }
//   }

//   Future<void> _checkLocationPermission() async {
//     bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!isLocationEnabled) {
//       _showLocationDialog();
//     }
//   }

//   void _showLocationDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text("Location Required"),
//           content:
//               const Text("Please turn on your device's location to proceed."),
//           actions: [
//             TextButton(
//               onPressed: () async {
//                 await Geolocator.openLocationSettings();
//                 Navigator.of(context).pop();
//                 _checkLocationPermission();
//               },
//               child: const Text("Turn On"),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text("Cancel"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _startLocationUpdates() {
//     _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
//       _getUserLocation();
//     });
//   }

//   Future<void> _listenForIncomingRequests() async {
//     final phoneNumber = user?.phoneNumber?.replaceFirst('+91', '');

//     if (phoneNumber == null) return;

//     try {
//       final providerDoc = await FirebaseFirestore.instance
//           .collection('provider')
//           .doc(phoneNumber)
//           .get();

//       if (!providerDoc.exists) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Provider not registered.')),
//         );
//         return;
//       }

//       final providerCategory = providerDoc.data()?['service_category'] ?? '';

//       if (providerCategory.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Service category not found.')),
//         );
//         return;
//       }

//       FirebaseFirestore.instance
//           .collection('requests')
//           .where('status', isEqualTo: 'pending')
//           .where('category_name', isEqualTo: providerCategory)
//           .snapshots()
//           .listen((snapshot) {
//         setState(() {
//           _temporaryRequests.clear();
//           _temporaryRequests.addAll(snapshot.docs);
//           _restartRequestTimer();
//         });
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   void _restartRequestTimer() {
//     _requestTimer?.cancel();
//     _requestTimer = Timer(const Duration(minutes: 5), () {
//       setState(() {
//         _temporaryRequests.clear();
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _requestTimer?.cancel();
//     _locationUpdateTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _checkAndShowPopup() async {
//     final prefs = await SharedPreferences.getInstance();
//     bool showPopup = prefs.getBool('showPopup') ?? true;

//     if (showPopup) {
//       _showPopupDialog();
//       prefs.setBool('showPopup', false);
//     }
//   }

//   void _showPopupDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text("New Request Available"),
//           content: const Text("You have a new service request."),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text("Ok"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _checkAndShowUserDetailsDialog() async {
//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser != null) {
//       String phoneNumber = currentUser.phoneNumber ?? "";

//       if (phoneNumber.startsWith("+91")) {
//         phoneNumber = phoneNumber.substring(3);
//       }

//       final userDoc = await FirebaseFirestore.instance
//           .collection('provider')
//           .doc(phoneNumber)
//           .get();

//       if (!userDoc.exists ||
//           userDoc.data()?['name'] == '' ||
//           userDoc.data()?['gender'] == '' ||
//           userDoc.data()?['serviceCategories'] == '') {
//         _showUserDetailsDialog(phoneNumber);
//       }
//     }
//   }

//   void _showUserDetailsDialog(String phoneNumber) {
//     final TextEditingController nameController = TextEditingController();
//     String selectedGender = '';
//     String? selectedServiceCategory;
//     List<String> serviceCategories = [];

//     FirebaseFirestore.instance
//         .collection('serviceCategories')
//         .get()
//         .then((snapshot) {
//       setState(() {
//         serviceCategories = snapshot.docs.map((doc) => doc.id).toList();
//       });
//     }).catchError((error) {
//       print("Error fetching service categories: $error");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error fetching service categories: $error")),
//       );
//     });

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) => AlertDialog(
//           title: const Text("Complete Your Profile"),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: nameController,
//                 decoration: const InputDecoration(
//                   labelText: "Enter your name",
//                 ),
//               ),
//               const SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: selectedGender.isEmpty ? null : selectedGender,
//                 onChanged: (value) {
//                   setState(() {
//                     selectedGender = value!;
//                   });
//                 },
//                 items: const [
//                   DropdownMenuItem(value: "Male", child: Text("Male")),
//                   DropdownMenuItem(value: "Female", child: Text("Female")),
//                   DropdownMenuItem(value: "Other", child: Text("Other")),
//                 ],
//                 decoration: const InputDecoration(
//                   labelText: "Select Gender",
//                 ),
//               ),
//               const SizedBox(height: 16),
//               if (serviceCategories.isNotEmpty)
//                 DropdownButtonFormField<String>(
//                   value: selectedServiceCategory,
//                   onChanged: (value) {
//                     setState(() {
//                       selectedServiceCategory = value!;
//                     });
//                   },
//                   items: serviceCategories
//                       .map((category) => DropdownMenuItem(
//                             value: category,
//                             child: Text(category),
//                           ))
//                       .toList(),
//                   decoration: const InputDecoration(
//                     labelText: "Select Service Category",
//                     border: OutlineInputBorder(),
//                   ),
//                 )
//               else
//                 const Text("Loading service categories..."),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 if (nameController.text.isNotEmpty &&
//                     selectedGender.isNotEmpty &&
//                     selectedServiceCategory != null) {
//                   FirebaseFirestore.instance
//                       .collection('provider')
//                       .doc(phoneNumber)
//                       .set({
//                     'name': nameController.text.trim(),
//                     'gender': selectedGender,
//                     'service_category': selectedServiceCategory,
//                     'phone_number': phoneNumber,
//                   }, SetOptions(merge: true)).then((_) {
//                     Navigator.pop(context);
//                   }).catchError((error) {
//                     print("Error updating user details: $error");
//                   });
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("All fields are required!")),
//                   );
//                 }
//               },
//               child: const Text("OK"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Service Provider",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.blueAccent,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () async {
//               await FirebaseAuth.instance.signOut();
//             },
//           ),
//         ],
//       ),
//       body: _currentIndex == 0
//           ? Column(
//               children: [
//                 _temporaryRequests.isNotEmpty
//                     ? Expanded(
//                         flex: 7,
//                         child: ListView.builder(
//                           itemCount: _temporaryRequests.length,
//                           itemBuilder: (context, index) {
//                             final requestData = _temporaryRequests[index].data()
//                                 as Map<String, dynamic>;
//                             return Card(
//                               margin: const EdgeInsets.all(8.0),
//                               child: ListTile(
//                                 title: Text(
//                                     "New Request: ${requestData['service_name']}"),
//                                 subtitle: Text(
//                                     "Customer: ${requestData['user_name']}\nAddress: ${requestData['address']}"),
//                                 trailing: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     TextButton(
//                                       onPressed: () async {
//                                         await _temporaryRequests[index]
//                                             .reference
//                                             .update({'status': 'rejected'});
//                                         ScaffoldMessenger.of(context)
//                                             .showSnackBar(const SnackBar(
//                                                 content:
//                                                     Text("Request Rejected!")));
//                                       },
//                                       child: const Text("Reject"),
//                                     ),
//                                     TextButton(
//                                       onPressed: () async {
//                                         final user =
//                                             FirebaseAuth.instance.currentUser;
//                                         if (user != null) {
//                                           final providerPhoneNumber = user
//                                               .phoneNumber!
//                                               .replaceFirst('+91', '');

//                                           await _temporaryRequests[index]
//                                               .reference
//                                               .update({
//                                             'status': 'accepted',
//                                             'provider_id': providerPhoneNumber,
//                                             'accepted_by': providerPhoneNumber,
//                                           });

//                                           // ignore: use_build_context_synchronously
//                                           ScaffoldMessenger.of(context)
//                                               .showSnackBar(
//                                             const SnackBar(
//                                                 content:
//                                                     Text("Request Accepted!")),
//                                           );
//                                         } else {
//                                           ScaffoldMessenger.of(context)
//                                               .showSnackBar(
//                                             const SnackBar(
//                                                 content: Text(
//                                                     "Error: User not authenticated.")),
//                                           );
//                                         }
//                                       },
//                                       child: const Text("Accept"),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       )
//                     : const Center(child: Text("No New Requests")),
//               ],
//             )
//           : _currentIndex == 1
//               ? const ProviderRequestPage()
//               : _currentIndex == 2
//                   ? const ProviderHistoryPage()
//                   : const ProfilePage(),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//         backgroundColor: const Color.fromARGB(
//             255, 9, 9, 10), // Set your desired background color here
//         selectedItemColor: const Color.fromARGB(
//             255, 0, 106, 254), // Set the color for selected items
//         unselectedItemColor: const Color.fromARGB(255, 0, 0, 0),
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.assignment),
//             label: 'Requests',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.history),
//             label: 'History',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }
// }
// import 'dart:async';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:serviceprovider/screen/map_page.dart';
// import 'package:serviceprovider/screen/profile_page.dart';
// import 'package:serviceprovider/screen/provider_booking_page.dart';
// import 'package:serviceprovider/screen/provider_history_page.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final user = FirebaseAuth.instance.currentUser;
//   String? serviceCategory;
//   int _currentIndex = 0;
//   final List<DocumentSnapshot> _temporaryRequests = [];
//   Timer? _requestTimer;

//   final List<Widget> _pages = [
//     Center(child: Text("Home Page Content")),
//     ProviderRequestPage(),
//     ProviderHistoryPage(),
//     ProfilePage(),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _checkAndShowPopup();
//       _checkAndShowUserDetailsDialog();
//       _listenForIncomingRequests();
//       _checkLocationPermission();
//     });
//   }

//   Future<void> _checkLocationPermission() async {
//     bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!isLocationEnabled) {
//       _showLocationDialog();
//     }
//   }

//   void _showLocationDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text("Location Required"),
//           content:
//               const Text("Please turn on your device's location to proceed."),
//           actions: [
//             TextButton(
//               onPressed: () async {
//                 await Geolocator.openLocationSettings();
//                 Navigator.of(context).pop();
//                 _checkLocationPermission();
//               },
//               child: const Text("Turn On"),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text("Cancel"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _listenForIncomingRequests() async {
//     final phoneNumber = user?.phoneNumber?.replaceFirst('+91', '');

//     if (phoneNumber == null) return;

//     try {
//       final providerDoc = await FirebaseFirestore.instance
//           .collection('provider')
//           .doc(phoneNumber)
//           .get();

//       if (!providerDoc.exists) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Provider not registered.')),
//         );
//         return;
//       }

//       final providerCategory = providerDoc.data()?['service_category'] ?? '';

//       if (providerCategory.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Service category not found.')),
//         );
//         return;
//       }

//       FirebaseFirestore.instance
//           .collection('requests')
//           .where('status', isEqualTo: 'pending')
//           .where('category_name', isEqualTo: providerCategory)
//           .snapshots()
//           .listen((snapshot) {
//         setState(() {
//           _temporaryRequests.clear();
//           _temporaryRequests.addAll(snapshot.docs);
//           _restartRequestTimer();
//         });
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   void _restartRequestTimer() {
//     _requestTimer?.cancel();
//     _requestTimer = Timer(const Duration(minutes: 5), () {
//       setState(() {
//         _temporaryRequests.clear();
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _requestTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _checkAndShowPopup() async {
//     try {
//       final phoneNumber = user!.phoneNumber;
//       if (phoneNumber != null) {
//         final userDoc = await FirebaseFirestore.instance
//             .collection('provider')
//             .doc(phoneNumber)
//             .get();

//         if (userDoc.exists) {
//           final data = userDoc.data();
//           final missingFields = _getMissingFields(data);

//           if (missingFields.isNotEmpty) {
//             _showMissingFieldsDialog(missingFields);
//           } else {
//             fetchAndShowServiceCategoryDialog();
//           }
//         }
//       }
//     } catch (e) {
//       print("Error fetching user data: $e");
//     }
//   }

//   List<String> _getMissingFields(Map<String, dynamic>? data) {
//     if (data == null) return [];
//     final missingFields = <String>[];

//     if (data['name'] == null || data['name'].toString().isEmpty) {
//       missingFields.add('Name');
//     }
//     if (data['gender'] == null || data['gender'].toString().isEmpty) {
//       missingFields.add('Gender');
//     }
//     if (data['age'] == null || data['age'].toString().isEmpty) {
//       missingFields.add('Age');
//     }

//     return missingFields;
//   }

//   void _showMissingFieldsDialog(List<String> missingFields) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text("Complete Your Profile"),
//           content: Text(
//               "The following fields are missing: ${missingFields.join(', ')}. Please update them."),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: const Text("OK"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> fetchAndShowServiceCategoryDialog() async {
//     try {
//       QuerySnapshot snapshot = await FirebaseFirestore.instance
//           .collection('serviceCategories')
//           .get();

//       final fetchedCategories = snapshot.docs.map((doc) => doc.id).toList();

//       if (fetchedCategories.isNotEmpty) {
//         showDialog(
//           context: context,
//           builder: (context) {
//             String selectedCategory = fetchedCategories[0];

//             return AlertDialog(
//               title: const Text("Select Service Category"),
//               content: DropdownButtonFormField<String>(
//                 value: selectedCategory,
//                 items: fetchedCategories
//                     .map((category) => DropdownMenuItem(
//                         value: category, child: Text(category)))
//                     .toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     serviceCategory = value;
//                   });
//                 },
//                 decoration: const InputDecoration(
//                   labelText: "Service Category",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   child: const Text("OK"),
//                 ),
//               ],
//             );
//           },
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No service categories available.')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching categories: $e')),
//       );
//     }
//   }

//   Future<void> _checkAndShowUserDetailsDialog() async {
//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser != null) {
//       String phoneNumber = currentUser.phoneNumber ?? "";

//       if (phoneNumber.startsWith("+91")) {
//         phoneNumber = phoneNumber.substring(3);
//       }

//       final userDoc = await FirebaseFirestore.instance
//           .collection('provider')
//           .doc(phoneNumber)
//           .get();

//       if (!userDoc.exists ||
//           userDoc.data()?['name'] == '' ||
//           userDoc.data()?['gender'] == '' ||
//           userDoc.data()?['serviceCategories'] == '') {
//         _showUserDetailsDialog(phoneNumber);
//       }
//     }
//   }

//   void _showUserDetailsDialog(String phoneNumber) {
//     final TextEditingController nameController = TextEditingController();
//     String selectedGender = '';
//     String? selectedServiceCategory;
//     List<String> serviceCategories = [];

//     FirebaseFirestore.instance
//         .collection('serviceCategories')
//         .get()
//         .then((snapshot) {
//       setState(() {
//         serviceCategories = snapshot.docs.map((doc) => doc.id).toList();
//       });
//     }).catchError((error) {
//       print("Error fetching service categories: $error");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error fetching service categories: $error")),
//       );
//     });

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) => AlertDialog(
//           title: const Text("Complete Your Profile"),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: nameController,
//                 decoration: const InputDecoration(
//                   labelText: "Enter your name",
//                 ),
//               ),
//               const SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: selectedGender.isEmpty ? null : selectedGender,
//                 onChanged: (value) {
//                   setState(() {
//                     selectedGender = value!;
//                   });
//                 },
//                 items: const [
//                   DropdownMenuItem(value: "Male", child: Text("Male")),
//                   DropdownMenuItem(value: "Female", child: Text("Female")),
//                   DropdownMenuItem(value: "Other", child: Text("Other")),
//                 ],
//                 decoration: const InputDecoration(
//                   labelText: "Select Gender",
//                 ),
//               ),
//               const SizedBox(height: 16),
//               if (serviceCategories.isNotEmpty)
//                 DropdownButtonFormField<String>(
//                   value: selectedServiceCategory,
//                   onChanged: (value) {
//                     setState(() {
//                       selectedServiceCategory = value!;
//                     });
//                   },
//                   items: serviceCategories
//                       .map((category) => DropdownMenuItem(
//                             value: category,
//                             child: Text(category),
//                           ))
//                       .toList(),
//                   decoration: const InputDecoration(
//                     labelText: "Select Service Category",
//                     border: OutlineInputBorder(),
//                   ),
//                 )
//               else
//                 const Text("Loading service categories..."),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 if (nameController.text.isNotEmpty &&
//                     selectedGender.isNotEmpty &&
//                     selectedServiceCategory != null) {
//                   FirebaseFirestore.instance
//                       .collection('provider')
//                       .doc(phoneNumber)
//                       .set({
//                     'name': nameController.text.trim(),
//                     'gender': selectedGender,
//                     'service_category': selectedServiceCategory,
//                     'phone_number': phoneNumber,
//                   }, SetOptions(merge: true)).then((_) {
//                     Navigator.pop(context);
//                   }).catchError((error) {
//                     print("Error updating user details: $error");
//                   });
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("All fields are required!")),
//                   );
//                 }
//               },
//               child: const Text("OK"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   signout() async {
//     await FirebaseAuth.instance.signOut();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Service Provider",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.blueAccent,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () async {
//               await FirebaseAuth.instance.signOut();
//             },
//           ),
//         ],
//       ),
//       body: _currentIndex == 0
//           ? Column(
//               children: [
//                 _temporaryRequests.isNotEmpty
//                     ? Expanded(
//                         flex: 7,
//                         child: ListView.builder(
//                           itemCount: _temporaryRequests.length,
//                           itemBuilder: (context, index) {
//                             final requestData = _temporaryRequests[index].data()
//                                 as Map<String, dynamic>;
//                             return Card(
//                               margin: const EdgeInsets.all(8.0),
//                               child: ListTile(
//                                 title: Text(
//                                     "New Request: ${requestData['service_name']}"),
//                                 subtitle: Text(
//                                     "Customer: ${requestData['user_name']}\nAddress: ${requestData['address']}"),
//                                 trailing: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     TextButton(
//                                       onPressed: () async {
//                                         await _temporaryRequests[index]
//                                             .reference
//                                             .update({'status': 'rejected'});
//                                         ScaffoldMessenger.of(context)
//                                             .showSnackBar(const SnackBar(
//                                                 content:
//                                                     Text("Request Rejected!")));
//                                       },
//                                       child: const Text("Reject"),
//                                     ),
//                                     TextButton(
//                                       onPressed: () async {
//                                         final user =
//                                             FirebaseAuth.instance.currentUser;
//                                         if (user != null) {
//                                           final providerPhoneNumber = user
//                                               .phoneNumber!
//                                               .replaceFirst('+91', '');

//                                           await _temporaryRequests[index]
//                                               .reference
//                                               .update({
//                                             'status': 'accepted',
//                                             'provider_id': providerPhoneNumber,
//                                             'accepted_by': providerPhoneNumber,
//                                           });

//                                           // ignore: use_build_context_synchronously
//                                           ScaffoldMessenger.of(context)
//                                               .showSnackBar(
//                                             const SnackBar(
//                                                 content:
//                                                     Text("Request Accepted!")),
//                                           );
//                                         } else {
//                                           ScaffoldMessenger.of(context)
//                                               .showSnackBar(
//                                             const SnackBar(
//                                                 content: Text(
//                                                     "Error: User not authenticated.")),
//                                           );
//                                         }
//                                       },
//                                       child: const Text("Accept"),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       )
//                     : const Center(child: Text("No New Requests")),
//                 Expanded(
//                   child: Center(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const MapPage(),
//                           ),
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blueAccent,
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 32, vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                       ),
//                       child: const Text(
//                         "Go to Map",
//                         style: TextStyle(color: Colors.white, fontSize: 18),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             )
//           : _pages[_currentIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//         selectedItemColor: Colors.blueAccent,
//         unselectedItemColor: Colors.grey,
//         showUnselectedLabels: true,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.assignment),
//             label: 'Requests',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.history),
//             label: 'History',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.account_circle),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }
// }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text(
  //         "Service Provider",
  //         style: TextStyle(fontWeight: FontWeight.bold),
  //       ),
  //       backgroundColor: Colors.blueAccent,
  //       actions: [
  //         IconButton(
  //           icon: const Icon(Icons.logout),
  //           onPressed: () async {
  //             await FirebaseAuth.instance.signOut();
  //           },
  //         ),
  //       ],
  //     ),
  //     body: _currentIndex == 0
  //         ? Column(
  //             children: [
  //               _temporaryRequests.isNotEmpty
  //                   ? Expanded(
  //                       flex: 7,
  //                       child: ListView.builder(
  //                         itemCount: _temporaryRequests.length,
  //                         itemBuilder: (context, index) {
  //                           final requestData = _temporaryRequests[index].data()
  //                               as Map<String, dynamic>;
  //                           return Card(
  //                             margin: const EdgeInsets.all(8.0),
  //                             child: ListTile(
  //                               title: Text(
  //                                   "New Request: ${requestData['serviceName']}"),
  //                               subtitle: Text(
  //                                   "Customer: ${requestData['customerName']}\nAddress: ${requestData['address']}"),
  //                               trailing: Row(
  //                                 mainAxisSize: MainAxisSize.min,
  //                                 children: [
  //                                   TextButton(
  //                                     onPressed: () async {
  //                                       await _temporaryRequests[index]
  //                                           .reference
  //                                           .update({'status': 'rejected'});
  //                                       ScaffoldMessenger.of(context)
  //                                           .showSnackBar(const SnackBar(
  //                                               content:
  //                                                   Text("Request Rejected!")));
  //                                     },
  //                                     child: const Text("Reject"),
  //                                   ),
  //                                   TextButton(
  //                                     onPressed: () async {
  //                                       await _temporaryRequests[index]
  //                                           .reference
  //                                           .update({'status': 'accepted'});
  //                                       ScaffoldMessenger.of(context)
  //                                           .showSnackBar(const SnackBar(
  //                                               content:
  //                                                   Text("Request Accepted!")));
  //                                     },
  //                                     child: const Text("Accept"),
  //                                   ),
  //                                 ],
  //                               ),
  //                             ),
  //                           );
  //                         },
  //                       ),
  //                     )
  //                   : const Center(child: Text("No New Requests")),
  //               Expanded(
  //                 child: Center(
  //                   child: ElevatedButton(
  //                     onPressed: () {
  //                       Navigator.push(
  //                         context,
  //                         MaterialPageRoute(
  //                           builder: (context) => const MapPage(),
  //                         ),
  //                       );
  //                     },
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.blueAccent,
  //                       padding: const EdgeInsets.symmetric(
  //                           horizontal: 32, vertical: 16),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(20),
  //                       ),
  //                     ),
  //                     child: const Text(
  //                       "Go to Map",
  //                       style: TextStyle(color: Colors.white, fontSize: 18),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           )
  //         : _pages[_currentIndex],
  //     bottomNavigationBar: BottomNavigationBar(
  //       currentIndex: _currentIndex,
  //       onTap: (index) {
  //         setState(() {
  //           _currentIndex = index;
  //         });
  //       },
  //       selectedItemColor: Colors.blueAccent,
  //       unselectedItemColor: Colors.grey,
  //       showUnselectedLabels: true,
  //       items: const [
  //         BottomNavigationBarItem(
  //           icon: Icon(Icons.home),
  //           label: 'Home',
  //         ),
  //         BottomNavigationBarItem(
  //           icon: Icon(Icons.assignment),
  //           label: 'Requests',
  //         ),
  //         BottomNavigationBarItem(
  //           icon: Icon(Icons.history),
  //           label: 'History',
  //         ),
  //         BottomNavigationBarItem(
  //           icon: Icon(Icons.account_circle),
  //           label: 'Profile',
  //         ),
  //       ],
  //     ),
  //   );
  // }

