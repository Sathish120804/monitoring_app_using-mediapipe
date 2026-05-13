import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // ======================================
  // NOTIFICATION INITIALIZATION
  // ======================================

  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings =
  InitializationSettings(
    android: androidSettings,
  );

  await notificationsPlugin.initialize(settings);

  runApp(const MyApp());
}

// ======================================
// NOTIFICATION PLUGIN
// ======================================

final FlutterLocalNotificationsPlugin notificationsPlugin =
FlutterLocalNotificationsPlugin();

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: "Healthcare Monitor",

      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      home: const Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {

  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {

  // ======================================
  // RENDER CLOUD SERVER
  // ======================================

  final String url =
      "https://healthcare-ai-server.onrender.com/data";

  int activeIndex = 0;

  String message = "Waiting For Patient Data...";

  String lastAction = "";

  bool connected = false;

  Timer? timer;

  // ======================================
  // NOTIFICATION CONTROL
  // ======================================

  DateTime lastNotificationTime =
  DateTime.now();

  // ======================================
  // INIT
  // ======================================

  @override
  void initState() {

    super.initState();

    initApp();
  }

  // ======================================
  // INITIALIZE APP
  // ======================================

  Future<void> initApp() async {

    // Notification Permission

    await Permission.notification.request();

    // START FETCHING

    startFetching();
  }

  // ======================================
  // FETCH DATA EVERY 300ms
  // ======================================

  void startFetching() {

    timer = Timer.periodic(

      const Duration(milliseconds: 300),

          (_) {

        fetchData();
      },
    );
  }

  // ======================================
  // FETCH SERVER DATA
  // ======================================

  Future<void> fetchData() async {

    try {

      final response = await http

          .get(
        Uri.parse(url),
      )

          .timeout(
        const Duration(seconds: 2),
      );

      if (response.statusCode != 200) {

        setDisconnected();

        return;
      }

      final data =
      json.decode(response.body);

      if (data == null ||
          data["value"] == null) {

        setDisconnected();

        return;
      }

      String action =
      data["value"]
          .toString()
          .toUpperCase();

      int index =
      mapActionToIndex(action);

      // ======================================
      // NOTIFICATION CONTROL
      // ======================================

      if (

      action != "NONE" &&

          action != lastAction &&

          DateTime.now()

              .difference(lastNotificationTime)

              .inSeconds > 2

      ) {

        lastAction = action;

        lastNotificationTime =
            DateTime.now();

        await showNotification(action);
      }

      // ======================================
      // UPDATE UI ONLY IF NEEDED
      // ======================================

      if (

      activeIndex != index ||

          !connected ||

          message != getMessage(action)

      ) {

        if (!mounted) return;

        setState(() {

          connected = true;

          activeIndex = index;

          message = getMessage(action);
        });
      }

    } catch (e) {

      setDisconnected();
    }
  }

  // ======================================
  // DISCONNECTED STATUS
  // ======================================

  void setDisconnected() {

    if (!mounted) return;

    setState(() {

      connected = false;

      message = "Server Connection Failed";
    });
  }

  // ======================================
  // SHOW NOTIFICATION
  // ======================================

  Future<void> showNotification(
      String action,
      ) async {

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(

      'healthcare_channel',

      'Healthcare Alerts',

      channelDescription:
      'Healthcare Emergency Alerts',

      importance: Importance.max,

      priority: Priority.high,

      playSound: true,
    );

    const NotificationDetails details =
    NotificationDetails(
      android: androidDetails,
    );

    await notificationsPlugin.show(

      DateTime.now().millisecond,

      "Patient Alert",

      action,

      details,
    );
  }

  // ======================================
  // MAP ACTION TO CARD
  // ======================================

  int mapActionToIndex(String action) {

    switch (action) {

      case "CAMERA_CONNECTED":
        return 0;

      case "FOOD":
        return 1;

      case "RESTROOM":
        return 2;

      case "EMERGENCY":
        return 3;

      case "ELECTRICAL":
        return 4;

      default:
        return 0;
    }
  }

  // ======================================
  // STATUS MESSAGE
  // ======================================

  String getMessage(String action) {

    switch (action) {

      case "CAMERA_CONNECTED":
        return "📷 DroidCam Connected";

      case "FOOD":
        return "Food Request 🍽";

      case "RESTROOM":
        return "Restroom Needed 🚻";

      case "EMERGENCY":
        return "🚨 Emergency Alert";

      case "ELECTRICAL":
        return "Electrical Assistance 🔌";

      default:
        return "Patient Resting 💤";
    }
  }

  // ======================================
  // CARD WIDGET
  // ======================================

  Widget card(
      int i,
      String title,
      IconData icon,
      Color color,
      ) {

    bool active = i == activeIndex;

    return AnimatedContainer(

      duration:
      const Duration(milliseconds: 250),

      margin: const EdgeInsets.all(10),

      decoration: BoxDecoration(

        color:
        active ? color : Colors.white,

        borderRadius:
        BorderRadius.circular(18),

        boxShadow: [

          BoxShadow(

            color:
            active
                ? color.withOpacity(0.4)
                : Colors.black12,

            blurRadius:
            active ? 15 : 5,
          )
        ],
      ),

      child: Column(

        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [

          Icon(

            icon,

            size: 45,

            color:
            active
                ? Colors.white
                : color,
          ),

          const SizedBox(height: 12),

          Text(

            title,

            style: TextStyle(

              fontWeight:
              FontWeight.bold,

              fontSize: 15,

              color:
              active
                  ? Colors.white
                  : Colors.black,
            ),
          )
        ],
      ),
    );
  }

  // ======================================
  // DISPOSE
  // ======================================

  @override
  void dispose() {

    timer?.cancel();

    super.dispose();
  }

  // ======================================
  // UI
  // ======================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(0xffF4F7FB),

      appBar: AppBar(

        title:
        const Text("Healthcare Monitor"),

        centerTitle: true,

        backgroundColor:
        Colors.blueAccent,
      ),

      body: Column(

        children: [

          const SizedBox(height: 20),

          // STATUS CARD

          Container(

            margin:
            const EdgeInsets.symmetric(
                horizontal: 20),

            padding:
            const EdgeInsets.all(16),

            decoration: BoxDecoration(

              color:
              connected
                  ? Colors.blueAccent
                  : Colors.red,

              borderRadius:
              BorderRadius.circular(18),
            ),

            child: Row(

              children: [

                Icon(

                  connected
                      ? Icons.monitor_heart
                      : Icons.cloud_off,

                  color: Colors.white,

                  size: 30,
                ),

                const SizedBox(width: 12),

                Expanded(

                  child: Text(

                    message,

                    style: const TextStyle(

                      color: Colors.white,

                      fontSize: 16,

                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          // GRID

          Expanded(

            child: GridView.count(

              crossAxisCount: 2,

              children: [

                card(
                  0,
                  "CONNECTED",
                  Icons.videocam,
                  Colors.grey,
                ),

                card(
                  1,
                  "FOOD",
                  Icons.restaurant,
                  Colors.green,
                ),

                card(
                  2,
                  "RESTROOM",
                  Icons.wc,
                  Colors.blue,
                ),

                card(
                  3,
                  "EMERGENCY",
                  Icons.warning,
                  Colors.red,
                ),

                card(
                  4,
                  "ELECTRICAL",
                  Icons.electrical_services,
                  Colors.orange,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}