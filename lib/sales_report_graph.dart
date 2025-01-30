import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Report',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: const ColorScheme.light(
          primary: Colors.lightBlue,
          onPrimary: Colors.white,
          surface: Colors.lightBlue,
        ),
        iconTheme: const IconThemeData(color: Colors.lightBlue),
      ),
      home: const SalesReport(),
    );
  }
}

class SalesReport extends StatefulWidget {
  const SalesReport({super.key});

  @override
  _SalesReportState createState() => _SalesReportState();
}

class _SalesReportState extends State<SalesReport> {
  final Map<String, List<SalesData>> _salesDataMap = {};
  String _selectedInterval = '3D';
  String loggedInUsername = '';

  @override
  void initState() {
    super.initState();
    _loadUsername().then((_) {
      _preloadData();
    });
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedInUsername = prefs.getString('username') ?? 'default_username';
    });
  }

  Future<void> _preloadData() async {
    await _fetchData('3D');
    await _fetchData('5D');
    await _fetchData('1M');
    await _fetchData('1Y');
    await _fetchData('5Y');
  }

  Future<void> _fetchData(String interval) async {
    List<SalesData> fetchedData;
    switch (interval) {
      case '3D':
        fetchedData = await fetchSalesData('ThreeDays');
        break;
      case '5D':
        fetchedData = await fetchSalesData('FiveDays');
        break;
      case '1M':
        fetchedData = await fetchSalesData('FourMonths');
        break;
      case '1Y':
        fetchedData = await fetchSalesData('Year');
        break;
      case '5Y':
        fetchedData = await fetchSalesData('FiveYears');
        break;
      default:
        fetchedData = [];
    }
    if (mounted) {
      setState(() {
        _salesDataMap[interval] = fetchedData;
      });
    }
  }

  Future<List<SalesData>> fetchSalesData(String reportType) async {
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/sales_report_graph/get_sales_report.php?username=$loggedInUsername&reportType=$reportType');

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          final List<dynamic> salesData = jsonData['data'];

          return salesData.map((row) {
            DateTime date;
            if (reportType == 'FiveYears') {
              date = DateTime.utc(row['Year']);
            } else if (reportType == 'FourMonths' || reportType == 'Year') {
              date = DateFormat('yyyy-MM').parseUtc(row['Date'] ?? '');
            } else {
              date = DateFormat('yyyy-MM-dd').parseUtc(row['Date'] ?? '');
            }

            return SalesData(
              date: date.toLocal(),
              totalSales: (row['TotalSales'] as num).toDouble(),
            );
          }).toList();
        } else {
          throw Exception('API Error: ${jsonData['message']}');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      developer.log('Error fetching sales data: $e');
      return [];
    }
  }

  void _refreshData() async {
    await _fetchData(_selectedInterval);
  }

  Widget _buildQuickAccessButton(String interval) {
    final bool isSelected = _selectedInterval == interval;
    return TextButton(
      onPressed: () {
        setState(() {
          _selectedInterval = interval;
          _refreshData();
        });
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            return isSelected
                ? const Color(0xff0175FF)
                : const Color(0xFFD9D9D9);
          },
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            return isSelected ? Colors.white : Colors.black;
          },
        ),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
      child: Text(interval, style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sales Report',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAccessButton('3D'),
                  const SizedBox(width: 10),
                  _buildQuickAccessButton('5D'),
                  const SizedBox(width: 10),
                  _buildQuickAccessButton('1M'),
                  const SizedBox(width: 10),
                  _buildQuickAccessButton('1Y'),
                  const SizedBox(width: 10),
                  _buildQuickAccessButton('5Y'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _salesDataMap[_selectedInterval] != null
                ? _salesDataMap[_selectedInterval]!.isNotEmpty
                    ? ListView.builder(
                        itemCount: _salesDataMap[_selectedInterval]!.length,
                        itemBuilder: (context, index) {
                          SalesData data = _salesDataMap[_selectedInterval]![index];
                          String dateText = '';
                          switch (_selectedInterval) {
                            case '3D':
                            case '5D':
                              dateText = DateFormat('dd-MM-yyyy').format(data.date);
                              break;
                            case '1M':
                            case '1Y':
                              dateText = DateFormat('MMM yyyy').format(data.date);
                              break;
                            case '5Y':
                              dateText = data.date.year.toString();
                              break;
                          }

                          final int salesInt = data.totalSales.toInt();
                          final String formattedSales = 'RM${salesInt.toString().replaceAllMapped(
                            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[1]},'
                          )}';

                          return ListTile(
                            title: Text(dateText),
                            trailing: Text(formattedSales),
                          );
                        },
                      )
                    : const Center(
                        child: Text('No data available'),
                      )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
        ],
      ),
    );
  }
}

class SalesData {
  final DateTime date;
  final double totalSales;

  SalesData({
    required this.date,
    required this.totalSales,
  });
}