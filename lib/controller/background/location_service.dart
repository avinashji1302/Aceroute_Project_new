import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class GeoServiceController extends GetxController {
  final String gpsSyncMins;
  final String locChangeMeters;
  final String token, nspace, rid, lstoid, nxtoid;
  final List<Position> recordedPositions = [];
  Timer? sendTimer;
  Position? lastPosition;

  GeoServiceController({
    required this.gpsSyncMins,
    required this.locChangeMeters,
    required this.token,
    required this.nspace,
    required this.rid,
    required this.lstoid,
    required this.nxtoid,
  });

  @override
  void onInit() {
    super.onInit();
    _initLocationUpdates();
    _startSendTimer();
  }

  void _initLocationUpdates() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter:
            int.parse(locChangeMeters), // Capture every meter change, we'll filter ourselves
      ),
    ).listen((Position position) {
      if (lastPosition == null ||
          Geolocator.distanceBetween(
                lastPosition!.latitude,
                lastPosition!.longitude,
                position.latitude,
                position.longitude,
              ) >=
              int.parse(locChangeMeters)) {
        recordedPositions.add(position);
        lastPosition = position;
        print(
            "Recorded new position: ${position.latitude}, ${position.longitude}");
      }
    });
  }

  void _startSendTimer() {
    sendTimer = Timer.periodic(Duration(minutes: int.parse(gpsSyncMins)), (_) {
      print('sindng on afte $gpsSyncMins');
      if (recordedPositions.isNotEmpty) {
        _sendToServer();
      }
    });
  }

  Future<void> _sendToServer() async {
    final geoData = recordedPositions
        .map((pos) => "${pos.latitude},${pos.longitude}")
        .join("|");
    final timestamps = recordedPositions
        .map((pos) =>
            pos.timestamp?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch)
        .join("|");

    final lstoidPipe = List.filled(recordedPositions.length, lstoid).join("|");
    final nxtoidPipe = List.filled(recordedPositions.length, nxtoid).join("|");

    final url =
        'https://portal.aceroute.com/mobi?token=$token&nspace=$nspace&rid=$rid&action=saveresgeo'
        '&geo=$geoData&stmp=$timestamps&lstoid=$lstoidPipe&nxtoid=$nxtoidPipe';

    print("Sending to server: $url");

    try {
      final response = await http.get(Uri.parse(url));
      print("Server response: ${response.statusCode} ${response.body}");

      if (response.statusCode == 200) {
        recordedPositions.clear();
      }
    } catch (e) {
      print("Failed to send data: $e");
    }
  }

  @override
  void onClose() {
    sendTimer?.cancel();
    super.onClose();
  }
}
