// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:get/get.dart';

// late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
// RxBool isAppInBackground = false.obs;

// void initializeNotifications() {
//   flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');

//   const InitializationSettings initializationSettings = InitializationSettings(
//     android: initializationSettingsAndroid,
//   );

//   flutterLocalNotificationsPlugin.initialize(
//     initializationSettings,
//   );
// }

// void showLocalNotification(String title, String body) async {
//   const AndroidNotificationDetails androidPlatformChannelSpecifics =
//       AndroidNotificationDetails(
//     'pubnub_channel_id',
//     'PubNub Notifications',
//     channelDescription: 'Notifications from PubNub',
//     importance: Importance.max,
//     priority: Priority.high,
//     ticker: 'ticker',
//   );

//   const NotificationDetails platformChannelSpecifics =
//       NotificationDetails(android: androidPlatformChannelSpecifics);

//   await flutterLocalNotificationsPlugin.show(
//     0,
//     title,
//     body,
//     platformChannelSpecifics,
//   );
// }
