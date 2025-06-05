// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

// class ReviewPage extends StatefulWidget {
//   final String providerId;

//   const ReviewPage({Key? key, required this.providerId}) : super(key: key);

//   @override
//   State<ReviewPage> createState() => _ReviewPageState();
// }

// class _ReviewPageState extends State<ReviewPage> {
//   List<Map<String, dynamic>> reviews = [];
//   String? currentUserId;

//   @override
//   void initState() {
//     super.initState();
//     _checkCurrentUser();
//     fetchReviews();
//   }

//   // Check the currently logged-in user
//   void _checkCurrentUser() {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       setState(() {
//         currentUserId = user.uid;
//       });
//     } else {
//       print('No user is logged in.');
//     }
//   }

//   Future<void> fetchReviews() async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('reviews')
//           .where('provider_id', isEqualTo: widget.providerId)
//           .get();

//       if (querySnapshot.docs.isNotEmpty) {
//         setState(() {
//           reviews = querySnapshot.docs
//               .map((doc) => doc.data() as Map<String, dynamic>)
//               .toList();
//         });
//       }
//     } catch (e) {
//       print('Error fetching reviews: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Reviews'),
//         centerTitle: true,
//         backgroundColor: Colors.blue,
//       ),
//       body: reviews.isEmpty
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//               itemCount: reviews.length,
//               itemBuilder: (context, index) {
//                 final review = reviews[index];
//                 final isCurrentUserReview =
//                     currentUserId == review['request_id'];

//                 return Card(
//                   margin:
//                       const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                   elevation: 5,
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Rating: ${review['rating']?.toString() ?? 'N/A'} ⭐',
//                           style: const TextStyle(
//                               fontSize: 18, fontWeight: FontWeight.bold),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Review: ${review['review'] ?? 'No review available'}',
//                           style: const TextStyle(fontSize: 16),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Request ID: ${review['request_id'] ?? 'N/A'}',
//                           style:
//                               const TextStyle(fontSize: 14, color: Colors.grey),
//                         ),
//                         // Display additional message if the review is by the current user
//                         if (isCurrentUserReview) const SizedBox(height: 8),
//                         Text(
//                           'This is your review.',
//                           style: const TextStyle(
//                               fontSize: 14, color: Colors.green),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
// import 'package:intl/intl.dart'; // For formatting the timestamp

// class ReviewPage extends StatefulWidget {
//   final String providerId;

//   const ReviewPage({Key? key, required this.providerId}) : super(key: key);

//   @override
//   State<ReviewPage> createState() => _ReviewPageState();
// }

// class _ReviewPageState extends State<ReviewPage> {
//   List<Map<String, dynamic>> reviews = [];
//   String? currentUserId;

//   @override
//   void initState() {
//     super.initState();
//     _checkCurrentUser();
//     fetchReviews();
//   }

//   // Check the currently logged-in user
//   void _checkCurrentUser() {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       setState(() {
//         currentUserId = user.uid;
//       });
//     } else {
//       print('No user is logged in.');
//     }
//   }

//   Future<void> fetchReviews() async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('reviews')
//           .where('provider_id', isEqualTo: widget.providerId)
//           .get();

//       if (querySnapshot.docs.isNotEmpty) {
//         setState(() {
//           reviews = querySnapshot.docs
//               .map((doc) => doc.data() as Map<String, dynamic>)
//               .toList();
//         });
//       }
//     } catch (e) {
//       print('Error fetching reviews: $e');
//     }
//   }

//   String _formatTimestamp(Timestamp timestamp) {
//     // Format the timestamp into a readable date format
//     DateTime dateTime = timestamp.toDate();
//     return DateFormat('d MMMM yyyy HH:mm:ss').format(dateTime);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Reviews'),
//         centerTitle: true,
//         backgroundColor: Colors.blue,
//       ),
//       body: reviews.isEmpty
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//               itemCount: reviews.length,
//               itemBuilder: (context, index) {
//                 final review = reviews[index];
//                 final isCurrentUserReview =
//                     currentUserId == review['request_id'];

//                 return Card(
//                   margin:
//                       const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                   elevation: 5,
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Rating: ${review['rating']?.toString() ?? 'N/A'} ⭐',
//                           style: const TextStyle(
//                               fontSize: 18, fontWeight: FontWeight.bold),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Review: ${review['review'] ?? 'No review available'}',
//                           style: const TextStyle(fontSize: 16),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Request ID: ${review['request_id'] ?? 'N/A'}',
//                           style:
//                               const TextStyle(fontSize: 14, color: Colors.grey),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Provider ID: ${review['provider_id'] ?? 'N/A'}',
//                           style:
//                               const TextStyle(fontSize: 14, color: Colors.grey),
//                         ),
//                         const SizedBox(height: 8),
//                         // Format the timestamp and display it
//                         Text(
//                           'Timestamp: ${_formatTimestamp(review['timestamp'])}',
//                           style:
//                               const TextStyle(fontSize: 14, color: Colors.grey),
//                         ),
//                         // Display additional message if the review is by the current user
//                         if (isCurrentUserReview) const SizedBox(height: 8),
//                         Text(
//                           'This is your review.',
//                           style: const TextStyle(
//                               fontSize: 14, color: Colors.green),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
// import 'package:intl/intl.dart'; // For formatting the timestamp

