import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final messagingInstance = FirebaseMessaging.instance;
  final fcmToken = await messagingInstance.getToken();
  debugPrint('FCM TOKEN: $fcmToken');

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await _initializePlatformSpecifics(
      flutterLocalNotificationsPlugin, messagingInstance);
  _setupForegroundNotificationHandling(flutterLocalNotificationsPlugin);

  runApp(const MyApp());
}

Future<void> _initializePlatformSpecifics(
    FlutterLocalNotificationsPlugin notificationsPlugin,
    FirebaseMessaging messagingInstance) async {
  if (Platform.isIOS) {
    await messagingInstance.requestPermission();
    await messagingInstance.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);
  } else {
    const androidChannel = AndroidNotificationChannel(
      'default_notification_channel',
      'プッシュ通知のチャンネル名',
      importance: Importance.max,
    );
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }
}

void _setupForegroundNotificationHandling(
    FlutterLocalNotificationsPlugin notificationsPlugin) {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (Platform.isAndroid) {
      await notificationsPlugin.show(
        0,
        notification!.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'default_notification_channel',
            'プッシュ通知のチャンネル名',
            importance: Importance.max,
            icon: android?.smallIcon,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  });

  notificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (NotificationResponse details) {
      final payload = details.payload;
      if (payload != null) {
        final payloadMap = json.decode(payload) as Map<String, dynamic>;
        debugPrint(payloadMap.toString());
      }
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
