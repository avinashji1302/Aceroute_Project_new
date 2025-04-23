import 'dart:convert'; // For JSON encoding

import 'package:ace_routes/controller/connectivity/network_controller.dart';
import 'package:ace_routes/database/offlineTables/order_part_sync_table.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:xml/xml.dart';

import '../core/colors/Constants.dart';

import '../database/Tables/PartTypeDataTable.dart';
import '../database/Tables/getOrderPartTable.dart';

import '../model/Ptype.dart';
import '../model/orderPartsModel.dart';

class GetOrderPartController extends GetxController {
  //
  RxList<OrderParts> orderPartsList = <OrderParts>[].obs;
  RxList<PartTypeDataModel> partTypeDataList = <PartTypeDataModel>[].obs;
  final NetworkController networkController = Get.find<NetworkController>();

  //for add part
  final RxList<String> categories = <String>[].obs;

  String categoryId = "";

  // Future<void> syncOfflineActions() async {
  //   if (networkController.isOnline.value == false) return;

  //   final unsynced = await OrderPartSyncTable.getUnsynced();

  //   for (var item in unsynced) {
  //     final id = item['id'] as int;
  //     final action = item['action'] as String;
  //     final oid = item['order_id'] as String;
  //     final sku = item['sku'] as String;
  //     final qty = item['qty'] as String;
  //     final tid = item['tid'] as String;

  //     try {
  //       if (action == 'save' || action == 'edit') {
  //         final saveUrl =
  //             "https://$baseUrl/mobi?token=$token&nspace=$nsp&geo=$geo&rid=$rid&action=saveorderpart&oid=$oid&id=0&tid=$tid&qty=$qty&sku=$sku&stmp=333242323";

  //         final response = await http.get(Uri.parse(saveUrl));
  //         if (response.statusCode == 200) {
  //           await OrderPartSyncTable.markSynced(id);
  //         }
  //       } else if (action == 'delete') {
  //         final deleteUrl =
  //             "https://$baseUrl/mobi?token=$token&nspace=$nsp&geo=$geo&rid=$rid&action=deleteorderpart&id=$sku"; // Assuming `sku` is used as id here
  //         final response = await http.get(Uri.parse(deleteUrl));
  //         if (response.statusCode == 200) {
  //           await OrderPartSyncTable.markSynced(id);
  //         }
  //       }
  //     } catch (e) {
  //       print('❌ Sync failed for $action -> $e');
  //     }
  //   }

  //   // Refresh UI
  //   await GetOrderPartFromDb(unsynced.first['order_id']);
  // }

  Future<void> fetchOrderData(String oid) async {
    print("inside fetch");
    try {
      final url =
          'https://$baseUrl/mobi?token=$token&nspace=$nsp&geo=<lat,lon>&rid=$rid&action=getorderpart&oid=$oid';

      final response = await http.get(Uri.parse(url));
      // print('getorderpart API URL: $url');

      if (response.statusCode == 200) {
        // print('Response Body:\n${response.body}'); // Debug the response body

        final xmlDoc = XmlDocument.parse(response.body);

        // Extract and parse `<oprt>` elements
        final List<OrderParts> orders = xmlDoc
            .findAllElements('oprt')
            .map((node) {
              String getElementText(String tag) {
                final element = node.findElements(tag).isEmpty
                    ? null
                    : node.findElements(tag).single;
                return element?.text ?? ''; // Provide a default value for null
              }

              return OrderParts(
                id: getElementText('id'),
                oid: getElementText('oid'),
                tid: getElementText('tid'),
                sku: getElementText('sku'),
                qty: getElementText('qty'),
                upd: getElementText('upd'),
                by: getElementText('by'),
              );
            })
            .where((order) => order.id.isNotEmpty) // Filter out invalid data
            .toList();

        if (orders.isEmpty) {
          print('No order parts found in the XML response.');
          return;
        }

        print(
            'Parsed Orders:\n${jsonEncode(orders.map((e) => e.toJson()).toList())}');

        // Insert each order into the database
        for (var order in orders) {
          await GetOrderPartTable.insertData(order);
          print('Inserted order into DB: ${order.toJson()}');
        }

        // Verify data in the database
        final List<OrderParts> dbOrders = await GetOrderPartTable.fetchData();
        if (dbOrders.isEmpty) {
          print('No order parts found in the database after insertion.');
        } else {
          print(
              'Orders in DB:\n${jsonEncode(dbOrders.map((e) => e.toJson()).toList())}');
        }
      } else {
        print('Error fetching order data. Status Code: ${response.statusCode}');
        print('Reason: ${response.reasonPhrase}');
      }

      //   await GetOrderPartFromDb();
    } catch (e) {
      print('Error in fetchOrderData: $e');
    }
  }

  //
  Future<void> GetOrderPartFromDb(String oid) async {
    try {
      //chatgpt..........

      // Fetch order parts from the database
      final List<OrderParts> dbOrder =
          await GetOrderPartTable.fetchDataByOid(oid);
      if (dbOrder.isNotEmpty) {
        orderPartsList.assignAll(dbOrder);

        for (var data in dbOrder) {
          List<PartTypeDataModel> fetchedPartTypeList =
              await PartTypeDataTable.fetchPartTypeAllDataById(data.tid);

          if (fetchedPartTypeList.isNotEmpty) {
            // Store fetched data in the list
            partTypeDataList.addAll(fetchedPartTypeList);

            print("suxxess");
          } else {
            print('No data found for tid:');
          }
        }

        print("orders data is ::: ${dbOrder.length}");
      } else {
        print('No order parts found in the database.');
      }
    } catch (e) {
      print('Error in GetOrderPartFromDb: $e');
    }
  }

