import 'dart:convert';
import 'dart:io';

import 'package:ace_routes/controller/clockout/clockout_controller.dart';
import 'package:ace_routes/controller/dynamic_form_controller.dart';
import 'package:ace_routes/controller/eform_data_controller.dart';
import 'package:ace_routes/controller/getOrderPart_controller.dart';
import 'package:ace_routes/controller/status_updated_controller.dart';
import 'package:ace_routes/controller/vehicle_controller.dart';
import 'package:ace_routes/core/colors/Constants.dart';
import 'package:ace_routes/database/offlineTables/add_form_sync_table.dart';
import 'package:ace_routes/database/offlineTables/clockout_sync_table.dart';
import 'package:ace_routes/database/offlineTables/delete_sync_eform.dart';
import 'package:ace_routes/database/offlineTables/order_part_sync_table.dart';
import 'package:ace_routes/database/offlineTables/status_sync_table.dart';
import 'package:ace_routes/database/offlineTables/upload_sync_table.dart';
import 'package:ace_routes/database/offlineTables/vehicle_sync_table.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class NetworkController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  RxBool isOnline = true.obs;

  // Control whether sync should be triggered (e.g. after login)
  bool canSync = false;

  @override
  void onInit() {
    super.onInit();
    _connectivity.onConnectivityChanged.listen(_updateConnectivity);

    // Do initial check
    _checkConnection();

    // Watch for internet status change
    ever(isOnline, (val) {
      print("📡 Internet status changed: ${val ? "Online" : "Offline"}");
    });
  }

  void _checkConnection() async {
    ConnectivityResult result =
        (await _connectivity.checkConnectivity()) as ConnectivityResult;
    _updateConnectivity([result]); // Wrap in List to match stream format
  }

  void _updateConnectivity(List<ConnectivityResult> results) async {
    print("🔁 Connectivity Results: $results");

    // Check if any result is NOT none (has internet)
    bool hasConnection =
        results.any((result) => result != ConnectivityResult.none);
    isOnline.value = hasConnection;

    if (!hasConnection) {
      Get.rawSnackbar(
        messageText: const Text(
          "Please check the internet connectivity",
          style: TextStyle(color: Colors.red),
        ),
        isDismissible: false,
        duration: const Duration(seconds: 3),
      );
    } else {
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }

      if (canSync) {
        await _syncData();
        await _syncVehicleData();
        await _syncOrderParts();
        await _syncClockOutData();
        // await _syncAddFormData();
        await _syncPendingUploads();
        await _syncEform();
        await _syncPendingEformDeletes();
        print("🔄 Syncing data...");
      } else {
        print("⚠️ Skipping sync — login not completed.");
      }
    }
  }

  Future<void> _syncData() async {
    try {
      final StatusControllers statusControllers = Get.find<StatusControllers>();

      List<Map<String, dynamic>> unsyncedData =
          await StatusSyncTable.getUnsynced();

      for (var data in unsyncedData) {
        String orderId = data['order_id'];
        String newWkf = data['new_wkf'];

        await statusControllers.getStatusUpdate(orderId, "", newWkf, "Syncing");

        await StatusSyncTable.markSynced(data['id']);
        print("✅ Synced data for order_id: $orderId");
      }
    } catch (e) {
      print("❌ Error syncing data: $e");
    }
  }

  Future<void> _syncVehicleData() async {
    try {
      List<Map<String, dynamic>> unsyncedData =
          await VehicleSyncTable.getUnsynced();

      for (var data in unsyncedData) {
        String orderId = data['order_id'];

        Map<String, String> payload = {
          'faultDesc': data['alt'] ?? '',
          'registration': data['po'] ?? '',
          'details': data['dtl'] ?? '',
          'odometer': data['inv'] ?? '',
          'notes': data['note'] ?? '',
        };
        final vehicleController =
            Get.put(VehicleController(orderId), tag: orderId);
        await vehicleController.offlineEdit(payload, fromSync: true);
        await VehicleSyncTable.markSynced(data['id']);

        print("✅ Vehicle data synced for order_id: $orderId");
      }
    } catch (e) {
      print("❌ Error syncing vehicle data: $e");
    }
  }

  Future<void> _syncOrderParts() async {
    final GetOrderPartController getOrderPartController =
        Get.find<GetOrderPartController>();

    print("inside sync order part");

    try {
      List<Map<String, dynamic>> unsyncedData =
          await OrderPartSyncTable.getUnsynced();

      for (var data in unsyncedData) {
        final String action = data['action'];
        final String orderId = data['order_id'];
        final String partId = data['part_id'] ?? '';

        print(
            "🧾 Syncing action=$action | order_id=$orderId | id=${data['id']}  $partId");

        if (action == 'save') {
          await getOrderPartController.SaveOrderPart(
              data['tid'], data['qty'], data['sku'], orderId,
              fromSync: true);
        } else if (action == 'edit') {
          print("editing  orderId $orderId  id   ${data['id']}");
          await getOrderPartController.EditPart(
              partId, orderId, data['tid'], data['qty'], data['sku'],
              fromSync: true);
        } else if (action == 'delete') {
          print("deleting  orderId $orderId  id   ${data['id']}");
          await getOrderPartController.DeletePart(
            orderId,
          );
        } else {
          print("Unknown action: $action");
        }

        await OrderPartSyncTable.markSynced(data['id']);

        print("synced order successfully");
        print("✅ Order part data synced for order_id: $orderId");
      }
    } catch (e) {
      print("❌ Error syncing order part data: $e");
    }

    print(".............");
  }

  Future<void> _syncClockOutData() async {
    try {
      List<Map<String, dynamic>> unsyncedData =
          await ClockOutSyncTable.getUnsynced();
      ClockOut clockOutController = Get.put(ClockOut());

      for (var data in unsyncedData) {
        await clockOutController.executeAction(
          tid: data['tid'],
          lstoid: data['lstoid'],
          nxtoid: data['nxtoid'],
          timestamp: data['timestamp'],
          latitude: data['latitude'],
          longitude: data['longitude'],
        );

        await ClockOutSyncTable.markSynced(data['id']);
        print("✅ Synced clockout for tid: ${data['tid']}");
      }
    } catch (e) {
      print("❌ Error syncing clockout data: $e");
    }
  }

  //form sync -----------------
  // Future<void> _syncAddFormData() async {
  //   try {
  //     List<Map<String, dynamic>> unsyncedData =
  //         await AddFormSyncTable.getUnsynced();

  //     for (var data in unsyncedData) {
  //       print("🔍 Unsynced form data: $data");

  //       final String geo = data['geo'] ?? '';
  //       final String oid = data['oid'] ?? '';
  //       final String formId = data['formId'] ?? '';
  //       final String ftid = data['ftid'] ?? '';
  //       final String frmkey = data['frmkey'] ?? '';
  //       final String fdataJson = data['fdata'] ?? '{}';

  //       print("all data is : $geo $oid $formId $ftid $frmkey $fdataJson");

  //       if ([geo, oid, formId, ftid].any((e) => e.isEmpty)) {
  //         print("❌ Skipping due to missing required fields");
  //         continue;
  //       }

  //       Map<String, dynamic> fdata = {};
  //       try {
  //         fdata = jsonDecode(fdataJson);
  //       } catch (e) {
  //         print("❌ Error decoding fdata JSON: $e");
  //         continue;
  //       }

  //       // Submit the form again
  //       final apiUrl =
  //           'https://$baseUrl/mobi?token=$token&nspace=$nsp&geo=$geo&rid=$rid&action=saveorderform&oid=$oid&id=$formId&ftid=$ftid&fdata=${Uri.encodeComponent(jsonEncode(fdata))}&frmkey=$frmkey&index1=NULL&index2=NULL&index3=NULL&index4=NULL&index5=NULL&index6=NULL&stmp=${DateTime.now().millisecondsSinceEpoch}';

  //       final response = await http.get(Uri.parse(apiUrl));

  //       if (response.statusCode == 200) {
  //         print("✅ Synced form data for oid: $oid");
  //         print(response.body);
  //         await AddFormSyncTable.markSynced(data['id']);
  //       } else {
  //         print("❌ Failed to sync form: ${response.body}");
  //       }
  //     }
  //   } catch (e) {
  //     print("❌ Error fetching unsynced form data: $e");
  //   }
  // }

  Future<void> _syncPendingUploads() async {
    List<Map<String, dynamic>> unsynced = await UploadSyncTable.getUnsynced();

    for (var item in unsynced) {
      final file = File(item['file_path']);
      if (!file.existsSync()) {
        print("⚠️ File does not exist: ${item['file_path']}");
        continue;
      }

      try {
        final request = http.MultipartRequest(
          "POST",
          Uri.parse("https://$baseUrl/fileupload"),
        );

        final mimeType = item['file_type'] == "1" ? "mp3" : "jpg";

        print("$item[mimeType]  $item['description']");

        request.fields.addAll({
          'token': "$token",
          'nspace': "$nsp",
          'geo': "$geo",
          'rid': "$rid",
          'oid': item['event_id'],
          'stmp': item['timestamp'],
          'tid': item['file_type'],
          'mime': mimeType,
          'dtl': item['description'] ?? '',
          'frmkey': "",
          'frmfldid': "",
        });

        request.files.add(await http.MultipartFile.fromPath(
          'binaryFile',
          file.path,
          filename: p.basename(file.path),
        ));

        final response = await request.send();

        if (response.statusCode == 200) {
          print("✅ File uploaded successfully for ID: ${item['id']}");
          await UploadSyncTable.markSynced(item['id']);

          print("Synced image successfully : ");
        } else {
          print(
              "❌ Upload failed with status ${response.statusCode} for ID: ${item['id']}");
        }
      } catch (e) {
        print("❌ Exception during sync for ID ${item['id']}: $e");
      }
    }
  }

  Future<void> _syncEform() async {
    try {
      final unsyncedForms = await AddFormSyncTable.getUnsynced();

      if (unsyncedForms.isEmpty) {
        print("No unsynced forms found.");
        return;
      }

      for (var form in unsyncedForms) {
        try {
          print("🔄 Processing form ID: ${form['id']}");

          // Parse the form data
          final List<dynamic> formData;
          if (form['frm'] is String) {
            formData = jsonDecode(form['frm']) as List<dynamic>;
          } else {
            formData = form['frm'] as List<dynamic>;
          }

          // Prepare the API request
          final formattedData = {'frm': formData};
          final apiUrl =
              'https://$baseUrl/mobi?token=$token&nspace=$nsp&geo=${form['geo']}&rid=$rid'
              '&action=saveorderform&oid=${form['oid']}&id=${form['form_id']}&ftid=${form['ftid']}'
              '&fdata=${Uri.encodeComponent(jsonEncode(formattedData))}&frmkey=${form['frmkey']}'
              '&index1=NULL&index2=NULL&index3=NULL&index4=NULL&index5=NULL&index6=NULL'
              '&stmp=${DateTime.now().millisecondsSinceEpoch}';

          //  print("🌐 Calling API: ${apiUrl.replaceAll(token, '***')}");

          // Make the API call
          final response = await http.get(Uri.parse(apiUrl));

          if (response.statusCode == 200) {
            print("✅ Successfully synced form ${form['id']}");
            await AddFormSyncTable.markSynced(form['id'] as int);

            // Refresh the form data if needed
            final eformDataController = Get.find<EFormDataController>();
            await eformDataController.fetchEForm();
            await eformDataController.loadFormsFromDb();
          } else {
            print("❌ API Error for form ${form['id']}: ${response.statusCode}");
            // Don't mark as synced if API call failed
          }
        } catch (e) {
          print("❌ Error processing form ${form['id']}: $e");
          // Continue with next form even if this one fails
        }
      }
    } catch (e) {
      print("🔥 Error in _syncEform: $e");
    }
  }

  // Delete  in Eform

  Future<void> _syncPendingEformDeletes() async {
    try {
      final unsyncedDeletes = await DeleteSyncEformTable.getUnsyncedDeletes();
      final EFormDataController eFormDataController =
          Get.find<EFormDataController>();

      if (unsyncedDeletes.isEmpty) {
        print("No pending deletes to sync");
        return;
      }

      for (var deleteRecord in unsyncedDeletes) {
        try {
          final formId = deleteRecord['form_id'] as String;
          print("🔄 Processing queued delete for form $formId");

          final success =
              await eFormDataController.performDeleteOnServer(formId);

          print("id in controller : $formId");

          if (success) {
            await DeleteSyncEformTable.markSynced(deleteRecord['id'] as int);
            print("✅ Successfully synced delete for form $formId");
          }
        } catch (e) {
          print(
              "❌ Error processing delete for record ${deleteRecord['id']}: $e");
        }
      }
    } catch (e) {
      print("🔥 Error in _syncPendingDeletes: $e");
    }
  }

  /// Call this method **after login is complete** to allow syncing
  void enableSyncAfterLogin() {
    canSync = true;
    print("🔓 Syncing enabled.");
    if (isOnline.value) {
      _syncData();
      _syncVehicleData();
      _syncOrderParts();
      _syncClockOutData();
      //  _syncAddFormData();
      _syncPendingUploads();

      //eform
      _syncEform();
      _syncPendingEformDeletes();
    }
  }

  Future<void> syncAll() async {
    if (!canSync) {
      print("⚠️ Cannot sync. Sync not enabled.");
      return;
    }

    if (!isOnline.value) {
      print("🚫 Cannot sync. No internet.");
      return;
    }

    print("🔁 Manual sync initiated.");
    await _syncData();
    await _syncVehicleData();
    await _syncOrderParts();
    await _syncClockOutData();
    //  await _syncAddFormData();
    await _syncPendingUploads();
    await _syncEform();
    await _syncPendingEformDeletes();
  }
}