// class ReviewPage extends StatefulWidget {
//   final String providerId;

//   const ReviewPage({Key? key, required this.providerId}) : super(key: key);

//   @override
//   State<ReviewPage> createState() => _ReviewPageState();
// }

// class _ReviewPageState extends State<ReviewPage> {
//   List<Map<String, dynamic>> reviews = [];
//   String? currentProviderId;

//   @override
//   void initState() {
//     super.initState();
//     _checkCurrentProvider();
//     fetchReviews();
//   }

//   // Check the currently logged-in provider by querying the provider collection
//   Future<void> _checkCurrentProvider() async {
//     try {
//       final providerSnapshot = await FirebaseFirestore.instance
//           .collection(
//               'provider') // Assuming you have a collection called 'providers'
//           .doc(widget.providerId) // Use the providerId passed to the page
//           .get();

//       if (providerSnapshot.exists) {
//         setState(() {
//           currentProviderId =
//               widget.providerId; // If provider exists, it's logged in
//         });
//       } else {
//         print('Provider is not logged in.');
//       }
//     } catch (e) {
//       print('Error checking provider: $e');
//     }
//   }

//   // Fetch reviews based on providerId
//   Future<void> fetchReviews() async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('reviews')
//           .where('provider_id',
//               isEqualTo: widget.providerId) // Filter by provider_id
//           .get();

//       if (querySnapshot.docs.isNotEmpty) {
//         setState(() {
//           reviews = querySnapshot.docs
//               .map((doc) => doc.data() as Map<String, dynamic>)
//               .toList();
//         });
//       } else {
//         print('No reviews found for this provider.');
//       }
//     } catch (e) {
//       print('Error fetching reviews: $e');
//     }
//   }

//   // Format timestamp
//   String _formatTimestamp(Timestamp timestamp) {
//     DateTime dateTime = timestamp.toDate();
//     return DateFormat('d MMMM yyyy HH:mm:ss').format(dateTime);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Reviews'),
//         centerTitle: true,
//         backgroundColor: Colors.blue,
//       ),
//       body: currentProviderId == null
//           ? const Center(
//               child:
//                   CircularProgressIndicator()) // Wait until the provider check is done
//           : reviews.isEmpty
//               ? const Center(child: Text('No reviews found for this provider.'))
//               : ListView.builder(
//                   itemCount: reviews.length,
//                   itemBuilder: (context, index) {
//                     final review = reviews[index];

//                     return Card(
//                       margin: const EdgeInsets.symmetric(
//                           vertical: 8, horizontal: 16),
//                       elevation: 5,
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Rating: ${review['rating']?.toString() ?? 'N/A'} ⭐',
//                               style: const TextStyle(
//                                   fontSize: 18, fontWeight: FontWeight.bold),
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               'Review: ${review['review'] ?? 'No review available'}',
//                               style: const TextStyle(fontSize: 16),
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               'Request ID: ${review['request_id'] ?? 'N/A'}',
//                               style: const TextStyle(
//                                   fontSize: 14, color: Colors.grey),
//                             ),
//                             const SizedBox(height: 8),
//                             // Format the timestamp and display it
//                             Text(
//                               'Timestamp: ${_formatTimestamp(review['timestamp'])}',
//                               style: const TextStyle(
//                                   fontSize: 14, color: Colors.grey),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReviewPage extends StatefulWidget {
  final String providerId;

  const ReviewPage({Key? key, required this.providerId}) : super(key: key);

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  List<Map<String, dynamic>> reviews = [];
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  // Check if the provider is authenticated
  void _checkAuthentication() {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("No user is authenticated.");
    } else {
      print("Authenticated as: ${currentUser!.uid}");
      fetchReviews();
    }
  }

  // Fetch reviews from Firestore for the provider
  Future<void> fetchReviews() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('provider_id', isEqualTo: widget.providerId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          reviews = querySnapshot.docs.map((doc) => doc.data()).toList();
        });
        print("Reviews fetched successfully: ${reviews.length}");
      } else {
        print("No reviews found for this provider.");
      }
    } catch (e) {
      print("Error fetching reviews: $e");
    }
  }

  // Format timestamp safely
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      DateTime dateTime = timestamp.toDate();
      return DateFormat('d MMMM yyyy HH:mm:ss').format(dateTime);
    }
    return "N/A";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: currentUser == null
          ? const Center(
              child: Text('User not authenticated. Please log in.'),
            )
          : reviews.isEmpty
              ? const Center(child: Text('No reviews found for this provider.'))
              : ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rating: ${review['rating']?.toString() ?? 'N/A'} ⭐',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Review: ${review['review']?.isNotEmpty == true ? review['review'] : 'No review available'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Request ID: ${review['request_id'] ?? 'N/A'}',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Timestamp: ${_formatTimestamp(review['timestamp'])}',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
