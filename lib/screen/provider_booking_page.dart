// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:firebase_messaging/firebase_messaging.dart';
// // import 'package:serviceprovider/screen/track_customer.dart';
// // import 'package:url_launcher/url_launcher.dart';

// // class ProviderRequestPage extends StatefulWidget {
// //   const ProviderRequestPage({Key? key}) : super(key: key);

// //   @override
// //   _ProviderRequestPageState createState() => _ProviderRequestPageState();
// // }

// // class _ProviderRequestPageState extends State<ProviderRequestPage> {
// //   String? providerCategory;
// //   User? user;
// //   bool isLoading = true;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _checkProviderLogin();
// //   }

// //   Future<void> _checkProviderLogin() async {
// //     user = FirebaseAuth.instance.currentUser;

// //     if (user == null || user!.phoneNumber == null) {
// //       _navigateToSignIn("Please log in to continue.");
// //       return;
// //     }

// //     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

// //     try {
// //       final providerDoc = await FirebaseFirestore.instance
// //           .collection('provider')
// //           .doc(phoneNumber)
// //           .get();

// //       if (!providerDoc.exists) {
// //         _navigateToSignIn("No provider account found. Please register.");
// //         return;
// //       }

// //       setState(() {
// //         providerCategory = providerDoc['service_category'];
// //         isLoading = false;
// //       });

// //       _subscribeToFCM();
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error: $e')),
// //       );
// //       _navigateToSignIn("An error occurred. Please try again.");
// //     }
// //   }

// //   void _subscribeToFCM() {
// //     FirebaseMessaging.instance.subscribeToTopic('providers');
// //   }

// //   void _navigateToSignIn(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text(message)),
// //     );
// //     Navigator.pushReplacementNamed(context, '/signin');
// //   }

// //   Future<void> _acceptRequest(String requestId) async {
// //     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

// //     final requestRef =
// //         FirebaseFirestore.instance.collection('requests').doc(requestId);

