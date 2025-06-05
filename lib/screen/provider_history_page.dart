// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class ProviderHistoryPage extends StatefulWidget {
//   const ProviderHistoryPage({super.key});

//   @override
//   _ProviderHistoryPageState createState() => _ProviderHistoryPageState();
// }

// class _ProviderHistoryPageState extends State<ProviderHistoryPage> {
//   User? user;
//   String? providerId;

//   @override
//   void initState() {
//     super.initState();
//     user = FirebaseAuth.instance.currentUser;
//     providerId = user?.phoneNumber?.replaceAll('+91', '');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Service History'),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: providerId == null
//           ? const Center(child: Text('Unable to fetch provider data.'))
//           : StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('requests')
//                   .where('provider_id', isEqualTo: providerId)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return const Center(
//                       child: Text('No service history available.'));
//                 }

//                 var requests = snapshot.data!.docs;

//                 return ListView.builder(
//                   itemCount: requests.length,
//                   itemBuilder: (context, index) {
//                     var request =
//                         requests[index].data() as Map<String, dynamic>;

//                     return Card(
//                       margin: const EdgeInsets.all(12.0),
//                       elevation: 4,
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text('Service: ${request['service_name']}',
//                                 style: const TextStyle(
//                                     fontWeight: FontWeight.bold, fontSize: 18)),
//                             Text('User: ${request['user_name']}'),
//                             Text('Phone: ${request['user_phone']}'),
//                             Text('Address: ${request['address']}'),
//                             Text('Building: ${request['building_name']}'),
//                             Text(
//                               'Status: ${request['status']}',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 color: _getStatusColor(request['status']),
//                               ),
//                             ),
//                             Text(
//                               'Timestamp: ${request['timestamp'].toDate()}',
//                               style: const TextStyle(color: Colors.grey),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }

//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'pending':
//         return Colors.orange;
//       case 'accepted':
//         return Colors.green;
//       case 'completed':
//         return Colors.blue;
//       case 'rejected':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProviderHistoryPage extends StatefulWidget {
  const ProviderHistoryPage({super.key});

  @override
  _ProviderHistoryPageState createState() => _ProviderHistoryPageState();
}

class _ProviderHistoryPageState extends State<ProviderHistoryPage> {
  User? user;
  String? providerId;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    providerId = user?.phoneNumber?.replaceAll('+91', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service History'),
        backgroundColor: Colors.blueAccent,
      ),
      body: providerId == null
          ? const Center(child: Text('Unable to fetch provider data.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('provider_id', isEqualTo: providerId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No service history available.'));
                }

                var requests = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    var request =
                        requests[index].data() as Map<String, dynamic>;

                    bool isRejectedByProvider = request['rejected_by'] !=
                            null &&
                        (request['rejected_by'] as List).contains(providerId);

                    return Card(
                      margin: const EdgeInsets.all(12.0),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Service: ${request['service_name']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            Text('User: ${request['user_name']}'),
                            Text('Phone: ${request['user_phone']}'),
                            Text('Address: ${request['address']}'),
                            Text('Building: ${request['building_name']}'),
                            Text(
                              'Status: ${request['status']} ${isRejectedByProvider ? '(Rejected by you)' : ''}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(request['status']),
                              ),
                            ),
                            Text(
                              'Timestamp: ${request['timestamp'].toDate()}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
