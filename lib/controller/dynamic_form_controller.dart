import 'dart:convert';

import 'package:ace_routes/controller/background/location_service.dart';
import 'package:ace_routes/controller/connectivity/network_controller.dart';
import 'package:ace_routes/controller/eform_data_controller.dart';
import 'package:ace_routes/core/colors/Constants.dart';
import 'package:ace_routes/database/Tables/eform_data_table.dart';
import 'package:ace_routes/database/offlineTables/add_form_sync_table.dart';
import 'package:ace_routes/model/eform_data_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class DynamicFormController extends GetxController {
  final Map<String, TextEditingController> textControllers = {};
  final RxMap<String, String> selectedRadio = <String, String>{}.obs;
  final RxMap<String, Set<String>> selectedMulti = <String, Set<String>>{}.obs;
  //final Rx<XFile?> pickedImage = Rx<XFile?>(null);
  final ImagePicker _picker = ImagePicker();

  final pickedImage = Rx<XFile?>(null);

  final networkController = Get.find<NetworkController>();
  final eformDataControlle = Get.find<EFormDataController>();
  Future<void> pickImage() async {
    final source = await Get.bottomSheet<ImageSource>(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () => Get.back(result: ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Gallery'),
            onTap: () => Get.back(result: ImageSource.gallery),
          ),
        ],
      ),
      backgroundColor: Colors.white,
    );

    if (source != null) {
      final img = await _picker.pickImage(source: source);
      if (img != null) {
        pickedImage.value = img;
      }
    }
  }

  void toggleMultiSelect(String fieldName, String option) {
    selectedMulti.putIfAbsent(fieldName, () => <String>{});
    if (selectedMulti[fieldName]!.contains(option)) {
      selectedMulti[fieldName]!.remove(option);
    } else {
      selectedMulti[fieldName]!.add(option);
    }
    selectedMulti.refresh();
  }

  Future<void> submitForm(String id, String geo, String oid, String formId,
      String ftid, String name, List<dynamic> frm, String frmkey) async {
    // 1. Create proper form key
    final formattedFrmkey =
        'BW Form715297${DateTime.now().millisecondsSinceEpoch}';

    // 2. Restructure the form data
    final formattedData = {'frm': frm};

    final formFieldsForDb = frm;

    print(
        "All the data is :$id $geo $oid $formId $ftid $formattedData $formattedFrmkey");

    if (networkController.isOnline.value == false) {
      print("Network is offline : ");

      await AddFormSyncTable.insert(
          geo: geo,
          oid: oid,
          formId: formId,
          ftid: ftid,
          name: name,
          frm: formFieldsForDb, // Use formatted data
          frmkey: formattedFrmkey, // Use formatted key
          action: 'save'
          
          );

      final data = EFormDataModel(
        id: id,
        oid: oid,
        ftid: ftid,
        frmKey: formattedFrmkey,
        formFields: formFieldsForDb, // Use formatted data
        updatedTimestamp: '${DateTime.now().millisecondsSinceEpoch}',
        updatedBy: 'updatedBy',
      );

      await EFormDataTable.insertEForm(data);
      await eformDataControlle.loadFormsFromDb();
      return;
    }

    final apiUrl =
        'https://$baseUrl/mobi?token=$token&nspace=$nsp&geo=$geo&rid=$rid'
        '&action=saveorderform&oid=$oid&id=$formId&ftid=$ftid'
        '&fdata=${Uri.encodeComponent(jsonEncode(formattedData))}&frmkey=$formattedFrmkey'
        '&index1=NULL&index2=NULL&index3=NULL&index4=NULL&index5=NULL&index6=NULL'
        '&stmp=${DateTime.now().millisecondsSinceEpoch}';

    print("API form : $formattedData $formattedFrmkey");

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        print("Form saved successfully: ${response.body}");
        await eformDataControlle.fetchEForm();
        await eformDataControlle.loadFormsFromDb();
      } else {
        print("Failed to save form: ${response.statusCode}");
      }
    } catch (e) {
      print("Error while submitting form: $e");
    }
  }
}
