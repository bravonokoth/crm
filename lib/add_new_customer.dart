import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddNewCustomer extends StatefulWidget {
  @override
  _AddNewCustomerState createState() => _AddNewCustomerState();
}

class _AddNewCustomerState extends State<AddNewCustomer> {
  String? salesmanId;
  String? userName;
  double width = 0.0;

  final _formKey = GlobalKey<FormState>();

  // Controllers initialization
  late TextEditingController companyController,
      kraController,
      emailController,
      phoneController,
      billingStreetController,
      billingCityController,
      billingStateController,
      billingZipController,
      websiteController,
      fnameController,
      lnameController,
      billingCountryController,
      addedFromController,
      activeController,
      isSupplierController;

  List<Map<String, String>> countries = [];
  List<String> addedFromOptions = ['App'];
  List<String> clientTypeOptions = ['Individual', 'Company'];
  List<String> activeStatusOptions = ['1', '0'];
  List<String> isSupplierOptions = ['1', '0'];

  String? selectedCountry;
  String? selectedClientType;
  String? selectedAddedFrom;
  String? selectedActiveStatus;
  String? selectedIsSupplier;

  bool isLoadingCountries = false;
  bool isSubmitting = false;

  @override
void initState() {
  super.initState();
  initializeControllers();
  getUser();
  fetchCountries();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    setState(() {
      width = SizerUtil.width;
    });
  });
}

  void initializeControllers() {
    companyController = TextEditingController();
    kraController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    billingStreetController = TextEditingController();
    billingCityController = TextEditingController();
    billingStateController = TextEditingController();
    billingZipController = TextEditingController();
    websiteController = TextEditingController();
    fnameController = TextEditingController();
    lnameController = TextEditingController();
    billingCountryController = TextEditingController();
    addedFromController = TextEditingController();
    activeController = TextEditingController();
    isSupplierController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose of all controllers
    companyController.dispose();
    kraController.dispose();
    emailController.dispose();
    phoneController.dispose();
    billingStreetController.dispose();
    billingCityController.dispose();
    billingStateController.dispose();
    billingZipController.dispose();
    websiteController.dispose();
    fnameController.dispose();
    lnameController.dispose();
    billingCountryController.dispose();
    addedFromController.dispose();
    activeController.dispose();
    isSupplierController.dispose();
    super.dispose();
  }

  Future<void> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName');
      salesmanId = prefs.getString('id');
    });
  }

  Future<bool> checkInternetConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> fetchCountries() async {
    if (!await checkInternetConnectivity()) {
      _showResponseDialog('Error', 'No internet connection.');
      return;
    }

    setState(() {
      isLoadingCountries = true; 
    });

    final url = Uri.parse('');
    try {
      final response = await http.post(url, body: {});
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'true') {
          setState(() {
            countries = List<Map<String, String>>.from(data['countries'].map((country) {
              return {
                'country_id': country['country_id'].toString(),
                'short_name': country['short_name'].toString(),
              };
            }));
          });
        } else {
          _showResponseDialog('Error', 'Failed to load countries');
        }
      } else {
        _showResponseDialog('Error', 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showResponseDialog('Error', 'Network error while loading countries.');
    } finally {
      setState(() {
        isLoadingCountries = false; 
      });
    }
  }

Future<void> submitCompany() async {
  selectedCountry ??= "0";

  final url = Uri.parse('');
  final response = await http.post(url, body: {
    
    'company': companyController.text,
    'vat': kraController.text,
    'email': emailController.text,
    'firstname': fnameController.text,
    'lastname': lnameController.text,
    'phone': phoneController.text,
    'billing_street': billingStreetController.text,
    'billing_city': billingCityController.text,
    'billing_state': billingStateController.text,
    'billing_zip': billingZipController.text,
    'country': selectedCountry,
    'website': '',
    'added_from': selectedAddedFrom ?? '0',
    'client_type': selectedClientType ?? '',
    'datecreated': DateTime.now().toIso8601String(),
    'active': selectedActiveStatus ?? '1',
    'is_supplier': selectedIsSupplier ?? '0',
  });

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    if (data['status'] == 'true' && data['activation_status'] == 'true') {
      _showResponseDialog('Success', data['message']);
      _resetForm();
    } else {
      _showResponseDialog('Failure', data['message']);
    }
  } else {
    _showResponseDialog('Error', 'Failed to submit company. Status code: ${response.body}');
  }
}



 void _showResponseDialog(String title, String message) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  });
}

  void _resetForm() {
    companyController.clear();
    kraController.clear();
    emailController.clear();
    fnameController.clear();
    lnameController.clear();
    phoneController.clear();
    billingStreetController.clear();
    billingCityController.clear();
    billingStateController.clear();
    billingZipController.clear();
    websiteController.clear();
    addedFromController.clear();
    activeController.clear();
    isSupplierController.clear();
    selectedCountry = null;
    selectedClientType = null;
    selectedAddedFrom = null;
    selectedActiveStatus = null;
    selectedIsSupplier = null; 
    setState(() {});
  }



