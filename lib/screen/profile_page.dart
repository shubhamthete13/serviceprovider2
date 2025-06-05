// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class ProfilePage extends StatefulWidget {
//   final String? location;
//   final String? status;
//   final String? fcmToken;

//   const ProfilePage({
//     Key? key,
//     this.location,
//     this.status,
//     this.fcmToken,
//   }) : super(key: key);

//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {
//   final user = FirebaseAuth.instance.currentUser;

//   bool _isEditing = false; // State to track if fields are editable
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _serviceCategoryController =
//       TextEditingController();
//   final TextEditingController _genderController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _fetchUserData(); // Fetch user data from Firestore
//   }

//   // Fetch user data from Firestore
//   Future<void> _fetchUserData() async {
//     if (user?.phoneNumber == null) return;

//     final phone_number = user!.phoneNumber!.startsWith('+91')
//         ? user!.phoneNumber!.substring(3)
//         : user!.phoneNumber;

//     final userDoc = await FirebaseFirestore.instance
//         .collection('provider')
//         .doc(phone_number) // Using phone_number as the document ID
//         .get();

//     if (userDoc.exists) {
//       final data = userDoc.data();
//       if (data != null) {
//         setState(() {
//           _nameController.text = data['name'] ?? '';
//           _serviceCategoryController.text = data['service_category'] ?? '';
//           _genderController.text = data['gender'] ?? '';
//         });
//       }
//     }
//   }

//   // Update user data in Firestore
//   Future<void> _updateUserData() async {
//     if (user?.phoneNumber == null) return;

//     final phone_number = user!.phoneNumber!.startsWith('+91')
//         ? user!.phoneNumber!.substring(3)
//         : user!.phoneNumber;

//     final data = {
//       'name': _nameController.text.trim(),
//       'gender': _genderController.text.trim(),
//     };

//     await FirebaseFirestore.instance
//         .collection('provider')
//         .doc(phone_number) // Using phone_number as the document ID
//         .set(data, SetOptions(merge: true))
//         .then((_) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Profile updated successfully!')),
//       );
//     }).catchError((error) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to update profile: $error')),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Profile"),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             onPressed: () async {
//               await FirebaseAuth.instance.signOut();
//               Navigator.of(context).popUntil((route) => route.isFirst);
//             },
//             icon: const Icon(Icons.logout),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               const SizedBox(height: 30),
//               // Profile Picture
//               CircleAvatar(
//                 radius: 60,
//                 backgroundImage:
//                     const AssetImage("assets/images/dummy_profile.png"),
//                 backgroundColor: Colors.grey[200],
//               ),
//               const SizedBox(height: 10),
//               // Mobile Number
//               Text(
//                 user?.phoneNumber ?? "Not Linked",
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.black,
//                 ),
//               ),
//               if (user?.phoneNumber == null)
//                 const Padding(
//                   padding: EdgeInsets.only(top: 8.0),
//                   child: Text(
//                     "Your phone number is not linked to your account.",
//                     style: TextStyle(color: Colors.red, fontSize: 14),
//                   ),
//                 ),
//               const SizedBox(height: 20),
//               // Name Field
//               TextField(
//                 controller: _nameController,
//                 enabled: _isEditing,
//                 decoration: const InputDecoration(
//                   labelText: "Name",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               // Service Category (Disabled)
//               TextField(
//                 controller: _serviceCategoryController,
//                 enabled: false, // Service category is not editable
//                 decoration: const InputDecoration(
//                   labelText: "Service Category",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               // Gender Field
//               TextField(
//                 controller: _genderController,
//                 enabled: _isEditing,
//                 decoration: const InputDecoration(
//                   labelText: "Gender",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 40),
//               // Save and Cancel Buttons (Visible when editing)
//               if (_isEditing)
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     ElevatedButton(
//                       onPressed: () {
//                         setState(() {
//                           _isEditing =
//                               false; // Save changes and disable editing
//                         });
//                         _updateUserData(); // Save data to Firestore
//                       },
//                       child: const Text("Save"),
//                     ),
//                     OutlinedButton(
//                       onPressed: () {
//                         setState(() {
//                           _isEditing = false;
//                           _fetchUserData(); // Re-fetch data from Firestore
//                         });
//                       },
//                       child: const Text("Cancel"),
//                     ),
//                   ],
//                 ),
//               // Edit Button (Visible when not editing)
//               if (!_isEditing)
//                 ElevatedButton(
//                   onPressed: () {
//                     setState(() {
//                       _isEditing = true; // Enable editing
//                     });
//                   },
//                   child: const Text("Edit Profile"),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final String? location;
  final String? status;
  final String? fcmToken;

  const ProfilePage({
    Key? key,
    this.location,
    this.status,
    this.fcmToken,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;

  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _serviceCategoryController =
      TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user?.phoneNumber == null) return;

    final phone_number = user!.phoneNumber!.startsWith('+91')
        ? user!.phoneNumber!.substring(3)
        : user!.phoneNumber;

    final userDoc = await FirebaseFirestore.instance
        .collection('provider')
        .doc(phone_number)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null) {
        setState(() {
          _nameController.text = data['name'] ?? '';
          _serviceCategoryController.text = data['service_category'] ?? '';
          _genderController.text = data['gender'] ?? '';
        });
      }
    }
  }

  Future<void> _updateUserData() async {
    if (user?.phoneNumber == null) return;

    final phone_number = user!.phoneNumber!.startsWith('+91')
        ? user!.phoneNumber!.substring(3)
        : user!.phoneNumber;

    final data = {
      'name': _nameController.text.trim(),
      'gender': _genderController.text.trim(),
    };

    await FirebaseFirestore.instance
        .collection('provider')
        .doc(phone_number)
        .set(data, SetOptions(merge: true))
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(
            fontSize: 24, // Change font size
            fontWeight: FontWeight.bold, // Apply bold font
            color: Color.fromARGB(255, 0, 0, 0), // Set font color
            fontFamily: 'Roboto', // Use a custom font
            letterSpacing: 1.5, // Adjust spacing between letters
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 226, 228, 230),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: const AssetImage(
                    "assets/img/bc9fd4bd-de9b-4555-976c-8360576c6708.jpg"),
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(height: 10),
              Text(
                user?.phoneNumber ?? "Not Linked",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildTextField("Name", _nameController, _isEditing),
                      const SizedBox(height: 20),
                      _buildTextField("Service Category",
                          _serviceCategoryController, false),
                      const SizedBox(height: 20),
                      _buildTextField("Gender", _genderController, _isEditing),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (_isEditing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _isEditing = false);
                        _updateUserData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: const Text("Save"),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        setState(() => _isEditing = false);
                        _fetchUserData();
                      },
                      child: const Text("Cancel"),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: () => setState(() => _isEditing = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text("Edit Profile"),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, bool enabled) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }
}
