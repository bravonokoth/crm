import 'package:ClientFlow/order_details_page.dart';
import 'package:ClientFlow/sales_order_page.dart';
import 'package:ClientFlow/model/cs_order_model.dart';
import 'package:flutter/material.dart';
import 'package:ClientFlow/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ListOrderPage extends StatefulWidget {
  const ListOrderPage({super.key});

  @override
  State<ListOrderPage> createState() => _ListOrderPageState();
}

class _ListOrderPageState extends State<ListOrderPage> {
  List<Order> orders = [];
  String? staffId;
  String? userName;
  bool _isLoading = false;

  // Orders count
  int ordersTotal = 0;
  int ordersProcessing = 0;
  int ordersDelivered = 0;
  int ordersReturned = 0;

  String? authToken; // Store the auth token

    String truncateWords(String text, int wordLimit) {
    List<String> words = text.split(' ');
    if (words.length > wordLimit) {
      return '${words.sublist(0, wordLimit).join(' ')}...';
    }
    return text;
  }



  @override
  void initState() {
    super.initState();
    getUser();
  }



 Future<void> getUser() async {
  setState(() {
    _isLoading = true; 
  });

  final prefs = await SharedPreferences.getInstance();
  setState(() {
    staffId = prefs.getString('id');
    userName = prefs.getString('userName');
    authToken = prefs.getString('token'); // Ensure token is also fetched if needed
  });



    await fetchOrderData();
   
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ... (other methods remain unchanged)

 

  Future<void> fetchOrderData() async {
  
if (staffId == null) {
  throw Exception('Staff ID is null');
} else if (staffId!.isEmpty) {
  throw Exception('Staff ID is empty');
}



  String apiUrl = 'https://bf1c-102-215-77-46.ngrok-free.app/api/orders';
  try {
    final Uri ordersUrl = Uri.parse(apiUrl).replace(queryParameters: {
      'user_id': staffId!, // Use null assertion operator (!)
    });
    final response = await http.get(
      ordersUrl,
      headers: <String, String>{
        'Authorization': 'Bearer $authToken', 
        'Content-Type': 'application/json',
      },
    );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> ordersJson = data['data'] ?? []; // Assuming the response has a 'data' field
        setState(() {
          orders = ordersJson.map((json) => Order.fromJson(json)).toList();
        });
      } else {
        throw Exception('Failed to load orders from the server');
      }
    } catch (error) {
      throw Exception('Failed to fetch orders: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      body: RefreshIndicator(  
        onRefresh: getUser,
        child: SafeArea(
          child: Stack(
            children: [
              CustomPaint(
                size: Size(size.width, size.height), 
                painter: RPSCustomPainter(),
              ),
              _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : Container(
                  padding: const EdgeInsets.only(left: 15, right: 15),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 20.h,),
                        Container(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order_ = orders[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SalesOrderPage(),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black38,
                                        blurRadius: 4,
                                        offset: Offset(0, 3), 
                                      ),
                                    ]
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'For: ${order_.company}',
                                                    style: GoogleFonts.poppins(
                                                      textStyle: TextStyle(
                                                        fontSize: 10.sp,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 1.5.h,),
                                            Row(
                                              children: [
                                                SizedBox(width: 12.h,
                                                  child: Text(
                                                    'Client',
                                                    style: GoogleFonts.poppins(
                                                      textStyle: TextStyle(
                                                        fontSize: 8.sp,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    order_.company,
                                                    style: GoogleFonts.poppins(
                                                      textStyle: TextStyle(
                                                        fontSize: 8.sp,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    maxLines: 2, 
                                                    overflow: TextOverflow.ellipsis, 
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: 12.h,
                                                  child: Text(
                                                    'Created',
                                                    style: GoogleFonts.poppins(
                                                      textStyle: TextStyle(
                                                        fontSize: 8.sp,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  truncateWords(order_.dateCreated, 4),
                                                   style: GoogleFonts.poppins(
                                                    textStyle: TextStyle(
                                                        fontSize: 8.sp,
                                                        fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: 12.h,
                                                  child: Text(
                                                    'Delivery Date',
                                                    style: GoogleFonts.poppins(
                                                      textStyle: TextStyle(
                                                        fontSize: 8.sp,
                                                        fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '${order_.deliveryDate}',
                                                  style: GoogleFonts.poppins(
                                                    textStyle: TextStyle(
                                                        fontSize: 8.sp,
                                                        fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: 12.h,
                                                  child: Text(
                                                    'Total(KES)',
                                                    style: GoogleFonts.poppins(
                                                      textStyle: TextStyle(
                                                        fontSize: 8.sp,
                                                        fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                              NumberFormat.currency(
                                                              locale: 'en_KE',
                                                              symbol: 'KES', 
                                              ).format(double.parse(order_.total)),
                                              style: GoogleFonts.poppins(
                                                textStyle: TextStyle(
                                                  fontSize: 8.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                              ],
                                            ),
                                            // Here you would add the items list if you wanted to show them
                                            // But since you mentioned not to include descriptions:
                                            SizedBox(height: 1.h,),
                                            Text(
                                              'Items: ${order_.items.length}',
                                              style: GoogleFonts.poppins(
                                                textStyle: TextStyle(
                                                  fontSize: 8.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 1.h,),
                                      Container(
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                            bottomRight: Radius.circular(15),
                                            bottomLeft: Radius.circular(15),
                                          ),
                                          color: Color(0xffD7D7D7),
                                        ),
                                        padding: const EdgeInsets.all(15),
                                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Created by',
                                                  style: GoogleFonts.poppins(
                                                    textStyle: TextStyle(
                                                        fontSize: 8.sp,
                                                        fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                                Text(
                                                  '$userName',
                                                  style: GoogleFonts.poppins(
                                                    textStyle: TextStyle(
                                                        fontSize: 8.sp,
                                                        fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Status',
                                                  style: GoogleFonts.poppins(
                                                    textStyle: TextStyle(
                                                        fontSize: 8.sp,
                                                        fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                                Text(
                                                  '${order_.status}',
                                                  style: GoogleFonts.poppins(
                                                    textStyle: TextStyle(
                                                        fontSize: 8.sp,
                                                        fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}




class RPSCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint0Fill = Paint()..style = PaintingStyle.fill;
    paint0Fill.color = const Color(0xffF5F5F5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint0Fill);

    Path path_1 = Path();
    path_1.moveTo(0, size.height * 0.6829399);
    path_1.cubicTo(
        0,
        size.height * 0.6829399,
        size.width * 0.2295658,
        size.height * 0.6717189,
        size.width * 0.3581395,
        size.height * 0.6416309);
    path_1.cubicTo(
        size.width * 0.5106674,
        size.height * 0.6059378,
        size.width * 0.5318977,
        size.height * 0.5432468,
        size.width * 0.6825581,
        size.height * 0.5059013);
    path_1.cubicTo(size.width * 0.7971744, size.height * 0.4774903, size.width,
        size.height * 0.4592275, size.width, size.height * 0.4592275);
    path_1.lineTo(size.width, size.height * 0.5842275);
    path_1.cubicTo(
        size.width,
        size.height * 0.5842275,
        size.width * 0.7976814,
        size.height * 0.6005139,
        size.width * 0.6825581,
        size.height * 0.6276824);
    path_1.cubicTo(
        size.width * 0.5335093,
        size.height * 0.6628573,
        size.width * 0.5099930,
        size.height * 0.7244528,
        size.width * 0.3581395,
        size.height * 0.7569742);
    path_1.cubicTo(size.width * 0.2287335, size.height * 0.7846878, 0,
        size.height * 0.7902361, 0, size.height * 0.7902361);
    path_1.lineTo(0, size.height * 0.6829399);
    path_1.close();

    Paint paint1Fill = Paint()..style = PaintingStyle.fill;
    paint1Fill.color = AppTheme.primaryColor;
    canvas.drawPath(path_1, paint1Fill);

    Path path_2 = Path();
    path_2.moveTo(0, size.height * 0.8159871);
    path_2.cubicTo(
        0,
        size.height * 0.8159871,
        size.width * 0.2295658,
        size.height * 0.8031567,
        size.width * 0.3581395,
        size.height * 0.7730687);
    path_2.cubicTo(
        size.width * 0.5106674,
        size.height * 0.7373755,
        size.width * 0.5423628,
        size.height * 0.6859506,
        size.width * 0.6930233,
        size.height * 0.6486052);
    path_2.cubicTo(size.width * 0.8076395, size.height * 0.6201942, size.width,
        size.height * 0.6062232, size.width, size.height * 0.6062232);
    path_2.lineTo(size.width, size.height * 0.6432403);
    path_2.cubicTo(
        size.width,
        size.height * 0.6432403,
        size.width * 0.7976814,
        size.height * 0.6595268,
        size.width * 0.6825581,
        size.height * 0.6866953);
    path_2.cubicTo(
        size.width * 0.5335093,
        size.height * 0.7218702,
        size.width * 0.5099930,
        size.height * 0.7834657,
        size.width * 0.3581395,
        size.height * 0.8159871);
    path_2.cubicTo(size.width * 0.2287335, size.height * 0.8437006, 0,
        size.height * 0.8492489, 0, size.height * 0.8492489);
    path_2.lineTo(0, size.height * 0.8159871);
    path_2.close();

    Paint paint2Fill = Paint()..style = PaintingStyle.fill;
    paint2Fill.color = AppTheme.primaryColor;
    canvas.drawPath(path_2, paint2Fill);

    Path path_3 = Path();
    path_3.moveTo(0, size.height * 0.5992489);
    path_3.cubicTo(
        0,
        size.height * 0.5992489,
        size.width * 0.2295658,
        size.height * 0.6062682,
        size.width * 0.3581395,
        size.height * 0.5761803);
    path_3.cubicTo(
        size.width * 0.5106674,
        size.height * 0.5404871,
        size.width * 0.5470140,
        size.height * 0.4804785,
        size.width * 0.6976744,
        size.height * 0.4431330);
    path_3.cubicTo(size.width * 0.8122907, size.height * 0.4147221, size.width,
        size.height * 0.3959227, size.width, size.height * 0.3959227);
    path_3.lineTo(size.width, size.height * 0.4431330);
    path_3.cubicTo(
        size.width,
        size.height * 0.4431330,
        size.width * 0.7976814,
        size.height * 0.4604925,
        size.width * 0.6825581,
        size.height * 0.4876609);
    path_3.cubicTo(
        size.width * 0.5335093,
        size.height * 0.5228358,
        size.width * 0.5099930,
        size.height * 0.5887232,
        size.width * 0.3581395,
        size.height * 0.6212446);
    path_3.cubicTo(size.width * 0.2287335, size.height * 0.6489582, 0,
        size.height * 0.6641631, 0, size.height * 0.6641631);
    path_3.lineTo(0, size.height * 0.5992489);
    path_3.close();

    Paint paint3Fill = Paint()..style = PaintingStyle.fill;
    paint3Fill.color = AppTheme.primaryColor;
    canvas.drawPath(path_3, paint3Fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}