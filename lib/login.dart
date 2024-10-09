import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musict/admin_home.dart';
import 'main1.dart'; // Ensure this path matches your actual file structure

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginPageState();
}

class _LoginPageState extends State<Login> {
  TextEditingController user = TextEditingController();
  TextEditingController pass = TextEditingController();
  // Add a controller for full name if needed
  TextEditingController fullNameController = TextEditingController();

Future<void> login() async {
  try {
    // Attempt to sign in the user with Firebase
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: user.text.trim(),
      password: pass.text.trim(),
    );

    // Retrieve user UID
    String uid = userCredential.user!.uid;

    // Fetch user data from Firestore
    var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userDoc.exists) {
      String userRole = userDoc.data()?['roll'] ?? 'user'; // Default to 'user' if role is not set

      // Navigate based on role
      if (userRole == 'admin') {
        Fluttertoast.showToast(
          msg: 'Login Successful - Admin',
          backgroundColor: Colors.green,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_SHORT,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Adminhome(), // Replace with your actual admin home screen
          ),
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Login Successful',
          backgroundColor: Colors.green,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_SHORT,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MyApp1(), // Replace with your actual user home screen
          ),
        );
      }
    } else {
      // Handle case where user document does not exist
      Fluttertoast.showToast(
        msg: 'User role not found',
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  } on FirebaseAuthException catch (e) {
    String errorMessage = 'An error occurred';

    // Handle specific error cases
    if (e.code == 'wrong-password') {
      errorMessage = 'Incorrect password';
    } else if (e.code == 'invalid-email') {
      errorMessage = 'Invalid email format';
    }

    // Show error message as a toast
    Fluttertoast.showToast(
      msg: errorMessage,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_SHORT,
    );
  } catch (e) {
    // Handle any other error
    Fluttertoast.showToast(
      msg: 'An unknown error occurred',
      backgroundColor: Colors.red,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_SHORT,
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Text(
          "Welcome to the music application",
          style: TextStyle(
            fontSize: 30,
            color: Color(0xFF1C1C1C),
            height: 2,
          ),
        ),
        // Use the defined controller for the name if needed
       
        TextField(
          style: const TextStyle(color: Colors.white),
          controller: user,
          decoration: InputDecoration(
            hintText: 'Enter Email / Username',
            hintStyle: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(
                width: 0,
                style: BorderStyle.none,
              ),
            ),
            filled: true,
            fillColor: Colors.black,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        TextField(
          style: const TextStyle(color: Colors.white),
          obscureText: true,
          controller: pass,
          decoration: InputDecoration(
            hintText: 'Password',
            hintStyle: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(
                width: 0,
                style: BorderStyle.none,
              ),
            ),
            filled: true,
            fillColor: Colors.black,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          ),
        ),
        const SizedBox(
          height: 24,
        ),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF3D657),
            borderRadius: const BorderRadius.all(
              Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF3D657).withOpacity(0.2),
                spreadRadius: 3,
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: GestureDetector(
              onTap: login,
              child: const Text(
                "LOGIN",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 16,
        ),
      ],
    );
  }
}
