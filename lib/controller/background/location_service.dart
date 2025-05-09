import 'dart:async';
import 'dart:convert';
import 'package:ace_routes/controller/connectivity/network_controller.dart';
import 'package:ace_routes/controller/event_controller.dart';
import 'package:ace_routes/model/event_model.dart';
import 'package:ace_routes/model/login_model/token_api_response.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ace_routes/core/colors/Constants.dart';
import 'package:ace_routes/database/Tables/api_data_table.dart';
import 'package:ace_routes/database/Tables/event_table.dart';
import 'package:ace_routes/database/Tables/status_table.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

// Global Variables
String locChangeThreshold = "10"; // Default
String syncIntervalMinutes = "10"; // Default
List<Map<String, String>> locationData = [];

final networkController = Get.find<NetworkController>();
final EventController event = Get.find<EventController>();

// ✅ **1. Load Data from SQLite & Save to SharedPreferences**
Future<void> fetchDataFromLogin() async {
  print("not even called : ");
  try {
    List<TokenApiReponse> loginDataList = await ApiDataTable.fetchData();
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    for (var data in loginDataList) {
      await prefs.setString("locChangeThreshold", data.locationChange);
      await prefs.setString("syncIntervalMinutes", data.gpsSync);
      print("✅ Saved locChangeThreshold: ${data.locationChange}");
      print("✅ Saved syncIntervalMinutes: ${data.gpsSync}");
    }

    List<Event> localEvents = await EventTable.fetchEvents();

    Set<String> wkfSet =
        localEvents.map((event) => event.wkf.toString()).toSet();
    Map<String, String?> fetchedStatus =
        await StatusTable.fetchNamesByIds(wkfSet.toList());

    // Exclude "Complete" statuses
    List<String> validOrderIds = localEvents
        .where((event) => fetchedStatus[event.wkf] != "Complete")
        .map((event) => event.id.toString())
        .take(2)
        .toList();

    String lstoid = validOrderIds.isNotEmpty ? validOrderIds[0] : "0";
    String nxtoid = validOrderIds.length > 1 ? validOrderIds[1] : "0";

    await prefs.setString("lstoid", lstoid);
    await prefs.setString("nxtoid", nxtoid);
    await prefs.setString("nsp", nsp);
    await prefs.setString("token", token);
    await prefs.setString("rid", rid);
    print("✅ Saved lstoid: ${lstoid} $nsp $token");
    print("✅ Saved nxtoid: ${nxtoid}");
  } catch (e) {
    print("❌ Error fetching login data: $e");
  }
}

// ✅ **2. Initialize Background Service**
Future<void> initializeService() async {
  print("🔹 Initializing Background Service...");
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true, // Auto-start when app opens
    ),
    iosConfiguration: IosConfiguration(),
  );
}

// ✅ **3. Start Background Service (Reads from SharedPreferences)**
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    if (service is AndroidServiceInstance) {
      service.on('stopService').listen((event) {
        service.stopSelf();
      });

      // 🔔 Required for Foreground Service
      service.setForegroundNotificationInfo(
        title: "Ace Routes Background Service",
        content: "Tracking location in the background...",
      );
    }

    _initializeBackgroundTasks(service);
  } catch (e) {
    print(
        "❌ Error in background service onStart: $e"); // 🔧 FIX: Prevent silent crash
  }
}

Future<void> _initializeBackgroundTasks(ServiceInstance service) async {
  print("Now Start the background task:");
  try {
   
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    locChangeThreshold = prefs.getString("locChangeThreshold") ?? "10";
    syncIntervalMinutes = prefs.getString("syncIntervalMinutes") ?? "10";
    print(
        "Now calling stat location update api and sending data on server $locChangeThreshold $syncIntervalMinutes ");
    await _startLocationUpdates();
    await _sendDataToServer();

    Timer.periodic(Duration(minutes: int.tryParse(syncIntervalMinutes) ?? 10),
        (timer) async {
      await _startLocationUpdates();
      await _sendDataToServer();
    });

    await _waitUntilMidnight();
    await networkController.syncAll();
    await event.fetchEvents();
  } catch (e) {
    print("❌ Error in background tasks: $e");
  }
}

// ⏰ Wait until 12:00 AM
Future<void> _waitUntilMidnight() async {
  final now = DateTime.now();
  final nextMidnight = DateTime(now.year, now.month, now.day + 1);
  final durationUntilMidnight = nextMidnight.difference(now);

  print("⏳ Waiting until midnight (${nextMidnight.toLocal()})");
  await Future.delayed(durationUntilMidnight);
}

// ✅ **4. Start Location Updates**
Future<void> _startLocationUpdates() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print("❌ Location services are disabled.");
    return;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      print("❌ Location permissions are permanently denied.");
      return;
    }
  }

  Geolocator.getPositionStream(
    locationSettings: LocationSettings(
      distanceFilter: int.tryParse(locChangeThreshold) ?? 10, // Default 10m
      accuracy: LocationAccuracy.high,
    ),
  ).listen((Position position) {
    _recordLocation(position);
  });
}

// ✅ **5. Store Location Changes**
void _recordLocation(Position position) async {
  DateTime now = DateTime.now();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  String lstoid = prefs.getString("lstoid") ?? "10";
  String nxtoid = prefs.getString("nxtoid") ?? "10";

  locationData.add({
    "lat": position.latitude.toString(),
    "lon": position.longitude.toString(),
    "timestamp": now.millisecondsSinceEpoch.toString(),
    "lstoid": lstoid,
    "nxtoid": nxtoid,
  });

  print("📍 Location recorded: ${position.latitude}, ${position.longitude}");
}

// ✅ **6. Send Batched Location Data to the Server**
// Updated API call with validation for necessary data
Future<void> _sendDataToServer() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Ensure necessary data is present
  String? token = prefs.getString("token");
  String? nsp = prefs.getString("nsp");
  String? rid = prefs.getString("rid");

  print(" token is : $token $nsp $rid ");

  if (token == null || nsp == null || rid == null) {
    print(
        "❌ Missing necessary data for API call: token=$token, nsp=$nsp, rid=$rid");
    return; // Skip the API call if necessary data is missing
  }

  if (locationData.isEmpty) return;

  List<String> geoList = [];
  List<String> timestampList = [];
  List<String> lstoidList = [];
  List<String> nxtoidList = [];

  for (var entry in locationData) {
    geoList.add("${entry['lat']},${entry['lon']}");
    timestampList.add(entry['timestamp'].toString());
    lstoidList.add(entry['lstoid'] ?? "0");
    nxtoidList.add(entry['nxtoid'] ?? "0");
  }

  print("📡 Sending Location Data...");

  String url =
      "https://portal.aceroute.com/mobi?token=$token&nspace=$nsp&rid=$rid&action=saveresgeo&geo=${geoList.join('|')}&stmp=${timestampList.join('|')}&lstoid=${lstoidList.join('|')}&nxtoid=${nxtoidList.join('|')}";

  print("✅ API Call URL: $url");

  try {
    var response = await http.get(Uri.parse(url));
    print("🔹 Response Code: ${response.statusCode}");
    print("🔹 Response Body: ${response.body}");

    if (response.statusCode == 200) {
      // Parse XML instead of JSON
      var document = xml.XmlDocument.parse(response.body);
      var success = document.findAllElements('success').first.innerText;
      var id = document.findAllElements('id').first.innerText;

      print(
          "✅ Location data synced successfully: Success = $success, ID = $id");
    } else {
      print("❌ Failed to sync data: ${response.body}");
    }
  } catch (e) {
    print("❌ Error sending data: $e");
  }
}
