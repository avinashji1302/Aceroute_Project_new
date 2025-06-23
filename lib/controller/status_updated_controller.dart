import 'dart:convert';

import 'package:ace_routes/Widgets/custom_alert_box.dart';
import 'package:ace_routes/core/colors/Constants.dart';
import 'package:ace_routes/database/Tables/eform_data_table.dart';
import 'package:ace_routes/database/Tables/event_table.dart';
import 'package:ace_routes/database/Tables/genTypeTable.dart';
import 'package:ace_routes/database/offlineTables/status_sync_table.dart';
import 'package:ace_routes/model/eform_data_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../database/Tables/status_table.dart';
import '../model/Status_model_database.dart';
import '../controller/event_controller.dart';
import '../controller/connectivity/network_controller.dart';

class StatusControllers extends GetxController {
  var organizedData = <String, List<Status>>{}.obs;

  RxString currentStatus = "".obs;
  RxString updatedWkf = "".obs;

  final EventController eventController = Get.find<EventController>();
  final NetworkController networkController = Get.find<NetworkController>();

  @override
  void onInit() {
    super.onInit();
    //  organizeData();
  }

  Future<void> organizeData() async {
    List<Status> statusData = await StatusTable.fetchStatusData();
    Map<String, Status> groups = {};
    List<Status> items = [];

    for (var status in statusData) {
      if (status.isGroup == "1") {
        groups[status.groupId] = status;
      } else {
        items.add(status);
      }
    }

    var sortedGroups = groups.values.toList()
      ..sort((a, b) => (int.tryParse(a.groupSequence) ?? 0)
          .compareTo(int.tryParse(b.groupSequence) ?? 0));

    var organizedDataTemp = <String, List<Status>>{};
    for (var group in sortedGroups) {
      organizedDataTemp[group.name] = [];
    }

    for (var item in items) {
      var group = groups[item.groupId];
      if (group != null) {
        organizedDataTemp[group.name]?.add(item);
      }
    }

    for (var groupName in organizedDataTemp.keys) {
      organizedDataTemp[groupName]!.sort((a, b) =>
          (int.tryParse(a.sequence) ?? 0)
              .compareTo(int.tryParse(b.sequence) ?? 0));
    }

    organizedData.assignAll(organizedDataTemp);
  }

  Future<void> getStatusUpdate(
      String oid, String oldWkf, String newWkf, String status) async {
    print("oid: $oid, oldWkf: $oldWkf, newWkf: $newWkf, status: $status");
    currentStatus.value = status;
    updatedWkf.value = newWkf;

    //fetch all the data ------

    final String? tid = await EventTable.fetchTidForStatus(oid);

    // fetching all the form that must be there on the basis of tid
    final datas = await GTypeTable.fetchGTypesContainingCapacity(tid!);

    for (var data in datas) {
      Map<String, dynamic> detailsMap;
      try {
        detailsMap = Map<String, dynamic>.from(data.details);
      } catch (e) {
        print(
            "❌ Failed to convert details to Map for GType ID: ${data.id} → Error: $e");
        continue;
      }

      if (detailsMap['rules'] == null ||
          detailsMap['rules'] is! Map<String, dynamic>) {
        print("❌ 'rules' key is missing or not a Map in GType ID: ${data.id}");
        continue;
      }

      final rules = detailsMap['rules'] as Map<String, dynamic>;

      List<String> statusList = [];

      if (rules['sts'] is String) {
        statusList = (rules['sts'] as String).split(',');
      } else if (rules['sts'] is List) {
        statusList = (rules['sts'] as List).map((e) => e.toString()).toList();
      }

      print('Count: ${rules['cnt']}');
      print('Status List: $statusList');

      if (statusList.contains(newWkf)) {
        print("newKf $newWkf : ");

        List<EFormDataModel> formList =
            await EFormDataTable.getDataGenTypeId(data.id);

        if (formList.isEmpty) {
          showDialog(
            context: Get.context!,
            builder: (_) => CustomAlertDialog(
              title: "Oops...",
              message: "Please fill out the form before proceeding.",
              buttonText: "Ok",
            ),
          );
          return;
        } else {
          print("form is there : ");
        }

        print("Performing action because status is 4 or 5");
      } else {
        print("No action needed");
      }
    }

    // ✅ Always update local DB first
    await EventTable.updateOrder(oid, newWkf);
    print("📦 Updated local DB for order $oid with wkf = $newWkf");

    String? updatedStatus = await StatusTable.fetchNameById(newWkf);
    if (updatedStatus != null) {
      eventController.nameMap[oldWkf] = updatedStatus;
      print("✅ Updated status locally: $updatedStatus");
    }
    print(networkController.isOnline.value);
    // ✅ Check internet availability
    if (!networkController.isOnline.value) {
      print("📴 Offline: Saving to sync queue...");
      await StatusSyncTable.insert(oid, newWkf);
      return;
    }

    // ✅ If online, call API
    String url =
        "https://$baseUrl/mobi?token=$token&nspace=$nsp&geo=$geo&rid=$rid&action=saveorderfld&id=$oid&name=wkf&value=$newWkf&egeo=<lat,lon>&";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print("✅ Synced with server ${response.body}");
      } else {
        print("⚠️ API Failed, saving to queue as fallback...");
        await StatusSyncTable.insert(oid, newWkf);
      }
    } catch (e) {
      print("❌ Exception while calling API: $e");
      await StatusSyncTable.insert(oid, newWkf);
    }
  }
}
