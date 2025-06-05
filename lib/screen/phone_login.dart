// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'otppage.dart';

// class PhoneLogin extends StatefulWidget {
//   const PhoneLogin({super.key});

//   @override
//   State<PhoneLogin> createState() => _PhoneLoginState();
// }

// class _PhoneLoginState extends State<PhoneLogin> {
//   TextEditingController phonenumber = TextEditingController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   bool isLoading = false;

//   /// Method to send OTP code
//   sendcode() async {
//     final phone = phonenumber.text.trim();
//     if (phone.isEmpty ||
//         phone.length != 10 ||
//         !RegExp(r'^[0-9]+$').hasMatch(phone)) {
//       Get.snackbar(
//           'Invalid Input', 'Please enter a valid 10-digit phone number.',
//           backgroundColor: Colors.red, colorText: Colors.white);
//       return;
//     }

//     setState(() {
//       isLoading = true;
//     });

//     try {
//       await FirebaseAuth.instance.verifyPhoneNumber(
//         phoneNumber: '+91$phone',
//         verificationCompleted: (PhoneAuthCredential credential) async {
//           UserCredential userCredential =
//               await FirebaseAuth.instance.signInWithCredential(credential);
//           print('User ID: ${userCredential.user?.uid}');
//           savePhoneNumberToFirestore(userCredential.user);
//         },
//         verificationFailed: (FirebaseAuthException e) {
//           Get.snackbar('Error occurred', e.code,
//               backgroundColor: Colors.red, colorText: Colors.white);
//         },
//         codeSent: (String vid, int? token) {
//           Get.to(
//               () => OtpPage(vid: vid, phoneNumber: phone, phonenumber: phone));
//         },
//         codeAutoRetrievalTimeout: (vid) {},
//       );
//     } catch (e) {
//       Get.snackbar('Error occurred', e.toString(),
//           backgroundColor: Colors.red, colorText: Colors.white);
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   /// Method to save phone number to Firestore in 'provider' collection
//   Future<void> savePhoneNumberToFirestore(User? user) async {
//     if (user == null) {
//       Get.snackbar('Error', 'User not found');
//       return;
//     }

//     try {
//       final String userId = user.uid;

//       await _firestore.collection('provider').doc(userId).set({
//         'phone_number': '+91${phonenumber.text}',
//       });

//       Get.snackbar('Success', 'Phone number saved to Firestore',
//           backgroundColor: Colors.green, colorText: Colors.white);
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to save phone number: $e',
//           backgroundColor: Colors.red, colorText: Colors.white);
//     }
//   }

//   /// UI Widget
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Login'),
//         backgroundColor: const Color.fromARGB(255, 71, 65, 245),
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFFDFDFD), Color(0xFF003CE0)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Text(
//                 "Welcome Service Provider",
//                 style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 10),
//               const Text("Login", style: TextStyle(fontSize: 16)),
//               const SizedBox(height: 40),
//               phonetext(),
//               const SizedBox(height: 50),
//               button(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// TextField for Phone Number
//   Widget phonetext() {
//     return TextField(
//       controller: phonenumber,
//       keyboardType: TextInputType.number,
//       decoration: InputDecoration(
//         filled: true,
//         fillColor: Colors.white,
//         prefixIcon: const Icon(Icons.phone, color: Colors.grey),
//         labelText: 'Phone Number',
//         hintText: 'e.g., 9876543210',
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10.0),
//         ),
//       ),
//     );
//   }

//   /// Button to trigger OTP process
//   Widget button() {
//     return isLoading
//         ? const CircularProgressIndicator(color: Colors.white)
//         : ElevatedButton(
//             onPressed: sendcode,
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 80),
//               backgroundColor: const Color.fromARGB(255, 41, 41, 216),
//             ),
//             child: const Text('Send OTP', style: TextStyle(fontSize: 18.0)),
//           );
//   }
// }

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'otppage.dart';

// class PhoneLogin extends StatefulWidget {
//   const PhoneLogin({super.key});

//   @override
//   State<PhoneLogin> createState() => _PhoneLoginState();
// }

// class _PhoneLoginState extends State<PhoneLogin> {
//   TextEditingController phonenumber = TextEditingController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   bool isLoading = false; // To track loading state

//   /// Method to send OTP code
//   sendcode() async {
//     final phone = phonenumber.text.trim();
//     if (phone.isEmpty ||
//         phone.length != 10 ||
//         !RegExp(r'^[0-9]+$').hasMatch(phone)) {
//       Get.snackbar(
//           'Invalid Input', 'Please enter a valid 10-digit phone number.',
//           backgroundColor: Colors.red, colorText: Colors.white);
//       return;
//     }

//     setState(() {
//       isLoading = true; // Start loading
//     });