  //When we click on add Button

  Future<void> AddPartCategories() async {
    //Get All Part type
    List<PartTypeDataModel> allPartTypeData =
        await PartTypeDataTable.fetchPartTypeData();

    for (var data in allPartTypeData) {
      print(data.id);
      categories.add(data.name);
    }
  }

  //Calling save part api

  Future<void> SaveOrderPart(

      //offline part

      String category,
      String quantity,
      String sku,
      String oid,
      {bool fromSync = false}) async {
    if (networkController.isOnline.value == false) {
      OrderPartSyncTable.insert(
          orderId: oid,
          action: 'save',
          sku: sku,
          qty: quantity,
          tid: categoryId);

      print("INternet id off lets what happedns");

// 🔥 Manually create OrderParts and insert into local DB
      final newOfflinePart = OrderParts(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // temp ID
        oid: oid,
        tid: categoryId,
        sku: sku,
        qty: quantity,
        upd: '', // you can leave blank or add local timestamp
        by: 'local', // mark as local if needed
      );

      await GetOrderPartTable.insertData(newOfflinePart);
      print('Inserted locally (offline): ${newOfflinePart.toJson()}');

      // 📌 Refresh the UI
      await GetOrderPartFromDb(oid);

      // ✅ Optional: go back to the previous screen if needed
      // if (!fromSync) {
      //   print("coming back lame");
      //   Get.back();
      // }

      return;

      // GetOrderPartFromDb(oid);
      // // here add categoryId ,quantity,sku, and oid in partTypeDataList at th

      // print(fromSync);

      // // Get.back();
      // return;
    }

    print("$categoryId ${sku} ${quantity}");
    final url =
        "https://$baseUrl/mobi?token=$token&nspace=$nsp&geo=$geo&rid=$rid&action=saveorderpart&oid=$oid&id=0&tid=$categoryId&qty=$quantity&sku=$sku&stmp=333242323";
    print("oid to use $oid");
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      print("response is ::: ${response.body}");

      final xmlDoc = XmlDocument.parse(response.body);

      // Extract and parse `<oprt>` elements
      final List<OrderParts> orders = xmlDoc
          .findAllElements('oprt')
          .map((node) {
            String getElementText(String tag) {
              final element = node.findElements(tag).isEmpty
                  ? null
                  : node.findElements(tag).single;
              return element?.text ?? ''; // Provide a default value for null
            }

            return OrderParts(
              id: getElementText('id'),
              oid: getElementText('oid'),
              tid: getElementText('tid'),
              sku: getElementText('sku'),
              qty: getElementText('qty'),
              upd: getElementText('upd'),
              by: getElementText('by'),
            );
          })
          .where((order) => order.id.isNotEmpty) // Filter out invalid data
          .toList();

      if (orders.isEmpty) {
        print('No order parts found in the XML response.');
        return;
      }

      print(
          'Parsed Orders:\n${jsonEncode(orders.map((e) => e.toJson()).toList())}');

      // Insert each order into the database
      for (var order in orders) {
        await GetOrderPartTable.insertData(order);
        print('Inserted order into DB: ${order.toJson()}');
      }

      GetOrderPartFromDb(oid);
    }
  }

  //Delete the part

  Future<void> DeletePart(String id) async {
    if (networkController.isOnline.value == false) {
      print("deleting offline $id");

      await OrderPartSyncTable.insert(
        orderId: id,
        action: 'delete',
      );

      print("deleted offline $id");

      GetOrderPartTable.deleteById(id);
      GetOrderPartFromDb(id);
      return;
    }

    final url =
        "https://$baseUrl/mobi?token=$token&nspace=$nsp&geo=$geo&rid=$rid&action=deleteorderpart&id=$id";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      print("Deleted Successfully ${response.statusCode}");
      GetOrderPartTable.deleteById(id);
      print("deleted id is $id");
      GetOrderPartFromDb(id);
      print(response.body);
    }
  }

  Future<void> EditPart(
      String id, String oId, String tid, String quantity, String sku,
      {bool fromSync = false}) async {
    if (networkController.isOnline.value == false) {
      print("deleting offline $id");

      await OrderPartSyncTable.insert(
          orderId: oId,
          action: 'edit',
          sku: sku,
          qty: quantity,
          tid: tid,
          partId: id);

      print("edited offline $id  $oId");

      // GetOrderPartFromDb(oId);
      return;
    }

    print("edited offline $id  $oId ${tid}r $quantity $sku");

    final url =
        "https://$baseUrl/mobi?token=$token&nspace=$nsp&geo=$geo&rid=$rid&action=saveorderpart&oid=$oId&id=$id&tid=$tid&qty=$quantity&sku=$sku&stmp=333242323";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      print("edited Successfully ${response.statusCode}");

      print(response.body);

      // Refresh the data
      await GetOrderPartFromDb(oId);
      //  partTypeDataList.clear(); // Clear the list before refreshing
      for (var data in orderPartsList) {
        List<PartTypeDataModel> fetchedPartTypeList =
            await PartTypeDataTable.fetchPartTypeAllDataById(data.tid);
        if (fetchedPartTypeList.isNotEmpty) {
          partTypeDataList.addAll(fetchedPartTypeList);
        }
      }
    }
  }

  void FetchPartTypeId(String name) async {
    String? id = await PartTypeDataTable.fetchIdByName(name);
    categoryId = id!;
    print("id is this $id");
  }
}
