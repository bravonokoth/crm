import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CustomerSalesReport extends StatefulWidget {
  final int customerId;

  const CustomerSalesReport({super.key, required this.customerId});

  @override
  _CustomerSalesReportState createState() => _CustomerSalesReportState();
}

class _CustomerSalesReportState extends State<CustomerSalesReport> {
  final Map<String, List<SalesData>> _salesDataMap = {};
  String _selectedInterval = '3D';

  @override
  void initState() {
    super.initState();
    _preloadData();
  }

  Future<void> _preloadData() async {
    await _fetchData('3D');
    await _fetchData('5D');
    await _fetchData('1M');
    await _fetchData('1Y');
    await _fetchData('5Y');
  }

  Future<void> _fetchData(String interval) async {
    if (widget.customerId == 0) {
      return;
    }

    List<SalesData> fetchedData = [];
    switch (interval) {
      case '3D':
        fetchedData = await fetchCustomerSalesData('ThreeDays', widget.customerId);
        break;
      case '5D':
        fetchedData = await fetchCustomerSalesData('FiveDays', widget.customerId);
        break;
      case '1M':
        fetchedData = await fetchCustomerSalesData('OneMonth', widget.customerId);
        break;
      case '1Y':
        fetchedData = await fetchCustomerSalesData('Year', widget.customerId);
        break;
      case '5Y':
        fetchedData = await fetchCustomerSalesData('FiveYears', widget.customerId);
        break;
    }

    if (mounted) {
      setState(() {
        _salesDataMap[interval] = fetchedData;
      });
    }
  }

  Future<List<SalesData>> fetchCustomerSalesData(String reportType, int customerId) async {
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/customer_insight_graph/get_customer_graph.php?reportType=$reportType&customerId=$customerId');

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success' && jsonData['data'] is List) {
          return (jsonData['data'] as List).map<SalesData>((row) {
            DateTime? date;
            try {
              if (reportType == 'FiveYears') {
                date = DateTime.utc(row['Year'] ?? DateTime.now().year);
              } else if (reportType == 'OneMonth' || reportType == 'Year') {
                date = row['Date'] != null ? DateFormat('yyyy-MM').parseUtc(row['Date']) : DateTime.now();
              } else {
                date = row['FormattedDate'] != null ? DateFormat('yyyy-MM-dd').parseUtc(row['FormattedDate']) : DateTime.now();
              }
            } catch (e) {
              date = DateTime.now();
            }

            return SalesData(
              date: date.toLocal(),
              totalSales: (row['TotalSales'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList();
        } else {
          throw Exception('API Error: ${jsonData['message']}');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching customer sales data: $e');
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
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            return isSelected ? const Color(0xFF047CBD) : const Color(0xFFD9D9D9);
          },
        ),
        foregroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            return isSelected ? Colors.white : Colors.black;
          },
        ),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
      child: Text(interval, style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                          (Match m) => '${m[1]},',
                        )}';

                        return ListTile(
                          title: Text(dateText),
                          trailing: Text(formattedSales),
                        );
                      },
                    )
                  : const Center(child: Text('No data available'))
              : const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

class SalesData {
  final DateTime date;
  final double totalSales;

  SalesData({required this.date, required this.totalSales});
}
