import 'package:flutter/material.dart';

class CustomerDropdown extends StatefulWidget {
  final List<Map<String, dynamic>> crmCustomers;
  final Function(String?) onChanged;
  final InputDecoration? decoration;

  const CustomerDropdown({
    Key? key,
    required this.crmCustomers,
    required this.onChanged,
    this.decoration,
  }) : super(key: key);

  @override
  State<CustomerDropdown> createState() => _CustomerDropdownState();
}

class _CustomerDropdownState extends State<CustomerDropdown> {
  String? selectedCustomer;
  String? filterText;

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = widget.crmCustomers.where((customer) {
      final companyName = customer['company']?.toLowerCase() ?? '';
      final filter = filterText?.toLowerCase() ?? '';
      return companyName.contains(filter);
    }).toList();

    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Search for Customer',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          onChanged: (text) {
            setState(() {
              filterText = text;
            });
          },
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          decoration: widget.decoration ?? InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.white,
            filled: true,
          ),
          isExpanded: true,
          hint: const Text('Select Customer'),
          value: selectedCustomer,
          items: filteredCustomers.map((customer) {
            return DropdownMenuItem<String>(
              value: customer['company'],
              child: Text(customer['company']!),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedCustomer = value;
            });
            widget.onChanged(value); 
          },
        ),
      ],
    );
  }
}