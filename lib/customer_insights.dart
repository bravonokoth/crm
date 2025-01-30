import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ClientFlow/customer.dart' as Customer;
import 'dart:developer' as developer;
import 'package:ClientFlow/item_screen.dart';
import 'package:ClientFlow/recent_order_page.dart';

class CustomerInsightsPage extends StatefulWidget {
  final String customerName;

  const CustomerInsightsPage({super.key, required this.customerName});

  @override
  _CustomerInsightsPageState createState() => _CustomerInsightsPageState();
}

class _CustomerInsightsPageState extends State<CustomerInsightsPage> {
  late Future<Customer.Customer?> customerFuture;
  late Future<List<Map<String, dynamic>>> salesDataFuture = Future.value([]);
  late Future<List<Map<String, dynamic>>> productsFuture = Future.value([]);
  late Future<List<Map<String, dynamic>>> recommendationsFuture = Future.value([]);
  late int customerId = 0;
  double latestSpending = 0.00;
  List<Map<String, dynamic>> productRecommendations = [];
  late Completer<bool> _isLoadedCompleter;
  late Future<bool> isLoaded;
  String recency = 'High';
  String nextVisit = '0';
  String totalSpendGroup = 'High';
  List<dynamic> customerData = [];
  Map<String, dynamic>? relevantCustomer;
  bool _customerFound = true;

  @override
  void initState() {
    super.initState();
    _isLoadedCompleter = Completer<bool>();
    isLoaded = _isLoadedCompleter.future;
    customerFuture = fetchCustomer();
  }

  Future<Customer.Customer?> fetchCustomer() async {
    try {
      const String apiUrl = 'https://haluansama.com/crm-sales/api/customer_insights/get_customer_data.php';
      final response = await http.get(Uri.parse('$apiUrl?company_name=${widget.customerName}'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          final data = jsonResponse['data'];

          setState(() {
            customerId = data['id'];
            _customerFound = true;
          });

          // Initialize all data fetching futures
          salesDataFuture = fetchSalesDataByCustomer(customerId);
          productsFuture = fetchProductsByCustomer(customerId);
          recommendationsFuture = fetchRecommendations(customerId);
          getRecency();
          getTotalSpendGroup();
          fetchPredictedVisitDay();
          fetchCustomerSegmentation();

          return Customer.Customer(
            id: data['id'] as int? ?? 0,
            companyName: data['company_name'] as String? ?? '',
            addressLine1: data['address_line_1'] as String? ?? '',
            addressLine2: data['address_line_2'] as String? ?? '',
            contactNumber: data['contact_number'] as String? ?? '',
            email: data['email'] as String? ?? '',
            customerRate: data['customer_rate'] != null ? data['customer_rate'].toString() : '',
            discountRate: data['discount_rate'] as int? ?? 0,
          );
        } else {
          setState(() {
            _customerFound = false;
          });
          return null;
        }
      } else {
        setState(() {
          _customerFound = false;
        });
        return null;
      }
    } catch (e) {
      developer.log('Error fetching customer: $e', error: e);
      setState(() {
        _customerFound = false;
      });
      return null;
    } finally {
      _isLoadedCompleter.complete(true);
    }
  }

  Future<List<Map<String, dynamic>>> fetchSalesDataByCustomer(int customerId) async {
    try {
      String apiUrl = 'https://haluansama.com/crm-sales/api/customer_insights/get_customer_salesdata.php?customer_id=$customerId';

      final url = Uri.parse(apiUrl);
      final data = jsonDecode((await http.get(url)).body);

      if (data['status'] == 'success') {
        var latestSpendingData = data['latest_spending'];
        if (latestSpendingData != null && latestSpendingData.containsKey('final_total')) {
          var finalTotal = await latestSpendingData['final_total'];

          if (finalTotal is String) {
            latestSpending = double.tryParse(finalTotal) ?? 0;
          } else if (finalTotal is int) {
            latestSpending = finalTotal.toDouble();
          } else {
            latestSpending = 0;
          }
        } else {
          developer.log('No latest spending data or final total key not found.');
        }

        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      developer.log('Error fetching sales data: $e', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchProductsByCustomer(int customerId) async {
    try {
      final String apiUrl = 'https://haluansama.com/crm-sales/api/customer_insights/get_products_by_customer_id.php?customer_id=$customerId';

      final url = Uri.parse(apiUrl);
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      developer.log('Error fetching products: $e', error: e);
      return [];
    }
  }

  void navigateToItemScreen(int selectedProductId) async {
    final apiUrl = 'https://haluansama.com/crm-sales/api/product/get_product_by_id.php?id=$selectedProductId';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success' && jsonResponse['product'] != null) {
          Map<String, dynamic> product = jsonResponse['product'];

          int productId = product['id'];
          String productName = product['product_name'];
          List<String> itemAssetName = [
            'https://haluansama.com/crm-sales/${product['photo1'] ?? 'null'}',
            'https://haluansama.com/crm-sales/${product['photo2'] ?? 'null'}',
            'https://haluansama.com/crm-sales/${product['photo3'] ?? 'null'}',
          ];
          String description = product['description'] ?? ''; // Changed from Blob to String
          String priceByUom = product['price_by_uom'] ?? '';

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemScreen(
                productId: productId,
                productName: productName,
                itemAssetNames: itemAssetName,
                itemDescription: description, // Now String is passed to String
                priceByUom: priceByUom,
              ),
            ),
          );
        } else {
          developer.log('Product not found or API returned error: ${jsonResponse['message']}');
        }
      } else {
        developer.log('Failed to fetch product details: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching product details: $e', error: e);
    }
  }

