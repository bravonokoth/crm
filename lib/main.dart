import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ClientFlow/api/firebase_api.dart';
import 'package:ClientFlow/cart_page.dart';
import 'package:ClientFlow/firebase_options.dart';
import 'package:ClientFlow/home_page.dart';
import 'package:ClientFlow/notification_page.dart';
import 'package:ClientFlow/login_page.dart';
import 'package:ClientFlow/profile_page.dart';
import 'package:ClientFlow/sales_order_page.dart';
import 'package:ClientFlow/starting_page.dart';
import 'db_sqlite.dart';
import 'products_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import 'package:ClientFlow/model/cart_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io' show Platform;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env'); // Load .env file only once
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseApi().initNotifications();

  if (!Platform.isIOS) {
    initializeLocalNotifications();
  } else {
    developer.log('Skipping iOS notification initialization');
  }

  if (await shouldRequestExactAlarmPermission()) {
    await requestExactAlarmPermission();
  }

  handleInitialMessage();
  setupNotificationListeners();

  await DatabaseHelper.database;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartModel()),
      ],
      child: const MyApp(),
    ),
  );
}

void initializeLocalNotifications() async {
  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@drawable/clientflow');
  const InitializationSettings settings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(settings);
}

Future<bool> shouldRequestExactAlarmPermission() async {
  return await Permission.scheduleExactAlarm.isDenied;
}

Future<void> requestExactAlarmPermission() async {
  if (await Permission.scheduleExactAlarm.request().isGranted) {
    developer.log('SCHEDULE_EXACT_ALARM permission granted');
  } else {
    developer.log('SCHEDULE_EXACT_ALARM permission denied');
  }
}

void handleInitialMessage() {
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      Future.delayed(Duration.zero, () {
        navigatorKey.currentState?.pushNamed(NotificationsPage.route, arguments: message);
      });
    }
  });
}

void setupNotificationListeners() {
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    developer.log("onMessageOpenedApp: $message");
    Future.delayed(Duration.zero, () {
      navigatorKey.currentState?.pushNamed(NotificationsPage.route, arguments: message);
    });
  });
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
      home: isOffline ? NoInternetScreen() :  const StartingPage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/sales': (context) => const SalesOrderPage(),
        '/product': (context) => const ProductsScreen(),
        '/cart': (context) => const CartPage(),
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