// //     try {
// //       await FirebaseFirestore.instance.runTransaction((transaction) async {
// //         final snapshot = await transaction.get(requestRef);
// //         if (snapshot['status'] != 'pending') {
// //           throw Exception('Request already processed.');
// //         }
// //         transaction.update(requestRef, {
// //           'status': 'accepted',
// //           'accepted_by': phoneNumber,
// //           'provider_id': phoneNumber,
// //         });
// //       });

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Request accepted successfully.')),
// //       );
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _routeRequest(String requestId) async {
// //     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');
// //     final requestRef =
// //         FirebaseFirestore.instance.collection('requests').doc(requestId);

// //     try {
// //       await FirebaseFirestore.instance.runTransaction((transaction) async {
// //         final snapshot = await transaction.get(requestRef);

// //         if (!snapshot.exists) {
// //           throw Exception('Request not found.');
// //         }
// //         if (snapshot['status'] != 'accepted') {
// //           throw Exception('Request is not accepted or already processed.');
// //         }

// //         transaction.update(requestRef, {
// //           'status': 'route',
// //           'accepted_by': phoneNumber,
// //           'provider_id': phoneNumber,
// //         });
// //       });

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Routing the customer.')),
// //       );

// //       Navigator.push(
// //         context,
// //         MaterialPageRoute(
// //             builder: (context) => TrackingPage(requestId: requestId)),
// //       );
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _rejectRequest(String requestId) async {
// //     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

// //     await FirebaseFirestore.instance
// //         .collection('requests')
// //         .doc(requestId)
// //         .update({
// //       'rejected_by': FieldValue.arrayUnion([phoneNumber]),
// //     });

// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(content: Text('Request rejected.')),
// //     );
// //   }

// //   Future<void> _completeRequest(String requestId) async {
// //     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

// //     final requestRef =
// //         FirebaseFirestore.instance.collection('requests').doc(requestId);

// //     try {
// //       await FirebaseFirestore.instance.runTransaction((transaction) async {
// //         final snapshot = await transaction.get(requestRef);

// //         if (!snapshot.exists) {
// //           throw Exception('Request not found.');
// //         }

// //         final requestData = snapshot.data() as Map<String, dynamic>;

// //         if (requestData['status'] == 'completed') {
// //           throw Exception('Request is already completed.');
// //         }

// //         if (requestData['accepted_by'] != phoneNumber) {
// //           throw Exception('You are not authorized to complete this request.');
// //         }

// //         transaction.update(requestRef, {
// //           'status': 'completed',
// //           'completed_at': FieldValue.serverTimestamp(),
// //         });
// //       });

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Request marked as completed.')),
// //       );
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _openMap(double latitude, double longitude) async {
// //     final Uri url = Uri.parse(
// //         'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
// //     if (await launchUrl(url)) {
// //       await launchUrl(url);
// //     } else {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Could not open the map.')),
// //       );
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     if (isLoading) {
// //       return const Scaffold(body: Center(child: CircularProgressIndicator()));
// //     }

// //     if (providerCategory == null) {
// //       return const Scaffold(
// //         body: Center(child: Text('Provider data not found.')),
// //       );
// //     }

// //     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Service Requests'),
// //         backgroundColor: Colors.blueAccent,
// //       ),
// //       body: Column(
// //         children: [
// //           Container(
// //             width: double.infinity,
// //             padding: const EdgeInsets.all(16.0),
// //             color: Colors.blueAccent.withOpacity(0.2),
// //             child: Text(
// //               'Service Category: $providerCategory',
// //               style: const TextStyle(
// //                 fontWeight: FontWeight.bold,
// //                 fontSize: 16,
// //                 color: Colors.black87,
// //               ),
// //             ),
// //           ),
// //           Expanded(
// //             child: StreamBuilder<QuerySnapshot>(
// //               stream: FirebaseFirestore.instance
// //                   .collection('requests')
// //                   .where('category_name', isEqualTo: providerCategory)
// //                   .where(Filter.or(
// //                     Filter('status', isEqualTo: 'pending'),
// //                     Filter('accepted_by', isEqualTo: phoneNumber),
// //                   ))
// //                   .snapshots(),
// //               builder: (context, snapshot) {
// //                 if (snapshot.connectionState == ConnectionState.waiting) {
// //                   return const Center(child: CircularProgressIndicator());
// //                 }

// //                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
// //                   return const Center(
// //                       child: Text('No service requests available.'));
// //                 }

// //                 final filteredDocs = snapshot.data!.docs.where((doc) {
// //                   final data = doc.data() as Map<String, dynamic>;
// //                   final rejectedBy =
// //                       data['rejected_by'] as List<dynamic>? ?? [];
// //                   return !rejectedBy.contains(phoneNumber);
// //                 }).toList();

// //                 if (filteredDocs.isEmpty) {
// //                   return const Center(
// //                       child: Text('No pending requests available.'));
// //                 }

// //                 return ListView.builder(
// //                   itemCount: filteredDocs.length,
// //                   itemBuilder: (context, index) {
// //                     var request = filteredDocs[index];
// //                     var requestData = request.data() as Map<String, dynamic>;

// //                     return Card(
// //                       margin: const EdgeInsets.all(12.0),
// //                       elevation: 4,
// //                       child: Padding(
// //                         padding: const EdgeInsets.all(16.0),
// //                         child: Column(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                             Text('Service: ${requestData['service_name']}'),
// //                             Text('User: ${requestData['user_name']}'),
// //                             Text('Phone: ${requestData['user_phone']}'),
// //                             Text('Address: ${requestData['address']}'),
// //                             Text(
// //                                 'Building Name: ${requestData['building_name']}'),
// //                             Text('Category: ${requestData['category_name']}'),
// //                             Text('Status: ${requestData['status']}'),
// //                             const SizedBox(height: 10),
// //                             Column(
// //                               children: [
// //                                 Row(
// //                                   children: [
// //                                     ElevatedButton(
// //                                       onPressed:
// //                                           (requestData['status'] == 'pending')
// //                                               ? () => _acceptRequest(request.id)
// //                                               : null,
// //                                       style: ElevatedButton.styleFrom(
// //                                           backgroundColor: Colors.green),
// //                                       child: const Text('Accept'),
// //                                     ),
// //                                     const SizedBox(width: 10),
// //                                     ElevatedButton(
// //                                       onPressed: (requestData['status'] ==
// //                                               'pending')
// //                                           ? () => _completeRequest(request.id)
// //                                           : null,
// //                                       style: ElevatedButton.styleFrom(
// //                                           backgroundColor: Colors.blue),
// //                                       child: const Text('Complete'),
// //                                     ),
// //                                     const SizedBox(width: 10),
// //                                     ElevatedButton(
// //                                       onPressed:
// //                                           (requestData['status'] == 'pending')
// //                                               ? () => _rejectRequest(request.id)
// //                                               : null,
// //                                       style: ElevatedButton.styleFrom(
// //                                           backgroundColor: Colors.red),
// //                                       child: const Text('Reject'),
// //                                     ),
// //                                   ],
// //                                 ),
// //                                 const SizedBox(height: 10),
// //                                 Visibility(
// //                                   visible: requestData['status'] == 'accepted',
// //                                   child: Row(
// //                                     children: [
// //                                       ElevatedButton(
// //                                         onPressed: () =>
// //                                             _routeRequest(request.id),
// //                                         style: ElevatedButton.styleFrom(
// //                                             backgroundColor: Colors.red),
// //                                         child: const Text('Route'),
// //                                       ),
// //                                       ElevatedButton(
// //                                         onPressed: () =>
// //                                             _completeRequest(request.id),
// //                                         style: ElevatedButton.styleFrom(
// //                                             backgroundColor: Colors.blue),
// //                                         child: const Text('Complete'),
// //                                       ),
// //                                       const SizedBox(width: 10),
// //                                       ElevatedButton(
// //                                         onPressed: () => _openMap(
// //                                             requestData['latitude'],
// //                                             requestData['longitude']),
// //                                         style: ElevatedButton.styleFrom(
// //                                             backgroundColor: Colors.orange),
// //                                         child: const Text('View on Map'),
// //                                       ),
// //                                     ],
// //                                   ),
// //                                 ),
// //                               ],
// //                             )
// //                           ],
// //                         ),
// //                       ),
// //                     );
// //                   },
// //                 );
// //               },
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:firebase_messaging/firebase_messaging.dart';
// // import 'package:serviceprovider/screen/track_customer.dart';
// // import 'package:url_launcher/url_launcher.dart';

// // class ProviderRequestPage extends StatefulWidget {
// //   const ProviderRequestPage({Key? key}) : super(key: key);

// //   @override
// //   _ProviderRequestPageState createState() => _ProviderRequestPageState();
// // }

// // class _ProviderRequestPageState extends State<ProviderRequestPage> {
// //   String? providerCategory;
// //   User? user;
// //   bool isLoading = true;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _checkProviderLogin();
// //   }

// //   Future<void> _checkProviderLogin() async {
// //     user = FirebaseAuth.instance.currentUser;

// //     if (user == null || user!.phoneNumber == null) {
// //       _navigateToSignIn("Please log in to continue.");
// //       return;
// //     }

// //     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

// //     try {
// //       final providerDoc = await FirebaseFirestore.instance
// //           .collection('provider')
// //           .doc(phoneNumber)
// //           .get();

// //       if (!providerDoc.exists) {
// //         _navigateToSignIn("No provider account found. Please register.");
// //         return;
// //       }

// //       setState(() {
// //         providerCategory = providerDoc['service_category'];
// //         isLoading = false;
// //       });

// //       _subscribeToFCM();
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error: $e')),
// //       );
// //       _navigateToSignIn("An error occurred. Please try again.");
// //     }
// //   }

// //   void _subscribeToFCM() {
// //     FirebaseMessaging.instance.subscribeToTopic('providers');
// //   }

// //   void _navigateToSignIn(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text(message)),
// //     );
// //     Navigator.pushReplacementNamed(context, '/signin');
// //   }

// //   Future<void> _acceptRequest(String requestId) async {
// //     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

// //     final requestRef =
// //         FirebaseFirestore.instance.collection('requests').doc(requestId);

// //     try {
// //       await FirebaseFirestore.instance.runTransaction((transaction) async {
// //         final snapshot = await transaction.get(requestRef);
// //         if (snapshot['status'] != 'pending') {
// //           throw Exception('Request already processed.');
// //         }
// //         transaction.update(requestRef, {
// //           'status': 'accepted',
// //           'accepted_by': phoneNumber,
// //           'provider_id': phoneNumber,
// //         });
// //       });

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Request accepted successfully.')),
// //       );
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _routeRequest(String requestId) async {
// //     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');
// //     final requestRef =
// //         FirebaseFirestore.instance.collection('requests').doc(requestId);

// //     try {
// //       await FirebaseFirestore.instance.runTransaction((transaction) async {
// //         final snapshot = await transaction.get(requestRef);

// //         if (!snapshot.exists) {
// //           throw Exception('Request not found.');
// //         }
// //         if (snapshot['status'] != 'accepted') {
// //           throw Exception('Request is not accepted or already processed.');
// //         }

// //         transaction.update(requestRef, {
// //           'status': 'route',
// //           'accepted_by': phoneNumber,
// //           'provider_id': phoneNumber,
// //         });
// //       });

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Routing the customer.')),
// //       );

// //       Navigator.push(
// //         context,
// //         MaterialPageRoute(
// //             builder: (context) => TrackingPage(
// //                   requestId: requestId,
// //                   userLat: 0.0,
// //                   userLng: 0.0,
// //                   providerId: '',
// //                 )),
// //       );
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _rejectRequest(String requestId) async {
// //     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

// //     await FirebaseFirestore.instance
// //         .collection('requests')
// //         .doc(requestId)
// //         .update({
// //       'rejected_by': FieldValue.arrayUnion([phoneNumber]),
// //     });

// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(content: Text('Request rejected.')),
// //     );
// //   }

// //   Future<void> _completeRequest(String requestId) async {
// //     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

// //     final requestRef =
// //         FirebaseFirestore.instance.collection('requests').doc(requestId);

// //     try {
// //       await FirebaseFirestore.instance.runTransaction((transaction) async {
// //         final snapshot = await transaction.get(requestRef);

// //         if (!snapshot.exists) {
// //           throw Exception('Request not found.');
// //         }

// //         final requestData = snapshot.data() as Map<String, dynamic>;

// //         if (requestData['status'] == 'completed') {
// //           throw Exception('Request is already completed.');
// //         }

// //         if (requestData['accepted_by'] != phoneNumber) {
// //           throw Exception('You are not authorized to complete this request.');
// //         }

// //         transaction.update(requestRef, {
// //           'status': 'completed',
// //           'completed_at': FieldValue.serverTimestamp(),
// //         });
// //       });

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Request marked as completed.')),
// //       );
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _openMap(double latitude, double longitude) async {
// //     final Uri url = Uri.parse(
// //         'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
// //     if (await launchUrl(url)) {
// //       await launchUrl(url);
// //     } else {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Could not open the map.')),
// //       );
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     if (isLoading) {
// //       return const Scaffold(body: Center(child: CircularProgressIndicator()));
// //     }

// //     if (providerCategory == null) {
// //       return const Scaffold(
// //         body: Center(child: Text('Provider data not found.')),
// //       );
// //     }

// //     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Service Requests'),
// //         backgroundColor: Colors.blueAccent,
// //       ),
// //       body: Column(
// //         children: [
// //           Container(
// //             width: double.infinity,
// //             padding: const EdgeInsets.all(16.0),
// //             color: Colors.blueAccent.withOpacity(0.2),
// //             child: Text(
// //               'Service Category: $providerCategory',
// //               style: const TextStyle(
// //                 fontWeight: FontWeight.bold,
// //                 fontSize: 16,
// //                 color: Colors.black87,
// //               ),
// //             ),
// //           ),
// //           Expanded(
// //             child: StreamBuilder<QuerySnapshot>(
// //               stream: FirebaseFirestore.instance
// //                   .collection('requests')
// //                   .where('category_name', isEqualTo: providerCategory)
// //                   .where(Filter.or(
// //                     Filter('status', isEqualTo: 'pending'),
// //                     Filter('accepted_by', isEqualTo: phoneNumber),
// //                   ))
// //                   .snapshots(),
// //               builder: (context, snapshot) {
// //                 if (snapshot.connectionState == ConnectionState.waiting) {
// //                   return const Center(child: CircularProgressIndicator());
// //                 }

// //                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
// //                   return const Center(
// //                       child: Text('No service requests available.'));
// //                 }

// //                 final filteredDocs = snapshot.data!.docs.where((doc) {
// //                   final data = doc.data() as Map<String, dynamic>;
// //                   final rejectedBy =
// //                       data['rejected_by'] as List<dynamic>? ?? [];
// //                   return !rejectedBy.contains(phoneNumber);
// //                 }).toList();

// //                 if (filteredDocs.isEmpty) {
// //                   return const Center(
// //                       child: Text('No pending requests available.'));
// //                 }

// //                 return ListView.builder(
// //                   itemCount: filteredDocs.length,
// //                   itemBuilder: (context, index) {
// //                     var request = filteredDocs[index];
// //                     var requestData = request.data() as Map<String, dynamic>;

// //                     String requestStatus = requestData['status'];
// //                     bool isAccepted = requestStatus == 'accepted';
// //                     bool isRoute = requestStatus == 'route';

// //                     return Card(
// //                       margin: const EdgeInsets.all(12.0),
// //                       elevation: 4,
// //                       child: Padding(
// //                         padding: const EdgeInsets.all(16.0),
// //                         child: Column(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                             Text('Service: ${requestData['service_name']}'),
// //                             Text('User: ${requestData['user_name']}'),
// //                             Text('Phone: ${requestData['user_phone']}'),
// //                             Text('Address: ${requestData['address']}'),
// //                             Text(
// //                                 'Building Name: ${requestData['building_name']}'),
// //                             Text('Category: ${requestData['category_name']}'),
// //                             Text('Status: $requestStatus'),
// //                             const SizedBox(height: 10),
// //                             // First Row with Accept, Reject, Complete buttons
// //                             Row(
// //                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                               children: [
// //                                 ElevatedButton(
// //                                   onPressed: isAccepted
// //                                       ? null
// //                                       : () => _acceptRequest(request.id),
// //                                   style: ElevatedButton.styleFrom(
// //                                       backgroundColor: Colors.green),
// //                                   child: const Text('Accept'),
// //                                 ),
// //                                 const SizedBox(width: 10),
// //                                 ElevatedButton(
// //                                   onPressed: () => _completeRequest(request.id),
// //                                   style: ElevatedButton.styleFrom(
// //                                       backgroundColor: Colors.blue),
// //                                   child: const Text('Complete'),
// //                                 ),
// //                                 const SizedBox(width: 10),
// //                                 Visibility(
// //                                   // visible: !isAccepted,
// //                                   child: ElevatedButton(
// //                                     onPressed: () => _rejectRequest(request.id),
// //                                     style: ElevatedButton.styleFrom(
// //                                         backgroundColor: Colors.red),
// //                                     child: const Text('Reject'),
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                             const SizedBox(height: 10),
// //                             // Second Row with Route and View on Map buttons
// //                             Visibility(
// //                               visible: isAccepted || isRoute,
// //                               child: Row(
// //                                 mainAxisAlignment:
// //                                     MainAxisAlignment.spaceBetween,
// //                                 children: [
// //                                   Visibility(
// //                                     visible: isAccepted || isRoute,
// //                                     child: ElevatedButton(
// //                                       onPressed: () =>
// //                                           _routeRequest(request.id),
// //                                       style: ElevatedButton.styleFrom(
// //                                           backgroundColor: Colors.red),
// //                                       child: const Text('Route'),
// //                                     ),
// //                                   ),
// //                                   const SizedBox(width: 10),
// //                                   ElevatedButton(
// //                                     onPressed: () => _openMap(
// //                                         requestData['latitude'],
// //                                         requestData['longitude']),
// //                                     style: ElevatedButton.styleFrom(
// //                                         backgroundColor: Colors.orange),
// //                                     child: const Text('View on Map'),
// //                                   ),
// //                                 ],
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     );
// //                   },
// //                 );
// //               },
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:firebase_messaging/firebase_messaging.dart';
// // import 'package:serviceprovider/screen/track_customer.dart';
// // import 'package:url_launcher/url_launcher.dart';

// // class ProviderRequestPage extends StatefulWidget {
// //   const ProviderRequestPage({Key? key}) : super(key: key);

// //   @override
// //   _ProviderRequestPageState createState() => _ProviderRequestPageState();
// // }

// // class _ProviderRequestPageState extends State<ProviderRequestPage> {
// //   String? providerCategory;
// //   User? user;
// //   bool isLoading = true;
// //   double? enteredAmount;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _checkProviderLogin();
// //   }

// //   Future<void> _checkProviderLogin() async {
// //     user = FirebaseAuth.instance.currentUser;

// //     if (user == null || user!.phoneNumber == null) {
// //       _navigateToSignIn("Please log in to continue.");
// //       return;
// //     }

// //     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

// //     try {
// //       final providerDoc = await FirebaseFirestore.instance
// //           .collection('provider')
// //           .doc(phoneNumber)
// //           .get();

// //       if (!providerDoc.exists) {
// //         _navigateToSignIn("No provider account found. Please register.");
// //         return;
// //       }

// //       setState(() {
// //         providerCategory = providerDoc['service_category'];
// //         isLoading = false;
// //       });

// //       _subscribeToFCM();
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error: $e')),
// //       );
// //       _navigateToSignIn("An error occurred. Please try again.");
// //     }
// //   }

// //   void _subscribeToFCM() {
// //     FirebaseMessaging.instance.subscribeToTopic('providers');
// //   }

// //   void _navigateToSignIn(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text(message)),
// //     );
// //     Navigator.pushReplacementNamed(context, '/signin');
// //   }

// //   Future<void> _acceptRequest(String requestId) async {
// //     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

// //     final requestRef =
// //         FirebaseFirestore.instance.collection('requests').doc(requestId);

// //     try {
// //       await FirebaseFirestore.instance.runTransaction((transaction) async {
// //         final snapshot = await transaction.get(requestRef);
// //         if (snapshot['status'] != 'pending') {
// //           throw Exception('Request already processed.');
// //         }
// //         transaction.update(requestRef, {
// //           'status': 'accepted',
// //           'accepted_by': phoneNumber,
// //           'provider_id': phoneNumber,
// //         });
// //       });

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Request accepted successfully.')),
// //       );
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _routeRequest(String requestId) async {
// //     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');
// //     final requestRef =
// //         FirebaseFirestore.instance.collection('requests').doc(requestId);

// //     try {
// //       await FirebaseFirestore.instance.runTransaction((transaction) async {
// //         final snapshot = await transaction.get(requestRef);

// //         if (!snapshot.exists) {
// //           throw Exception('Request not found.');
// //         }
// //         if (snapshot['status'] != 'accepted') {
// //           throw Exception('Request is not accepted or already processed.');
// //         }

// //         transaction.update(requestRef, {
// //           'status': 'route',
// //           'accepted_by': phoneNumber,
// //           'provider_id': phoneNumber,
// //         });
// //       });

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Routing the customer.')),
// //       );

// //       Navigator.push(
// //         context,
// //         MaterialPageRoute(
// //             builder: (context) => TrackingPage(
// //                   requestId: requestId,
// //                   userLat: 0.0,
// //                   userLng: 0.0,
// //                   providerId: '',
// //                 )),
// //       );
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _rejectRequest(String requestId) async {
// //     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

// //     await FirebaseFirestore.instance
// //         .collection('requests')
// //         .doc(requestId)
// //         .update({
// //       'rejected_by': FieldValue.arrayUnion([phoneNumber]),
// //     });

// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(content: Text('Request rejected.')),
// //     );
// //   }

// //   Future<void> _completeRequest(String requestId) async {
// //     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');
// //     final requestRef =
// //         FirebaseFirestore.instance.collection('requests').doc(requestId);

// //     try {
// //       await FirebaseFirestore.instance.runTransaction((transaction) async {
// //         final snapshot = await transaction.get(requestRef);

// //         if (!snapshot.exists) {
// //           throw Exception('Request not found.');
// //         }

// //         final requestData = snapshot.data() as Map<String, dynamic>;

// //         if (requestData['status'] == 'completed') {
// //           throw Exception('Request is already completed.');
// //         }

// //         if (requestData['accepted_by'] != phoneNumber) {
// //           throw Exception('You are not authorized to complete this request.');
// //         }

// //         transaction.update(requestRef, {
// //           'status': 'completed',
// //           'completed_at': FieldValue.serverTimestamp(),
// //           'total_cost': enteredAmount, // Add the total cost
// //         });
// //       });

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Request marked as completed.')),
// //       );
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _openMap(double latitude, double longitude) async {
// //     final Uri url = Uri.parse(
// //         'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
// //     if (await launchUrl(url)) {
// //       await launchUrl(url);
// //     } else {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Could not open the map.')),
// //       );
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     if (isLoading) {
// //       return const Scaffold(body: Center(child: CircularProgressIndicator()));
// //     }

// //     if (providerCategory == null) {
// //       return const Scaffold(
// //         body: Center(child: Text('Provider data not found.')),
// //       );
// //     }

// //     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Service Requests'),
// //         backgroundColor: Colors.blueAccent,
// //       ),
// //       body: Column(
// //         children: [
// //           Container(
// //             width: double.infinity,
// //             padding: const EdgeInsets.all(16.0),
// //             color: Colors.blueAccent.withOpacity(0.2),
// //             child: Text(
// //               'Service Category: $providerCategory',
// //               style: const TextStyle(
// //                 fontWeight: FontWeight.bold,
// //                 fontSize: 16,
// //                 color: Colors.black87,
// //               ),
// //             ),
// //           ),
// //           Expanded(
// //             child: StreamBuilder<QuerySnapshot>(
// //               stream: FirebaseFirestore.instance
// //                   .collection('requests')
// //                   .where('category_name', isEqualTo: providerCategory)
// //                   .where(Filter.or(
// //                     Filter('status', isEqualTo: 'pending'),
// //                     Filter('accepted_by', isEqualTo: phoneNumber),
// //                   ))
// //                   .snapshots(),
// //               builder: (context, snapshot) {
// //                 if (snapshot.connectionState == ConnectionState.waiting) {
// //                   return const Center(child: CircularProgressIndicator());
// //                 }

// //                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
// //                   return const Center(
// //                       child: Text('No service requests available.'));
// //                 }

// //                 final filteredDocs = snapshot.data!.docs.where((doc) {
// //                   final data = doc.data() as Map<String, dynamic>;
// //                   final rejectedBy =
// //                       data['rejected_by'] as List<dynamic>? ?? [];
// //                   return !rejectedBy.contains(phoneNumber);
// //                 }).toList();

// //                 if (filteredDocs.isEmpty) {
// //                   return const Center(
// //                       child: Text('No pending requests available.'));
// //                 }

// //                 return ListView.builder(
// //                   itemCount: filteredDocs.length,
// //                   itemBuilder: (context, index) {
// //                     var request = filteredDocs[index];
// //                     var requestData = request.data() as Map<String, dynamic>;

// //                     String requestStatus = requestData['status'];
// //                     bool isAccepted = requestStatus == 'accepted';
// //                     bool isRoute = requestStatus == 'route';

// //                     return Card(
// //                       margin: const EdgeInsets.all(12.0),
// //                       elevation: 4,
// //                       child: Padding(
// //                         padding: const EdgeInsets.all(16.0),
// //                         child: Column(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                             Text('Service: ${requestData['service_name']}'),
// //                             Text('User: ${requestData['user_name']}'),
// //                             Text('Phone: ${requestData['user_phone']}'),
// //                             Text('Address: ${requestData['address']}'),
// //                             Text(
// //                                 'Building Name: ${requestData['building_name']}'),
// //                             Text('Category: ${requestData['category_name']}'),
// //                             Text('Status: $requestStatus'),
// //                             const SizedBox(height: 10),
// //                             // Amount Input (Visible on 'completed' status)
// //                             if (requestData['status'] == 'completed')
// //                               TextFormField(
// //                                 decoration: const InputDecoration(
// //                                   labelText: 'Enter Total Work Cost',
// //                                 ),
// //                                 keyboardType: TextInputType.number,
// //                                 onChanged: (value) {
// //                                   setState(() {
// //                                     enteredAmount = double.tryParse(value);
// //                                   });
// //                                 },
// //                               ),
// //                             const SizedBox(height: 10),
// //                             // First Row with Accept, Reject, Complete buttons
// //                             Row(
// //                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                               children: [
// //                                 ElevatedButton(
// //                                   onPressed: isAccepted
// //                                       ? null
// //                                       : () => _acceptRequest(request.id),
// //                                   style: ElevatedButton.styleFrom(
// //                                       backgroundColor: Colors.green),
// //                                   child: const Text('Accept'),
// //                                 ),
// //                                 const SizedBox(width: 10),
// //                                 ElevatedButton(
// //                                   onPressed: () => _completeRequest(request.id),
// //                                   style: ElevatedButton.styleFrom(
// //                                       backgroundColor: Colors.blue),
// //                                   child: const Text('Complete'),
// //                                 ),
// //                                 const SizedBox(width: 10),
// //                                 Visibility(
// //                                   // visible: !isAccepted,
// //                                   child: ElevatedButton(
// //                                     onPressed: () => _rejectRequest(request.id),
// //                                     style: ElevatedButton.styleFrom(
// //                                         backgroundColor: Colors.red),
// //                                     child: const Text('Reject'),
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                             const SizedBox(height: 10),
// //                             // Second Row with Route and View on Map buttons
// //                             Visibility(
// //                               visible: isAccepted || isRoute,
// //                               child: Row(
// //                                 mainAxisAlignment:
// //                                     MainAxisAlignment.spaceBetween,
// //                                 children: [
// //                                   Visibility(
// //                                     visible: isAccepted || isRoute,
// //                                     child: ElevatedButton(
// //                                       onPressed: () =>
// //                                           _routeRequest(request.id),
// //                                       style: ElevatedButton.styleFrom(
// //                                           backgroundColor: Colors.red),
// //                                       child: const Text('Route'),
// //                                     ),
// //                                   ),
// //                                   const SizedBox(width: 10),
// //                                   ElevatedButton(
// //                                     onPressed: () => _openMap(
// //                                         requestData['latitude'],
// //                                         requestData['longitude']),
// //                                     style: ElevatedButton.styleFrom(
// //                                         backgroundColor: Colors.orange),
// //                                     child: const Text('View on Map'),
// //                                   ),
// //                                 ],
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     );
// //                   },
// //                 );
// //               },
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:serviceprovider/screen/track_customer.dart';
// import 'package:url_launcher/url_launcher.dart';

// class ProviderRequestPage extends StatefulWidget {
//   const ProviderRequestPage({Key? key}) : super(key: key);

//   @override
//   _ProviderRequestPageState createState() => _ProviderRequestPageState();
// }

// class _ProviderRequestPageState extends State<ProviderRequestPage> {
//   String? providerCategory;
//   User? user;
//   bool isLoading = true;
//   double? enteredAmount;
//   double totalCost = 0.0;

//   @override
//   void initState() {
//     super.initState();
//     _checkProviderLogin();
//   }

//   Future<void> _checkProviderLogin() async {
//     user = FirebaseAuth.instance.currentUser;

//     if (user == null || user!.phoneNumber == null) {
//       _navigateToSignIn("Please log in to continue.");
//       return;
//     }

//     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

//     try {
//       final providerDoc = await FirebaseFirestore.instance
//           .collection('provider')
//           .doc(phoneNumber)
//           .get();

//       if (!providerDoc.exists) {
//         _navigateToSignIn("No provider account found. Please register.");
//         return;
//       }

//       setState(() {
//         providerCategory = providerDoc['service_category'];
//         isLoading = false;
//       });

//       _subscribeToFCM();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//       _navigateToSignIn("An error occurred. Please try again.");
//     }
//   }

//   void _subscribeToFCM() {
//     FirebaseMessaging.instance.subscribeToTopic('providers');
//   }

//   void _navigateToSignIn(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//     Navigator.pushReplacementNamed(context, '/signin');
//   }

//   Future<void> _acceptRequest(String requestId) async {
//     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

//     final requestRef =
//         FirebaseFirestore.instance.collection('requests').doc(requestId);

//     try {
//       await FirebaseFirestore.instance.runTransaction((transaction) async {
//         final snapshot = await transaction.get(requestRef);
//         if (snapshot['status'] != 'pending') {
//           throw Exception('Request already processed.');
//         }
//         transaction.update(requestRef, {
//           'status': 'accepted',
//           'accepted_by': phoneNumber,
//           'provider_id': phoneNumber,
//         });
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Request accepted successfully.')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _routeRequest(String requestId) async {
//     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');
//     final requestRef =
//         FirebaseFirestore.instance.collection('requests').doc(requestId);

//     try {
//       await FirebaseFirestore.instance.runTransaction((transaction) async {
//         final snapshot = await transaction.get(requestRef);

//         if (!snapshot.exists) {
//           throw Exception('Request not found.');
//         }
//         if (snapshot['status'] != 'accepted') {
//           throw Exception('Request is not accepted or already processed.');
//         }

//         transaction.update(requestRef, {
//           'status': 'route',
//           'accepted_by': phoneNumber,
//           'provider_id': phoneNumber,
//         });
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Routing the customer.')),
//       );

//       Navigator.push(
//         context,
//         MaterialPageRoute(
//             builder: (context) => TrackingPage(
//                   requestId: requestId,
//                   userLat: 0.0,
//                   userLng: 0.0,
//                   providerId: '',
//                 )),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _rejectRequest(String requestId) async {
//     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

//     await FirebaseFirestore.instance
//         .collection('requests')
//         .doc(requestId)
//         .update({
//       'rejected_by': FieldValue.arrayUnion([phoneNumber]),
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Request rejected.')),
//     );
//   }

//   Future<void> _completeRequest(String requestId) async {
//     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');
//     final requestRef =
//         FirebaseFirestore.instance.collection('requests').doc(requestId);

//     try {
//       await FirebaseFirestore.instance.runTransaction((transaction) async {
//         final snapshot = await transaction.get(requestRef);

//         if (!snapshot.exists) {
//           throw Exception('Request not found.');
//         }

//         final requestData = snapshot.data() as Map<String, dynamic>;

//         if (requestData['status'] == 'completed') {
//           throw Exception('Request is already completed.');
//         }

//         if (requestData['accepted_by'] != phoneNumber) {
//           throw Exception('You are not authorized to complete this request.');
//         }

//         transaction.update(requestRef, {
//           'status': 'completed',
//           'completed_at': FieldValue.serverTimestamp(),
//           'total_cost': totalCost, // Store the total cost in the request
//         });
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Request marked as completed.')),
//       );

//       // Open payment dialog
//       _showPaymentDialog(requestId);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   Future<void> _openMap(double latitude, double longitude) async {
//     final Uri url = Uri.parse(
//         'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
//     if (await launchUrl(url)) {
//       await launchUrl(url);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Could not open the map.')),
//       );
//     }
//   }

//   // Payment Dialog
//   void _showPaymentDialog(String requestId) {
//     final TextEditingController workCostController = TextEditingController();
//     double providerPrice = 0.0;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text("Complete Payment"),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: workCostController,
//                 decoration: const InputDecoration(
//                   labelText: 'Enter Work Cost',
//                 ),
//                 keyboardType: TextInputType.number,
//                 onChanged: (value) {
//                   setState(() {
//                     enteredAmount = double.tryParse(value);
//                   });
//                 },
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 'Total Cost: ₹${(enteredAmount ?? 0.0) + providerPrice}',
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text("Cancel"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 if (enteredAmount != null) {
//                   totalCost = (enteredAmount ?? 0.0) + providerPrice;
//                   // Update request with total cost
//                   await FirebaseFirestore.instance
//                       .collection('requests')
//                       .doc(requestId)
//                       .update({
//                     'total_cost': totalCost,
//                     'status': 'payment',
//                   });
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Payment Successful')),
//                   );
//                   Navigator.of(context).pop();
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                         content: Text('Please enter a valid amount')),
//                   );
//                 }
//               },
//               child: const Text('Pay Now'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     if (providerCategory == null) {
//       return const Scaffold(
//         body: Center(child: Text('Provider data not found.')),
//       );
//     }

//     final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Service Requests'),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: Column(
//         children: [
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16.0),
//             color: Colors.blueAccent.withOpacity(0.2),
//             child: Text(
//               'Service Category: $providerCategory',
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//                 color: Colors.black87,
//               ),
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('requests')
//                   .where('category_name', isEqualTo: providerCategory)
//                   .where(Filter.or(
//                     Filter('status', isEqualTo: 'pending'),
//                     Filter('accepted_by', isEqualTo: phoneNumber),
//                   ))
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return const Center(
//                       child: Text('No service requests available.'));
//                 }

//                 final filteredDocs = snapshot.data!.docs.where((doc) {
//                   final data = doc.data() as Map<String, dynamic>;
//                   final rejectedBy =
//                       data['rejected_by'] as List<dynamic>? ?? [];
//                   return !rejectedBy.contains(phoneNumber);
//                 }).toList();

//                 if (filteredDocs.isEmpty) {
//                   return const Center(
//                       child: Text('No pending requests available.'));
//                 }

//                 return ListView.builder(
//                   itemCount: filteredDocs.length,
//                   itemBuilder: (context, index) {
//                     var request = filteredDocs[index];
//                     var requestData = request.data() as Map<String, dynamic>;

//                     String requestStatus = requestData['status'];
//                     bool isAccepted = requestStatus == 'accepted';
//                     bool isRoute = requestStatus == 'route';
//                     double providerPrice = requestData['price'].toDouble();

//                     return Card(
//                       margin: const EdgeInsets.all(12.0),
//                       elevation: 4,
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text('Service: ${requestData['service_name']}'),
//                             Text('User: ${requestData['user_name']}'),
//                             Text('Phone: ${requestData['user_phone']}'),
//                             Text('Address: ${requestData['address']}'),
//                             Text(
//                                 'Building Name: ${requestData['building_name']}'),
//                             Text('Category: ${requestData['category_name']}'),
//                             Text('Status: $requestStatus'),
//                             const SizedBox(height: 10),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 ElevatedButton(
//                                   onPressed: isAccepted
//                                       ? null
//                                       : () => _acceptRequest(request.id),
//                                   style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.green),
//                                   child: const Text('Accept'),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 ElevatedButton(
//                                   onPressed: () => _rejectRequest(request.id),
//                                   style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.red),
//                                   child: const Text('Reject'),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 10),
//                             if (requestData['status'] == 'completed') ...[
//                               ElevatedButton(
//                                 onPressed: () => _completeRequest(request.id),
//                                 child: const Text('Complete Request'),
//                               ),
//                             ],
//                             if (requestData['status'] == 'route') ...[
//                               ElevatedButton(
//                                 onPressed: () => _routeRequest(request.id),
//                                 child: const Text('Route Request'),
//                               ),
//                             ],
//                             if (requestData['status'] == 'completed') ...[
//                               ElevatedButton(
//                                 onPressed: () => _openMap(
//                                   requestData['latitude'],
//                                   requestData['longitude'],
//                                 ),
//                                 child: const Text('View on Map'),
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:serviceprovider/screen/track_customer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProviderRequestPage extends StatefulWidget {
  const ProviderRequestPage({Key? key}) : super(key: key);

  @override
  _ProviderRequestPageState createState() => _ProviderRequestPageState();
}

class _ProviderRequestPageState extends State<ProviderRequestPage> {
  String? providerCategory;
  User? user;
  bool isLoading = true;
  double? enteredAmount;
  double totalCost = 0.0;

  @override
  void initState() {
    super.initState();
    _checkProviderLogin();
  }

  Future<void> _checkProviderLogin() async {
    user = FirebaseAuth.instance.currentUser;

    if (user == null || user!.phoneNumber == null) {
      _navigateToSignIn("Please log in to continue.");
      return;
    }

    final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

    try {
      final providerDoc = await FirebaseFirestore.instance
          .collection('provider')
          .doc(phoneNumber)
          .get();

      if (!providerDoc.exists) {
        _navigateToSignIn("No provider account found. Please register.");
        return;
      }

      setState(() {
        providerCategory = providerDoc['service_category'];
        isLoading = false;
      });

      _subscribeToFCM();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      _navigateToSignIn("An error occurred. Please try again.");
    }
  }

  void _subscribeToFCM() {
    FirebaseMessaging.instance.subscribeToTopic('providers');
  }

  void _navigateToSignIn(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.pushReplacementNamed(context, '/signin');
  }

  Future<void> _acceptRequest(String requestId) async {
    final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

    final requestRef =
        FirebaseFirestore.instance.collection('requests').doc(requestId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(requestRef);
        if (snapshot['status'] != 'pending') {
          throw Exception('Request already processed.');
        }
        transaction.update(requestRef, {
          'status': 'accepted',
          'accepted_by': phoneNumber,
          'provider_id': phoneNumber,
        });
      });

      Fluttertoast.showToast(
        msg: "Request marked as Accepeted.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: const Color.fromARGB(255, 2, 125, 248),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

 
  Future<void> _routeRequest(String requestId) async {
    // Ensure user is authenticated and has a phone number
    if (user == null || user!.phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User is not authenticated.')),
      );
      return;
    }

    // Get phone number and remove the country code (+91)
    final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');
    final requestRef =
        FirebaseFirestore.instance.collection('requests').doc(requestId);

    try {
      // Run transaction to update request status to 'route'
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(requestRef);

        if (!snapshot.exists) {
          throw Exception('Request not found.');
        }

        // Check if the request is already accepted
        if (snapshot['status'] != 'accepted') {
          throw Exception('Request is not accepted or already processed.');
        }

        // Update request status to 'route'
        transaction.update(requestRef, {
          'status': 'route',
          'accepted_by': phoneNumber,
          'provider_id': phoneNumber,
        });
      });

      // Fetch the updated request document from Firestore
      DocumentSnapshot updatedRequest = await requestRef.get();

      if (!updatedRequest.exists) {
        throw Exception('Updated request document not found.');
      }

      // Extract customer location data from Firestore
      var requestData = updatedRequest.data() as Map<String, dynamic>;

      if (requestData.containsKey('latitude') &&
          requestData.containsKey('longitude')) {
        double userLat = requestData['latitude'] ?? 0.0;
        double userLng = requestData['longitude'] ?? 0.0;

        // Check if the customer location is valid
        if (userLat == 0.0 || userLng == 0.0) {
          throw Exception('Invalid location coordinates.');
        }

        // Show a snack bar indicating that routing is in progress
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Routing the customer.')),
        );

        // Navigate to the CustomerTrackingPage, passing provider and customer locations
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapPage(
                requestId: requestId, // Use requestId instead of requestDocId
              ),
            ));
      } else {
        throw Exception('Missing latitude or longitude in Firestore data.');
      }
    } catch (e) {
      // Show any error that occurs during the process
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({
      'rejected_by': FieldValue.arrayUnion([phoneNumber]),
    });

    Fluttertoast.showToast(
      msg: "Request is Rejected.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: const Color.fromARGB(255, 2, 125, 248),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _completeRequest(String requestId) async {
    final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');
    final requestRef =
        FirebaseFirestore.instance.collection('requests').doc(requestId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(requestRef);

        if (!snapshot.exists) {
          throw Exception('Request not found.');
        }

        final requestData = snapshot.data() as Map<String, dynamic>;

        if (requestData['status'] == 'completed') {
          throw Exception('Request is already completed.');
        }

        if (requestData['accepted_by'] != phoneNumber) {
          throw Exception('You are not authorized to complete this request.');
        }

        transaction.update(requestRef, {
          'status': 'completed',
          'completed_at': FieldValue.serverTimestamp(),
          'total_cost': totalCost, // Store the total cost in the request
        });
      });
      Fluttertoast.showToast(
        msg: "Request marked as completed.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: const Color.fromARGB(255, 2, 125, 248),
        textColor: Colors.white,
        fontSize: 16.0,
      );
      _showPaymentDialog(requestId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _openMap(double latitude, double longitude) async {
    final Uri url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await launchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the map.')),
      );
    }
  }

  // Payment Dialog
  void _showPaymentDialog(String requestId) async {
    final TextEditingController workCostController = TextEditingController();
    double providerPrice = 0.0;

    final requestDoc = await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .get();

    if (requestDoc.exists && requestDoc.data() != null) {
      providerPrice = (requestDoc.data()!['price'] ?? 0).toDouble();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Complete Payment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: workCostController,
                decoration: const InputDecoration(
                  labelText: 'Enter Work Cost',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    // Ensure enteredAmount is always a valid number or default to 0.0
                    enteredAmount = double.tryParse(value) ?? 0.0;

                    // Calculate total cost dynamically
                    totalCost = enteredAmount! + providerPrice;
                  });
                },
              ),
              const SizedBox(height: 10),
              Text(
                'Total Cost: ₹${totalCost.toStringAsFixed(2)}', // Display total cost with 2 decimal places
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (enteredAmount != null) {
                  totalCost = enteredAmount! + providerPrice;
                  await FirebaseFirestore.instance
                      .collection('requests')
                      .doc(requestId)
                      .update({
                    'total_cost': totalCost,
                    'provider_cost': enteredAmount,
                    'status': 'payment',
                  });

                  Fluttertoast.showToast(
                    msg:
                        "Payment of ₹${totalCost.toStringAsFixed(2)} of Service!",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid amount')),
                  );
                }
              },
              child: const Text('Pay Now'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (providerCategory == null) {
      return const Scaffold(
        body: Center(child: Text('Provider data not found.')),
      );
    }

    final phoneNumber = user!.phoneNumber!.replaceFirst('+91', '');

    return Scaffold(
        appBar: AppBar(
          title: const Text('Service Requests'),
          backgroundColor: Colors.blueAccent,
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: Colors.blueAccent.withOpacity(0.2),
              child: Text(
                'Service Category: $providerCategory',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
                child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('requests')
                        .where('category_name', isEqualTo: providerCategory)
                        .where(Filter.or(
                          Filter('status', isEqualTo: 'pending'),
                          Filter('accepted_by', isEqualTo: phoneNumber),
                        ))
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('No service requests available.'));
                      }

                      final filteredDocs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final rejectedBy =
                            data['rejected_by'] as List<dynamic>? ?? [];
                        return !rejectedBy.contains(phoneNumber);
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return const Center(
                            child: Text('No pending requests available.'));
                      }

                      return ListView.builder(
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          var request = filteredDocs[index];
                          var requestData =
                              request.data() as Map<String, dynamic>;

                          String requestStatus = requestData['status'];

                          return Card(
                            margin: const EdgeInsets.all(12.0),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Service: ${requestData['service_name']}'),
                                  Text('User: ${requestData['user_name']}'),
                                  Text('Phone: ${requestData['user_phone']}'),
                                  Text('Address: ${requestData['address']}'),
                                  Text(
                                      'Building Name: ${requestData['building_name']}'),
                                  Text(
                                      'Category: ${requestData['category_name']}'),
                                  Text('Status: $requestStatus'),
                                  const SizedBox(height: 10),

                                  /// Buttons for **Pending Requests**
                                  if (requestStatus == 'pending') ...[
                                    ElevatedButton(
                                      onPressed: () =>
                                          _acceptRequest(request.id),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green),
                                      child: const Text('Accept'),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _rejectRequest(request.id),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red),
                                      child: const Text('Reject'),
                                    ),
                                  ],

                                  /// Buttons for **Accepted Requests**
                                  if (requestStatus == 'accepted') ...[
                                    ElevatedButton(
                                      onPressed: () =>
                                          _routeRequest(request.id),
                                      child: const Text('Route Request'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _openMap(
                                          requestData['latitude'],
                                          requestData['longitude'],
                                        );
                                      },
                                      child: const Text('View on Map'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _completeRequest(request.id),
                                      child: const Text('Complete Request'),
                                    ),
                                  ],

                                  /// Buttons for **Routed Requests**
                                  if (requestStatus == 'route') ...[
                                    ElevatedButton(
                                      onPressed: () =>
                                          _completeRequest(request.id),
                                      child: const Text('Complete Request'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _openMap(
                                          requestData['latitude'],
                                          requestData['longitude'],
                                        );
                                      },
                                      child: const Text('View on Map'),
                                    ),
                                  ],

                                  /// Buttons for **Completed Requests**
                                  if (requestStatus == 'completed') ...[
                                    ElevatedButton(
                                      onPressed: () =>
                                          _showPaymentDialog(request.id),
                                      child: const Text('Make Payment'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    })),
          ],
        ));
  }
}
