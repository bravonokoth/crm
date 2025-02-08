

import 'package:ClientFlow/list_order_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ClientFlow/home_page.dart';
import 'package:ClientFlow/notification_page.dart';
import 'package:ClientFlow/login_page.dart';
import 'package:ClientFlow/profile_page.dart';
import 'package:ClientFlow/sales_order_page.dart';
import 'package:ClientFlow/starting_page.dart';
import 'products_screen.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import 'package:ClientFlow/model/cart_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io' show Platform;
import 'package:sizer/sizer.dart'; // Add this import for Sizer

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Removed .env initialization
  // await dotenv.load(fileName: '.env');

  if (!Platform.isIOS) {
    initializeLocalNotifications();
  } else {
    developer.log('Skipping iOS notification initialization');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartModel()),
      ],
      child: Sizer(
        builder: (context, orientation, deviceType) {
          return const MyApp();
        },
      ),
    ),
  );
}

void initializeLocalNotifications() async {
  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@drawable/clientflow');
  const InitializationSettings settings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(settings);
}



class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  void _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() => isOffline = result == ConnectivityResult.none);

    Connectivity().onConnectivityChanged.listen((results) {
      setState(() => isOffline = results.contains(ConnectivityResult.none));
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartModel = Provider.of<CartModel>(context, listen: false);
    cartModel.initializeCartCount();

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: isOffline ? const NoInternetScreen() : const StartingPage(),
      routes: {
        '/home': (context) => HomePage(),
        '/sales': (context) => const SalesOrderPage(),
        '/product': (context) => const ProductsScreen(),
        '/cart': (context) => const ListOrderPage(),
        '/login': (context) => LoginPage(),
        '/profile': (context) => const ProfilePage(),
        NotificationsPage.route: (context) => const NotificationsPage(),
      },
    );
  }
}

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("No Internet Connection")),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text('No internet connection available.', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text('Please check your connection and try again.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