  Future<List<Map<String, dynamic>>> getProductRecommendations(String keyword) async {
    try {
      String apiUrl = 'https://haluansama.com/crm-sales/api/customer_insights/get_product_recommendation.php?keyword=${Uri.encodeComponent(keyword)}';

      final url = Uri.parse(apiUrl);
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      developer.log('Error fetching product recommendations: $e');
      return [];
    }
  }

  Future<List<String>> fetchKeywords(int customerId) async {
    try {
      String sqlUrl = 'https://haluansama.com/crm-sales/api/customer_insights/get_keywords.php?customer_id=$customerId';

      final url = Uri.parse(sqlUrl);
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        return List<String>.from(data['data'].map((item) => item['sub_category']) ?? '');
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      developer.log('Error fetching keywords: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchRecommendations(int customerId) async {
    try {
      List<String> keywords = await fetchKeywords(customerId);
      List<Map<String, dynamic>> recommendations = [];

      for (String keyword in keywords) {
        List<Map<String, dynamic>> keywordRecommendations = await getProductRecommendations(keyword);
        recommendations.addAll(keywordRecommendations);
      }

      return recommendations;
    } catch (e) {
      developer.log('Error fetching recommendations: $e', error: e);
      return [];
    }
  }

  Future<void> fetchCustomerSegmentation() async {
    const String apiUrl = 'http://18.142.14.144:5000/api/customer-segmentation';

    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        customerData = json.decode(response.body);

        int currentCustomerId = customerId;

        relevantCustomer = customerData.firstWhere(
          (customer) => customer['customer_id'] == currentCustomerId,
          orElse: () => null,
        );

        if (relevantCustomer != null) {
          relevantCustomer!['recency_category'] = categorizeRecency(relevantCustomer!['recency']);
          relevantCustomer!['total_spend_group'] = categoriseTotalSpentGroup(relevantCustomer!['Segment']);
          developer.log('Relevant Customer Data: $relevantCustomer');
        }
      } else {
        throw Exception('Failed to load customer segmentation: ${response.statusCode}');
      }
    } catch (error) {
      developer.log('Error fetching data: $error');
    }
  }

  String categoriseTotalSpentGroup(String totalSpentGroup) {
    if (totalSpentGroup == "Low Value") {
      totalSpendGroup = 'Low';
      return 'Low';
    } else if (totalSpentGroup == "Mid Value") {
      totalSpendGroup = 'Mid';
      return 'Mid';
    } else {
      totalSpendGroup = 'High';
      return 'High';
    }
  }

  Color getCustomerValueBgColor(String spendGroup) {
    if (totalSpendGroup == 'High') {
      return const Color(0xff94FFDF);
    } else if (totalSpendGroup == 'Mid') {
      return const Color(0xffF1F78B);
    } else {
      return const Color(0xffFF6666);
    }
  }

  Color getCustomerValueTextColor(String spendGroup) {
    if (spendGroup == 'High') {
      return const Color(0xff008A64);
    } else if (spendGroup == 'Mid') {
      return const Color(0xff808000);
    } else {
      return const Color(0xff840000);
    }
  }

