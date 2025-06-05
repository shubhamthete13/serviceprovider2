import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // For FCM Token
import 'package:serviceprovider/screen/wrapper.dart';

class OtpPage extends StatefulWidget {
  final String vid;
  final String phoneNumber;

  const OtpPage(
      {super.key,
      required this.vid,
      required this.phoneNumber,
      required String phonenumber});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  var code = '';
  bool isLoading = false;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Method to verify OTP and sign in user
  signIn() async {
    setState(() {
      isLoading = true; // Show loader
    });
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: widget.vid,
      smsCode: code,
    );
    try {
      await FirebaseAuth.instance
          .signInWithCredential(credential)
          .then((value) async {
        await _checkAndAddUserData(widget.phoneNumber);
        String fcmToken = await _getFCMToken(); // Get FCM Token
        await _saveFCMToken(widget.phoneNumber, fcmToken); // Save FCM Token
        Get.offAll(() => Wrapper());
      });
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Error occurred',
        e.code,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Sign-in Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        isLoading = false; // Hide loader
      });
    }
  }

  // Method to check and add user data in Firestore if it doesn't exist
  Future<void> _checkAndAddUserData(String phoneNumber) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('provider')
          .doc(phoneNumber)
          .get();

      if (!userDoc.exists) {
        FirebaseFirestore.instance.collection('provider').doc(phoneNumber).set({
          'phone_number': phoneNumber,
          'name': '',
          'gender': '',
          'fcmToken': '',
          'latitude': '',
          'longitude': '',
        });
      }
    } catch (e) {
      print("Error checking or adding user data: $e");
    }
  }

  // Method to retrieve FCM Token
  Future<String> _getFCMToken() async {
    String? fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      return fcmToken;
    } else {
      throw Exception("Failed to get FCM Token");
    }
  }

  // Method to save FCM token in Firestore
  Future<void> _saveFCMToken(String phoneNumber, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('provider')
          .doc(phoneNumber)
          .update({
        'fcmToken': token,
      });
      print("FCM Token saved successfully.");
    } catch (e) {
      print("Error saving FCM Token: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Icon(
                  Icons.security,
                  size: 80,
                  color: const Color.from(
                      alpha: 1, red: 0.267, green: 0.541, blue: 1),
                ),
                const SizedBox(height: 20),
                Text(
                  "OTP Verification",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Enter the OTP sent to ${widget.phoneNumber}",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                _textCodeInput(),
                const SizedBox(height: 60),
                _verifyButton(),
              ],
            ),
          ),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _verifyButton() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(3, 100, 255, 1),
              Colors.blueAccent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : () => signIn(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.all(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80),
            child: Text(
              'Verify & Proceed',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textCodeInput() {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: TextStyle(
        fontSize: 20,
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueAccent),
      ),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Pinput(
          length: 6,
          autofocus: true, // Autofill will work if SMS permissions are granted
          onChanged: (value) {
            setState(() {
              code = value;
            });
          },
          defaultPinTheme: defaultPinTheme,
          onSubmitted: (value) => signIn(),
        ),
      ),
    );
  }
}
