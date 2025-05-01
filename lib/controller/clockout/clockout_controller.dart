import 'package:ace_routes/controller/background/location_service.dart';
import 'package:ace_routes/core/colors/Constants.dart';
import 'package:ace_routes/database/offlineTables/clockout_sync_table.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ClockOut extends GetxController {
  Future<void> executeAction({
    String? lstoid,
    String? nxtoid,
    required int tid,
    required timestamp,
    required double latitude,
    required double longitude,
  }) async {
    String url = buildUrl(
        lstoid: lstoid,
        nxtoid: nxtoid,
        tid: tid,
        timestamp: timestamp,
        latitude: latitude ?? 0.0,
        longitude: longitude ?? 0.0);
    print("url is $url");

    if (networkController.isOnline.value == false) {
      // Store offline
      await ClockOutSyncTable.insert(
        lstoid: lstoid,
        nxtoid: nxtoid,
        tid: tid,
        timestamp: timestamp,
        latitude: latitude ?? 0.0,
        longitude: longitude ?? 0.0,
      );
      print("📴 Offline: Clock-out data saved locally.");
      return;
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print("response data : ${response.body}");
        print("stamp $tid: ${timestamp}");
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  String buildUrl({
    String? lstoid,
    String? nxtoid,
    required int tid,
    required int timestamp,
    required double latitude,
    required double longitude,
  }) {
    print("$lstoid $nxtoid $tid");
    String url =
        'https://$baseUrl/mobi?token=$token&nspace=$nsp&geo=$latitude,$longitude&rid=$rid&action=savetcrd&tid=$tid&stmp=$timestamp';

    if (lstoid != null) {
      url += '&lstoid=$lstoid';

      print("baseUrl $url");
    }
    if (nxtoid != null) {
      url += '&nxtoid=$nxtoid';
    }

    return url;
  }
}
