import 'package:ace_routes/controller/getOrderPart_controller.dart';
import 'package:ace_routes/controller/status_updated_controller.dart';
import 'package:ace_routes/controller/vehicle_controller.dart';
import 'package:ace_routes/database/offlineTables/order_part_sync_table.dart';
import 'package:ace_routes/database/offlineTables/status_sync_table.dart';
import 'package:ace_routes/database/offlineTables/vehicle_sync_table.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:ace_routes/controller/status_updated_controller.dart';
import 'package:ace_routes/database/offlineTables/status_sync_table.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
        duration: const Duration(days: 1),
      );
    } else {
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }

      if (canSync) {
        await _syncData();
        await _syncVehicleData();
        await _syncOrderParts();
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

  /// Call this method **after login is complete** to allow syncing
  void enableSyncAfterLogin() {
    canSync = true;
    print("🔓 Syncing enabled.");
    if (isOnline.value) {
      _syncData();
      _syncVehicleData();
      _syncOrderParts();
    }
  }
}
