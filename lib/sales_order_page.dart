import 'dart:convert';
import 'package:ClientFlow/home_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:sizer/sizer.dart';
import 'package:ClientFlow/customer_dropdown_widget.dart';

class SalesOrderPage extends StatefulWidget {
  const SalesOrderPage({super.key});

  @override
  _SalesOrderPageState createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  String? staffId;
  String? userName;
  String loggedInUsername = ""; // Initialize empty
  bool _isLoading = false;

  late TextEditingController duedateController;
  late TextEditingController deliverydateController;
  late TextEditingController deliverylocationController;
  late TextEditingController termsController;
  late TextEditingController notesController;
  late TextEditingController rateController;
  late TextEditingController quantityController;

  final Map<int, TextEditingController> rateControllers = {};
  final Map<int, TextEditingController> quantityControllers = {};

  List<Map<String, String>> crmCustomers = [];
  List<Map<String, String>> crmitems = [];
  List<Map<String, dynamic>> orderItems = []; 
  List<Map<String, String>> filteredCustomers = [];

  String? selectedCustomer;
  String? selectedItemId;
  String? selectedItemName;
  String? selectedItemRate;

  bool isPublic = false;

  @override
  void initState() {
    super.initState();
    getUser();
    duedateController = TextEditingController();
    deliverydateController = TextEditingController();
    termsController = TextEditingController();
    deliverylocationController = TextEditingController();
    notesController = TextEditingController();
    rateController = TextEditingController();
    quantityController = TextEditingController();
    filteredCustomers = List.from(crmCustomers);
     
    
  }

  @override
  void dispose() {
    duedateController.dispose();
    deliverydateController.dispose();
    termsController.dispose();
    notesController.dispose();
    deliverylocationController.dispose();
    for (var controller in rateControllers.values) {
      controller.dispose();
    }
    for (var controller in quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void updateOrderItems(int index, TextEditingController rateController, int quantity) {
    final item = crmitems[index];
    setState(() {
      orderItems[index] = {
        'item_id': item['id'],
        'description': item['item'],
        'sku': item['sku_code'],
        'rate': rateController.text,
        'quantity': quantity.toString(),
      };
    });
  }

  Future<void> getUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userName = prefs.getString('userName');
        staffId = prefs.getString('id'); // Assuming 'id' is the staffId
        loggedInUsername = prefs.getString('username') ?? '';
      });