  String categorizeRecency(int recency) {
    if (recency <= 30) {
      this.recency = 'High';
      return 'High';
    } else if (recency <= 90) {
      this.recency = 'Mid';
      return 'Mid';
    } else {
      this.recency = 'Low';
      return 'Low';
    }
  }

  Future<void> getRecency() async {
    final String apiUrl = 'https://haluansama.com/crm-sales/api/customer_insights/get_recency.php?customer_id=$customerId';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        setState(() {
          recency = jsonResponse.toString();
        });

        developer.log('Recency: $recency');
      } else {
        developer.log('Failed to fetch recency. Status code: ${response.statusCode}');
      }
    } catch (error) {
      developer.log('Error occurred: $error');
    }
  }

  Future<void> getTotalSpendGroup() async {
    final String apiUrl = 'https://haluansama.com/crm-sales/api/customer_insights/get_total_spend_group.php?customer_id=$customerId';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        setState(() {
          totalSpendGroup = jsonResponse.toString();
        });

        developer.log('Total Spend Group: $totalSpendGroup');
      } else {
        developer.log('Failed to fetch total spend group. Status code: ${response.statusCode}');
      }
    } catch (error) {
      developer.log('Error occurred: $error');
    }
  }

  IconData _getSpendGroupIcon(String totalSpendGroup) {
    if (totalSpendGroup == 'High') {
      return Icons.north_east;
    } else if (totalSpendGroup == 'Mid') {
      return Icons.east;
    } else {
      return Icons.south_east;
    }
  }

  Color _getSpendGroupColor(String totalSpendGroup) {
    if (totalSpendGroup == 'High') {
      return const Color(0xff29c194);
    } else if (totalSpendGroup == 'Mid') {
      return const Color(0xffFFC300);
    } else {
      return const Color(0xffFF5454);
    }
  }

  IconData _getRecencyIcon(String recency) {
    if (recency == 'High') {
      return Icons.north;
    } else if (recency == 'Mid') {
      return Icons.east;
    } else {
      return Icons.south;
    }
  }

  Future<int?> fetchPredictedVisitDay() async {
    try {
      final response = await http.get(Uri.parse('https://haluansama.com/crm-sales/api/customer_insights/get_next_visit.php?customer_id=$customerId'));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          nextVisit = responseData['predicted_visit_day'].toString();
          developer.log(responseData['predicted_visit_day'].toString());
          return responseData['predicted_visit_day'];
        } else {
          developer.log('Error: ${responseData['message']}');
          return null;
        }
      } else {
        developer.log('Failed to load data: ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      developer.log('Error occurred: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Customer Insights',
          style: GoogleFonts.inter(
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xff0175FF),
        leading: Theme(
          data: Theme.of(context).copyWith(
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: FutureBuilder<Customer.Customer?>(
        future: customerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError || !_customerFound || snapshot.data == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 100,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'This customer is not registered.\nPlease contact the admin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          } else {
            Customer.Customer customer = snapshot.data!;
            return FutureBuilder<List<dynamic>>(
              future: Future.wait([salesDataFuture, productsFuture, recommendationsFuture, isLoaded]),
              builder: (context, salesSnapshot) {
                if (salesSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Fetching Customer Details'),
                      ],
                    ),
                  );
                } else if (salesSnapshot.hasError) {
                  return Center(child: Text('Error: ${salesSnapshot.error}'));
                } else {
                  List<Map<String, dynamic>> salesData = salesSnapshot.data![0] as List<Map<String, dynamic>>;
                  List<Map<String, dynamic>> products = salesSnapshot.data![1] as List<Map<String, dynamic>>;
                  List<Map<String, dynamic>> recommendations = salesSnapshot.data![2] as List<Map<String, dynamic>>;

                  String totalSpent = salesData.isNotEmpty
                      ? salesData.map((entry) => entry['total_spent'] ?? '0.00')
                          .map((spent) => double.parse(spent.toString()))
                          .reduce((a, b) => (a + b))
                          .toString()
                      : '0.00';

                  String lastSpending = latestSpending.toString();

                  final formatter = NumberFormat("#,##0.000", "en_MY");
                  String formattedTotalSpent = formatter.format(double.parse(totalSpent));
                  String formattedLastSpending = formatter.format(double.parse(lastSpending));

                  Color spendGroupBgColor = getCustomerValueBgColor(totalSpendGroup);
                  Color spendGroupTextColor = getCustomerValueTextColor(totalSpendGroup);

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // ... (rest of your UI components here)
                      ],
                    ),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}