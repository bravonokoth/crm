import 'package:flutter/material.dart';
import 'package:ClientFlow/components/navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ClientFlow/utility_function.dart';
import 'package:ClientFlow/add_new_customer.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int userId;

  @override
  void initState() {
    super.initState();
    _initializeUserId();
  }

  void _initializeUserId() async {
    final id = await UtilityFunction.getUserId();
    developer.log('Initialized userId: $id');
    setState(() {
      userId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  automaticallyImplyLeading: false,
  backgroundColor: const Color(0xff0175FF),
  title: FutureBuilder(
    future: _getUserName(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        return Text(
          'Welcome, ${snapshot.data ?? "User"}',
          style: const TextStyle(color: Colors.white),
        );
      } else {
        return const Text('Welcome, User', style: TextStyle(color: Colors.white));
      }
    },
  ),
),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(),
              
               // Action Buttons
              _buildActionButtons(),

              // Invoices and Orders Section
              _buildInvoicesAndOrders(),
              
              // Quotations Summary
              _buildQuotationsSummary(),
              
             
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Color(0xff0175FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good Morning',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 18),
          ),
          Text(
            '', // Replace with dynamic user name
            style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    '',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              // Add your logo or icon here
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Center(
                  child: Icon(Icons.local_shipping, color: Color.fromARGB(255, 184, 20, 224), size: 30),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
Widget _buildActionButtons() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _buildActionCard(
        onTap: () {
          developer.log('Create Lead button pressed');
        },
        icon: Icons.add_circle_outline,
        title: 'Create Lead',
        color: Colors.blue,
      ),
      _buildActionCard(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddNewCustomer()),
          );
        },
        icon: Icons.person_add,
        title: 'Add Customer',
        color: Colors.green,
      ),
      _buildActionCard(
        onTap: () {
          developer.log('Completed Orders button pressed');
        },
        icon: Icons.check_circle_outline,
        title: 'Completed Orders',
        color: Colors.orange,
      ),
    ],
  );
}


Widget _buildActionCard({
  required VoidCallback onTap,
  required IconData icon,
  required String title,
  required Color color,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      width: MediaQuery.of(context).size.width / 3.5,
      height: 120, // Reduced height from 150 to 120
      margin: EdgeInsets.symmetric(horizontal: 4.0),
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 35, // Slightly smaller icon
            color: Colors.black,
          ),
          SizedBox(height: 4), // Reduce spacing
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14, // Slightly smaller font size
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

 

  Widget _buildInvoicesAndOrders() {
    return Row(
      children: [
        Expanded(
          child: _buildSectionCard('Invoices', [
            'Paid',
            'Unpaid',
            'Overdue',
          ]),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildSectionCard('Orders', [
            'Delivered',
            'Processing',
            'Draft/Awaiting Truck',
          ]),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, List<String> items) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  item,
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildQuotationsSummary() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quotations Summary',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuotationStatus('Draft', '7'),
              _buildQuotationStatus('Sent', '3'),
              _buildQuotationStatus('Opened', '0'),
              _buildQuotationStatus('Confirm', '0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationStatus(String status, String count) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[200],
          child: Text(
            count,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 8),
        Text(
          status,
          style: GoogleFonts.inter(fontSize: 14),
        ),
      ],
    );
  }

  

 

Future<String?> _getUserName() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('userName');
}

}