      await fetchCustomersForNewOrder();
      await fetchItemsForNewOrder();
    } catch (e) {
      developer.log('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> checkInternetConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await fetchCustomersForNewOrder();
      await fetchItemsForNewOrder();
    } catch (e) {
      developer.log('Error refreshing data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing data. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

Future<void> fetchItemsForNewOrder() async {
  String apiUrl = 'https://60ea-102-215-77-46.ngrok-free.app/api/items';
  try {
    final Uri itemsUrl = Uri.parse(apiUrl);
    final response = await http.get(itemsUrl);
    if (response.statusCode == 200) {
      final Map data = json.decode(response.body);
      setState(() {
        crmitems = List<Map<String, String>>.from(
          // Assuming 'items' in the response is a list of item maps
          data['items'].asMap().map((index, item) => MapEntry(index, {
            'id': (index + 1).toString(), // Using index + 1 as a placeholder for id
            'item': item['name'].toString(),
            'rate': item['rate'].toString(),
            'unit': item['unit'].toString(),
            'sku_code': item['sku_code'].toString(),
          })).values,
        );
      });
      developer.log('Number of items fetched: ${crmitems.length}');
    } else {
      developer.log('Failed to load items. Status code: ${response.statusCode}');
      throw Exception('Failed to load items');
    }
  } catch (e) {
    developer.log("Items URL $apiUrl not reachable: $e");
    throw Exception("Items URL is not reachable!");
  }
}

  Future<void> fetchCustomersForNewOrder() async {
    String apiUrl = 'https://60ea-102-215-77-46.ngrok-free.app/api/customers';
    try {
      final Uri customersUrl = Uri.parse(apiUrl);
      final response = await http.get(customersUrl);
      if (response.statusCode == 200) {
        final Map data = json.decode(response.body);
        final List clientList = data['data'];
        setState(() {
          crmCustomers = clientList.map((customer) {
            return {
              'clientid': customer['id'].toString(),
              'company': customer['company'].toString(),
            };
          }).toList();
          filteredCustomers = List.from(crmCustomers);
        });
      } else {
        developer.log('Failed to load crm customers. Status code: ${response.statusCode}');
        throw Exception('Failed to load crm customers');
      }
    } catch (e) {
      developer.log("Customers URL $apiUrl not reachable: $e");
      throw Exception("Customers URL is not reachable!");
    }
  }

  Future<void> submitNewOrder() async {
    if (staffId == null || staffId!.isEmpty) {
      developer.log('User not logged in');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to submit an order.')),
      );
      return;
    }

    if (duedateController.text.isEmpty ||
        selectedCustomer == null ||
        deliverydateController.text.isEmpty ||
        termsController.text.isEmpty ||
        notesController.text.isEmpty || 
        deliverylocationController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Validation Error'),
          content: const Text('Please fill all required (*) fields.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    bool isConnected = await checkInternetConnectivity();
    if (!isConnected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Internet Connection'),
          content: const Text('Please check your internet connection.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Are you sure you want to save this Order?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog if the user cancels
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close the dialog first
              setState(() {
                _isLoading = true;
              });
              try {
                final validOrderItems = orderItems.where((item) =>
                    item['rate'] != null &&
                    item['quantity'] != null &&
                    item['description'] != null &&
                    item['sku'] != null);

                final orderItemsData = validOrderItems.map((item) {
                  return {
                    'item_id': item['item_id'],
                    'rate': item['rate'],
                    'quantity': item['quantity'],
                    'description': item['description'],
                    'sku': item['sku'],
                  };
                }).toList();

                final url = Uri.parse('https://60ea-102-215-77-46.ngrok-free.app/api/create_order');
                final response = await http.post(
                  url,
                  headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: jsonEncode({
                    'seller': staffId, // Using staffId
                    'items': orderItemsData,
                    'deliverydate': deliverydateController.text,
                    'duedate': duedateController.text,
                    'order_branch': deliverylocationController.text,
                    'customer': selectedCustomer,
                    'notes': notesController.text,
                    'terms': termsController.text,
                    'currency': 'KES',
                  }),
                );

                if (response.statusCode == 200) {
                  final Map<String, dynamic> data = json.decode(response.body);
                  if (data['status'] == 'true' && data['activation_status'] == 'true') {
                    developer.log('Success: ${data['message']}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Order submitted successfully!')),
                    );
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to submit order: ${data['message']}')),
                    );
                  }
                } else {
                  developer.log('Failed to submit Order. Status code: ${response.statusCode}');
                  throw Exception('Failed to submit Order');
                }
              } catch (e) {
                developer.log('Error: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error submitting order. Please try again later.')),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

@override
Widget build(BuildContext context) {
  var height = MediaQuery.of(context).size.height;
  var width = MediaQuery.of(context).size.width;
  var sp = (double fontSize) => fontSize * MediaQuery.of(context).textScaleFactor;

  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        },
      ),
      title: Text('Sales Order Page'),
      backgroundColor: Colors.purple, // Violet color for the app bar
    ),
    backgroundColor: const Color(0xffF5F5F5),
    body: SafeArea(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshData,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      // Adding ConstrainedBox to limit the max height of the whole content
                      constraints: BoxConstraints(maxHeight: 2700),
                      child: Column(
                        children: [
                          SizedBox(height: height * 0.166),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              children: [
                                SizedBox(height: height * 0.02),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Customer *',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            textStyle: TextStyle(
                                              fontSize: sp(10.0),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: height * 0.01),
                                    CustomerDropdown(
                                      crmCustomers: crmCustomers,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedCustomer = value;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Select Customer',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10.0),
                                          borderSide: BorderSide.none,
                                        ),
                                        fillColor: Colors.white,
                                        filled: true,
                                        prefixIcon: Icon(Icons.person),
                                      ),
                                    ),
                                    SizedBox(height: height * 0.02),
                                    Row(
                                      children: [
                                        Text(
                                          'Due Date (For Order\'s Invoice) *',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            textStyle: TextStyle(
                                              fontSize: sp(10.0),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: height * 0.01),
                                    TextFormField(
                                      controller: deliverydateController,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10.0),
                                          borderSide: BorderSide.none,
                                        ),
                                        fillColor: Colors.white,
                                        filled: true,
                                        hintText: 'Select Date and Time',
                                        prefixIcon: Icon(Icons.calendar_month),
                                      ),
                                      onTap: () async {
                                        DateTime? pickedDate = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2101),
                                        );

                                        if (pickedDate != null) {
                                          TimeOfDay? pickedTime = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.now(),
                                          );

                                          if (pickedTime != null) {
                                            DateTime pickedDateTime = DateTime(
                                              pickedDate.year,
                                              pickedDate.month,
                                              pickedDate.day,
                                              pickedTime.hour,
                                              pickedTime.minute,
                                            );

                                            String formattedDateTime =
                                                DateFormat('yyyy-MM-dd HH:mm').format(pickedDateTime);
                                            deliverydateController.text = formattedDateTime;
                                          }
                                        }
                                      },
                                    ),
                                    SizedBox(height: height * 0.02),
                                    SizedBox(height: height * 0.01),
                                    Row(
                                      children: [
                                        Text(

 'Select Items *',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            textStyle: TextStyle(
                                              fontSize: sp(10.0),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: height * 0.01),
                                    // Removed ConstrainedBox to allow natural expansion
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: crmitems.length,
                                      itemBuilder: (context, index) {
                                        final item = crmitems[index];
                                        final originalRate = double.parse(item['rate']!);

                                        // Initialize controllers if not already present
                                        if (!rateControllers.containsKey(index)) {
                                          rateControllers[index] = TextEditingController();
                                          quantityControllers[index] = TextEditingController();
                                        }

                                        final rateController = rateControllers[index]!;
                                        final quantityController = quantityControllers[index]!;

                                        return Card(
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              color: Color(0xFF764abc),
                                              width: 2.0,
                                            ),
                                            borderRadius: BorderRadius.circular(6.0),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['item']!,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF764abc),
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          IconButton(
                                                            icon: Icon(Icons.remove),
                                                            onPressed: () {
                                                              double currentRate = double.tryParse(rateController.text) ?? originalRate;
                                                              if (currentRate > originalRate) {
                                                                setState(() {
                                                                  rateController.text = (currentRate - 1).toStringAsFixed(2);
                                                                });
                                                              }
                                                            },
                                                          ),
                                                          Expanded(
                                                            child: TextFormField(
                                                              controller: rateController,
                                                              decoration: InputDecoration(
                                                                labelText: 'Rate',
                                                              ),
                                                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                              onChanged: (value) {
                                                                if (value.isNotEmpty) {
                                                                  final enteredRate = double.tryParse(value);
                                                                  if (enteredRate != null && enteredRate < originalRate) {
                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                      SnackBar(
                                                                        content: Text('Rate cannot be less than ${originalRate.toStringAsFixed(2)} KES'),
                                                                      ),
                                                                    );
                                                                    rateController.text = originalRate.toStringAsFixed(2);
                                                                  }
                                                                }
                                                              },
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: Icon(Icons.add),
                                                            onPressed: () {
                                                              double currentRate = double.tryParse(rateController.text) ?? originalRate;
                                                              setState(() {
                                                                rateController.text = (currentRate + 1).toStringAsFixed(2);
                                                              });
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 16),
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          IconButton(
                                                            icon: Icon(Icons.remove),
                                                            onPressed: () {
                                                              int currentQuantity = int.tryParse(quantityController.text) ?? 0;
                                                              if (currentQuantity > 0) {
                                                                setState(() {
                                                                  quantityController.text = (currentQuantity - 1).toString();
                                                                  updateOrderItems(index, rateController, currentQuantity - 1);
                                                                });
                                                              }
                                                            },
                                                          ),
                                                          Expanded(
                                                            child: TextFormField(
                                                              controller: quantityController,
                                                              decoration: InputDecoration(
                                                                labelText: 'Quantity',
                                                              ),
                                                              keyboardType: TextInputType.number,
                                                              onChanged: (value) {
                                                                if (value.isNotEmpty) {
                                                                  setState(() {
                                                                    updateOrderItems(index, rateController, int.parse(value));
                                                                  });
                                                                }
                                                              },
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: Icon(Icons.add),
                                                            onPressed: () {
                                                              int currentQuantity = int.tryParse(quantityController.text) ?? 0;
                                                              setState(() {
                                                                quantityController.text = (currentQuantity + 1).toString();
                                                                updateOrderItems(index, rateController, currentQuantity + 1);
                                                              });
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(height: height * 0.02),
                                    Row(
                                      children: [
                                        Text(
                                          'Notes *',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            textStyle: TextStyle(
                                              fontSize: sp(10.0),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: height * 0.01),
                                    TextFormField(
                                      controller: notesController,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10.0),
                                          borderSide: BorderSide.none,
                                        ),
                                        fillColor: Colors.white,
                                        filled: true,
                                        prefixIcon: Icon(Icons.note_alt),
                                      ),
                                    ),
                                    SizedBox(height: height * 0.02),
                                    SizedBox(height: height * 0.01),
                                    Row(
                                      children: [
                                        Text(
                                          'Terms and Conditions *',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            textStyle: TextStyle(
                                              fontSize: sp(10.0),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: height * 0.01),
                                    TextFormField(
                                      controller: termsController,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10.0),
                                          borderSide: BorderSide.none,
                                        ),
                                        fillColor: Colors.white,
                                        filled: true,
                                        prefixIcon: Icon(Icons.description),
                                      ),
                                    ),
                                    SizedBox(height: height * 0.02),
                                    SizedBox(height: height * 0.01),
                                    Row(
                                      children: [
                                        Text(
                                          'Delivery Location *',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            textStyle: TextStyle(
                                              fontSize: sp(10.0),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: height * 0.01),
                                    TextFormField(
                                      controller: deliverylocationController,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10.0),
                                          borderSide: BorderSide.none,
                                        ),
                                        fillColor: Colors.white,
                                        filled: true,
                                        prefixIcon: Icon(Icons.location_on),
                                      ),
                                    ),
                                    SizedBox(height: height * 0.02),

                                    GestureDetector(
                                      onTap: () async {
                                        if (duedateController.text.isEmpty ||
                                            selectedCustomer == null ||
                                            deliverydateController.text.isEmpty ||
                                            termsController.text.isEmpty ||
                                            notesController.text.isEmpty ||
                                            deliverylocationController.text.isEmpty) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Validation Error'),
                                              content: const Text('Please fill all required (*) fields.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            ),
                                          );
                                        } else {
                                          bool isConnected = await checkInternetConnectivity();
                                          if (!isConnected) {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('No Internet Connection'),
                                                content: const Text('Please check your internet connection.'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: const Text('OK'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          } else {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Confirm'),
                                                content: const Text('Are you sure do you want to save this Order'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      submitNewOrder();
                                                    },
                                                    child: const Text('OK'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(height * 0.01),
                                        decoration: BoxDecoration(
                                          color: Colors.greenAccent,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Save Order',
                                          style: GoogleFonts.poppins(
                                            textStyle: TextStyle(
                                              fontSize: sp(10.0),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: height * 0.05),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}
}