//     try {
//       await FirebaseAuth.instance.verifyPhoneNumber(
//         phoneNumber: '+91$phone',
//         verificationCompleted: (PhoneAuthCredential credential) async {
//           UserCredential userCredential =
//               await FirebaseAuth.instance.signInWithCredential(credential);
//           print('User ID: ${userCredential.user?.uid}');
//           savePhoneNumberToFirestore(userCredential.user);
//         },
//         verificationFailed: (FirebaseAuthException e) {
//           Get.snackbar('Error occurred', e.code,
//               backgroundColor: Colors.red, colorText: Colors.white);
//         },
//         codeSent: (String vid, int? token) {
//           Get.to(
//             () => OtpPage(
//               vid: vid,
//               phoneNumber: phone,
//               phonenumber: phone, // Pass phone number for OTP page
//             ),
//           );
//         },
//         codeAutoRetrievalTimeout: (vid) {},
//       );
//     } on FirebaseAuthException catch (e) {
//       Get.snackbar('Error occurred', e.code,
//           backgroundColor: Colors.red, colorText: Colors.white);
//     } catch (e) {
//       Get.snackbar('Error occurred', e.toString(),
//           backgroundColor: Colors.red, colorText: Colors.white);
//     } finally {
//       setState(() {
//         isLoading = false; // Stop loading
//       });
//     }
//   }

//   /// Method to save phone number to Firestore
//   Future<void> savePhoneNumberToFirestore(User? user) async {
//     if (user == null) {
//       Get.snackbar('Error', 'User not found');
//       return;
//     }

//     try {
//       final String userId = user.uid;

//       await _firestore.collection('users').doc(userId).set({
//         'phone_number': '+91${phonenumber.text}',
//       });

//       Get.snackbar('Success', 'Phone number saved to Firestore',
//           backgroundColor: Colors.green, colorText: Colors.white);
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to save phone number: $e',
//           backgroundColor: const Color.fromARGB(255, 203, 14, 0),
//           colorText: Colors.white);
//     }
//   }

//   /// UI Widget
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Login'),
//         backgroundColor: const Color.fromARGB(255, 71, 65, 245),
//         elevation: 0, // Optional: remove elevation for a flat look
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Color.fromARGB(255, 253, 253, 253),
//               Color.fromARGB(255, 0, 60, 224)
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         width: double.infinity, // Make the container take up full width
//         height: double.infinity, // Make the container take up full height
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               const SizedBox(height: 40),
//               const Text(
//                 "Welcome Service Provider",
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: Color.fromARGB(255, 0, 0, 0),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               const Text(
//                 "Login",
//                 style: TextStyle(
//                     fontSize: 16, color: Color.fromARGB(179, 2, 2, 2)),
//               ),
//               const SizedBox(height: 40),
//               phonetext(),
//               const SizedBox(height: 50),
//               button(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// TextField for Phone Number
//   Widget phonetext() {
//     return TextField(
//       controller: phonenumber,
//       keyboardType: TextInputType.number,
//       decoration: InputDecoration(
//         filled: true,
//         fillColor: Colors.white,
//         prefixIcon: const Icon(
//           Icons.phone,
//           color: Color.fromARGB(255, 73, 73, 73),
//         ),
//         labelText: 'Phone Number',
//         labelStyle: const TextStyle(color: Color.fromARGB(255, 41, 41, 216)),
//         hintText: 'e.g., 9876543210',
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10.0),
//           borderSide: const BorderSide(
//               color: Color.fromARGB(255, 41, 41, 216), width: 1.5),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10.0),
//           borderSide: const BorderSide(
//               color: Color.fromARGB(255, 41, 41, 216), width: 2.0),
//         ),
//       ),
//     );
//   }

//   /// Button to trigger OTP process
//   Widget button() {
//     return Center(
//       child: isLoading
//           ? const CircularProgressIndicator(color: Colors.white)
//           : ElevatedButton(
//               onPressed: () {
//                 sendcode();
//               },
//               style: ElevatedButton.styleFrom(
//                 padding:
//                     const EdgeInsets.symmetric(vertical: 12, horizontal: 80),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10.0),
//                 ),
//                 backgroundColor: const Color.fromARGB(255, 41, 41, 216),
//               ),
//               child: const Text(
//                 'Send OTP',
//                 style: TextStyle(fontSize: 18.0, color: Colors.white),
//               ),
//             ),
//     );
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'otppage.dart';

class PhoneLogin extends StatefulWidget {
  const PhoneLogin({super.key});

  @override
  State<PhoneLogin> createState() => _PhoneLoginState();
}

