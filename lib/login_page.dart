import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'dart:io';
import 'package:ClientFlow/home_page.dart';  // Correct import for HomePage

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginPage({super.key});



  /// Handles user sign-in
  void signIn(BuildContext context) async {
    String email = emailController.text.trim(); // Trim to remove extra spaces
    String password = passwordController.text.trim();

    // Debugging: Print email and password before sending request
    developer.log("Email entered: $email");
    developer.log("Password entered: $password");

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return; // Stop execution if fields are empty
    }

    try {
      String apiUrl = "https://60ea-102-215-77-46.ngrok-free.app/api/login";
      final Uri url = Uri.parse(apiUrl);

      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json', // Explicitly set content type
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      developer.log("Response Status: ${response.statusCode}");
      developer.log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login successful! Welcome ${jsonResponse['user']['name']}")),
        );

        // Navigate to the homepage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please check your credentials.')),
        );
      }
    } catch (e) {
      developer.log('Error signing in: $e', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Please try again.')),
      );
    }
  }

  void showContactInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Information'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Please contact our support team for assistance:'),
                SizedBox(height: 10),
                Text('Phone: +254791418021'),
                Text('Email: energycrm.com'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.only(
                left: 18,
                top: 50,
                bottom: 20,
              ),
              alignment: Alignment.centerLeft,
              child: Image.asset('asset/logo/logo_fyh.png',
                  width: 200, height: 100),
            ),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(
                left: 20,
                bottom: 24,
              ),
              child: const Text(
                'Control your Sales\ntoday.',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              ),
            ),

            // Email input field
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.only(
                  top: 10, bottom: 10, left: 20, right: 20),
              child: TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Username',
                ),
              ),
            ),

            // Password input field
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.only(top: 10, left: 20, right: 20),
              child: TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
              ),
            ),

            // Sign in button
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.only(top: 10, left: 80, right: 80),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Call the sign in method
                  signIn(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 7, 148, 255),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Forgot password button
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                // Show pop up window
                showContactInfoDialog(context);
              },
              child: const Text(
                'Forgot Password',
                style: TextStyle(
                  color: Colors.black,
                  decoration: TextDecoration.underline,
                  decorationThickness: 2.0,
                ),
              ),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 800, // Set your desired width
                  child: Image.asset(
                    'asset/SN_ELEMENTS_CENTER.png',
                  ),
                ),
                Positioned(
                  top: 10,
                  // Adjust the position of the new image as needed
                  child: SizedBox(
                    width:
                        200, // Set your desired width for the new image
                    child: Image.asset(
                      'asset/chart_illu.png',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