@override
Widget build(BuildContext context) {
  if (width == 0.0) {
    return Center(child: CircularProgressIndicator()); // Show a loading indicator instead of an empty container
  }

  return Scaffold(
    backgroundColor: const Color(0xffF5F5F5),
    body: SafeArea(
      child: Column(
        children: [
          Container(
            color: const Color(0xffF5F5F5),
            height: 120.0,
            padding: const EdgeInsets.only(top: 60.0),
            child: Column(
              children: [
                Container(
                  height: 50.0,
                  padding: const EdgeInsets.only(left: 30, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              'Hello, $userName!',
                              style: GoogleFonts.poppins(
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 7, 7, 7)),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          'Add Customer',
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Using width to set container width
                  Container(
                    width: width * 0.95, // 80% of screen width
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Company Name
                          TextFormField(
                            controller: companyController,
                            decoration: InputDecoration(
                              labelText: 'Company Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              prefixIcon: Icon(Icons.business_center_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the company name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 15.sp),

                          // KRA Pin
                          TextFormField(
                            controller: kraController,
                            decoration: InputDecoration(
                              labelText: 'KRA Pin',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              prefixIcon: Icon(Icons.document_scanner),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the KRA Pin';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 15.sp),

                          // Email
                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              prefixIcon: Icon(Icons.email),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 15.sp),

                          // Contact First Name
                          TextFormField(
                            controller: fnameController,
                            decoration: InputDecoration(
                              labelText: 'Contact First Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the firstname';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 30.sp),

                          // Contact Last Name
                          TextFormField(
                            controller: lnameController,
                            decoration: InputDecoration(
                              labelText: 'Contact Last Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              prefixIcon: Icon(Icons.person_2_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the lastname';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 30.sp),

                          // Phone Number
                          TextFormField(
                            controller: phoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              prefixIcon: Icon(Icons.phone),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 15.sp),

                          // Billing Street
                          TextFormField(
                            controller: billingStreetController,
                            decoration: InputDecoration(
                              labelText: 'Billing Street',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              prefixIcon: Icon(Icons.map),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the billing street';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 15.sp),

                          // Billing City
                          TextFormField(
                            controller: billingCityController,
                            decoration: InputDecoration(
                              labelText: 'Billing City',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              prefixIcon: Icon(Icons.location_city),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the billing city';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 15.sp),

                          // Billing State
                          TextFormField(
                            controller: billingStateController,
                            decoration: InputDecoration(
                              labelText: 'Billing State',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              prefixIcon: Icon(Icons.location_history_rounded),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the billing state';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 15.sp),

                          // Billing Zip
                          TextFormField(
                            controller: billingZipController,
                            decoration: InputDecoration(
                              labelText: 'Billing Zip',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              prefixIcon: Icon(Icons.add_business),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the billing zip';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 15.sp),

                          // Country Dropdown
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: SizedBox(
                              height: 45.sp,
                              child: DropdownButtonFormField(
                                hint: const Text('Country'),
                                value: selectedCountry,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedCountry = newValue;
                                  });
                                },
                                items: countries
                                    .where((country) => country['short_name'] == 'Kenya')
                                    .map((country) {
                                  return DropdownMenuItem(
                                    value: country['country_id'],
                                    child: Text(country['short_name'] ?? ''),
                                  );
                                }).toList(),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                  prefixIcon: Icon(Icons.blur_on_rounded),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 15.sp),

                          // Added From Dropdown
                          DropdownButtonFormField(
                            hint: const Text('Added From'),
                            value: selectedAddedFrom,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedAddedFrom = newValue;
                              });
                            },
                            items: addedFromOptions.map((option) {
                              return DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              prefixIcon: Icon(Icons.back_hand_rounded),
                            ),
                          ),
                          SizedBox(height: 15.sp),

                          // Client Type Dropdown
                          DropdownButtonFormField(
                            hint: const Text('Client Type'),
                            value: selectedClientType,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedClientType = newValue;
                              });
                            },
                            items: clientTypeOptions.map((option) {
                              return DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              prefixIcon: Icon(Icons.star_border),
                            ),
                          ),
                          SizedBox(height: 15.sp),

                          // Active Status Dropdown
                          DropdownButtonFormField(
                            hint: const Text('Active Status'),
                            value: selectedActiveStatus,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedActiveStatus = newValue;
                              });
                            },
                            items: activeStatusOptions.map((option) {
                              return DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              prefixIcon: Icon(Icons.circle),
                            ),
                          ),
                          SizedBox(height: 15.sp),

                          // Is Supplier Dropdown
                          DropdownButtonFormField(
                            hint: const Text('Is Supplier'),
                            value: selectedIsSupplier,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedIsSupplier = newValue;
                              });
                            },
                            items: isSupplierOptions.map((option) {
                              return DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              prefixIcon: Icon(Icons.check_box),
                            ),
                          ),
                          SizedBox(height: 15.sp),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}