class _PhoneLoginState extends State<PhoneLogin> {
  TextEditingController phonenumber = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  /// Method to send OTP code
  sendcode() async {
    final phone = phonenumber.text.trim();
    if (phone.isEmpty ||
        phone.length != 10 ||
        !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      Get.snackbar(
          'Invalid Input', 'Please enter a valid 10-digit phone number.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        verificationCompleted: (PhoneAuthCredential credential) async {
          UserCredential userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          savePhoneNumberToFirestore(userCredential.user);
        },
        verificationFailed: (FirebaseAuthException e) {
          Get.snackbar('Error occurred', e.code,
              backgroundColor: Colors.red, colorText: Colors.white);
        },
        codeSent: (String vid, int? token) {
          Get.to(() => OtpPage(vid: vid, phoneNumber: phone, phonenumber: ''));
        },
        codeAutoRetrievalTimeout: (vid) {},
      );
    } catch (e) {
      Get.snackbar('Error occurred', e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Method to save phone number to Firestore
  Future<void> savePhoneNumberToFirestore(User? user) async {
    if (user == null) {
      Get.snackbar('Error', 'User not found');
      return;
    }

    try {
      final String userId = user.uid;
      await _firestore.collection('users').doc(userId).set({
        'phone_number': '+91${phonenumber.text}',
      });
      Get.snackbar('Success', 'Phone number saved to Firestore',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to save phone number: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// UI Widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('fleeso',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              const Text('Create new account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {},
                child: const Text('Have an account? Login',
                    style: TextStyle(color: Colors.blue)),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey),
                ),
                child: Row(
                  children: [
                    const Text('🇮🇳 +91', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: phonenumber,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Enter your phone number',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : sendcode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Continue',
                        style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {},
                child: const Text('Signup with email',
                    style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'otppage.dart';
// import 'wrapper.dart';

// class PhoneLogin extends StatefulWidget {
//   const PhoneLogin({super.key});

//   @override
//   State<PhoneLogin> createState() => _PhoneLoginState();
// }

// class _PhoneLoginState extends State<PhoneLogin> {
//   TextEditingController phonenumber = TextEditingController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   bool isLoading = false;

//   /// Method to send OTP code
//   sendcode() async {
//     final phone = phonenumber.text.trim();
//     if (phone.isEmpty ||
//         phone.length != 10 ||
//         !RegExp(r'^[0-9]+$').hasMatch(phone)) {
//       Get.snackbar(
//           'Invalid Input', 'Please enter a valid 10-digit phone number.',
//           backgroundColor: Colors.red, colorText: Colors.white);
//       return;
//     }

//     setState(() => isLoading = true);

//     try {
//       await FirebaseAuth.instance.verifyPhoneNumber(
//         phoneNumber: '+91$phone',
//         verificationCompleted: (PhoneAuthCredential credential) async {
//           UserCredential userCredential =
//               await FirebaseAuth.instance.signInWithCredential(credential);
//           await savePhoneNumberToFirestore(userCredential.user);
//           Get.offAll(() => Wrapper());
//         },
//         verificationFailed: (FirebaseAuthException e) {
//           print("Verification failed: ${e.message}");
//           Get.snackbar(
//               'Error occurred', e.message ?? 'An unknown error occurred',
//               backgroundColor: Colors.red, colorText: Colors.white);
//         },
//         codeSent: (String vid, int? token) {
//           print("Code sent. Verification ID: $vid");
//           Get.to(
//               () => OtpPage(vid: vid, phoneNumber: phone, phonenumber: phone));
//         },
//         codeAutoRetrievalTimeout: (String vid) {
//           print("Auto-retrieval timed out for verification ID: $vid");
//         },
//       );
//     } catch (e) {
//       print("Error during verification: $e");
//       Get.snackbar('Error occurred', e.toString(),
//           backgroundColor: Colors.red, colorText: Colors.white);
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   /// Method to save phone number to Firestore
//   Future<void> savePhoneNumberToFirestore(User? user) async {
//     if (user == null) {
//       Get.snackbar('Error', 'User not found');
//       return;
//     }

//     try {
//       await _firestore.collection('users').doc(user.uid).set({
//         'phone_number': '+91${phonenumber.text}',
//       });
//       Get.snackbar('Success', 'Phone number saved to Firestore',
//           backgroundColor: Colors.green, colorText: Colors.white);
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to save phone number: $e',
//           backgroundColor: Colors.red, colorText: Colors.white);
//     }
//   }

//   /// UI Widget
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[200],
//       body: Center(
//         child: Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: const [
//               BoxShadow(
//                 color: Colors.black12,
//                 blurRadius: 10,
//                 spreadRadius: 5,
//               ),
//             ],
//           ),
//           width: 350,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text('Service Provider',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
//               const SizedBox(height: 10),
//               const Text('Create new account',
//                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//               TextButton(
//                 onPressed: () {},
//                 child: const Text('Have an account? Login',
//                     style: TextStyle(color: Colors.blue)),
//               ),
//               const SizedBox(height: 20),
//               Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(color: Colors.grey),
//                 ),
//                 child: Row(
//                   children: [
//                     const Text('🇮🇳 +91', style: TextStyle(fontSize: 16)),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: TextField(
//                         controller: phonenumber,
//                         keyboardType: TextInputType.phone,
//                         decoration: const InputDecoration(
//                           hintText: 'Enter your phone number',
//                           border: InputBorder.none,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: isLoading ? null : sendcode,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10)),
//                   minimumSize: const Size(double.infinity, 50),
//                 ),
//                 child: isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : const Text('Continue',
//                         style: TextStyle(color: Colors.white)),
//               ),
//               const SizedBox(height: 10),
//               TextButton(
//                 onPressed: () {},
//                 child: const Text('Signup with email',
//                     style: TextStyle(color: Colors.grey)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
