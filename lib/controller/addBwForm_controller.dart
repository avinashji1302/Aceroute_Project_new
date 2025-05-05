import 'dart:io';
import 'package:ace_routes/controller/connectivity/network_controller.dart';
import 'package:ace_routes/core/colors/Constants.dart';
import 'package:ace_routes/database/offlineTables/add_form_sync_table.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

// class AddBwFormController extends GetxController {
//   // State for form fields
//   var selectedValue = ''.obs; // For single-select dropdown
//   var selectedValues = <String>{}.obs; // For multi-select checkboxes
//   var selectedImage = Rx<XFile?>(null); // Reactive variable for the image
//   var textEditingControllers = <String, TextEditingController>{}.obs; // Map for form fields

//   // Initialize text editing controllers for dynamic fields
//   void initializeTextControllers(List fields) {
//     for (var field in fields) {
//       if (field['nm'] == 'tech') {
//         textEditingControllers[field['nm']] =
//             TextEditingController(); // Create a controller
//       }
//     }
//   }

//   Future<void> pickImage(ImageSource source) async {
//     final picker = ImagePicker();
//     final XFile? image = await picker.pickImage(source: source);
//     if (image != null) {
//       selectedImage.value = image;
//     }
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AddBwFormController extends GetxController {
  var selectedValue = ''.obs;
  var selectedValues = <String>{}.obs;
  var selectedImage = Rx<XFile?>(null);
  var textEditingControllers = <String, TextEditingController>{}.obs;
  final NetworkController networkController = Get.find<NetworkController>();

  void initializeTextControllers(List fields) {
    for (var field in fields) {
      if (field['id'] == 1) {
        textEditingControllers[field['nm']] = TextEditingController();
      }
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      selectedImage.value = image;
    }
  }

  Future<void> submitForm({
    required String geo,
    required String oid,
    required String formId,
    required String ftid,
    required List formFields,
  }) async {
    // Step 1: Build fdata (form values in key-value pairs)
    Map<String, dynamic> fdata = {};

    for (var field in formFields) {
      switch (field['id']) {
        case 1: // Text field
          fdata[field['nm']] = textEditingControllers[field['nm']]?.text ?? '';
          break;
        case 2: // Radio
          fdata[field['nm']] = selectedValue.value;
          break;
        case 4: // Multi-select
          fdata[field['nm']] = selectedValues.toList();
          break;
        case 3: // Image
          // Will be handled separately, but we send the image name (optional)
          fdata[field['nm']] = selectedImage.value?.name ?? '';
          break;
      }
    }

    print(" fdata is :: $fdata");
    // Step 2: Create form key if image exists
    String frmkey = selectedImage.value != null
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : '';

    if (networkController.isOnline.value == false) {
      await AddFormSyncTable.insert(
          geo: geo,
          oid: oid,
          formId: formId,
          ftid: ftid,
          fdata: fdata,
          frmkey: frmkey);
          print("form saved offline :");
      Get.snackbar("Offline", "Form saved locally. It will sync when online.");
      return;
    }

    // Step 3: Build full URL
    final apiUrl =
        'https://$baseUrl/mobi?token=$token&nspace=$nsp&geo=$geo&rid=$rid&action=saveorderform&oid=$oid&id=$formId&ftid=$ftid&fdata=${Uri.encodeComponent(jsonEncode(fdata))}&frmkey=$frmkey&index1=NULL&index2=NULL&index3=NULL&index4=NULL&index5=NULL&index6=NULL&stmp=${DateTime.now().millisecondsSinceEpoch}';


    print("APi  url ; $apiUrl");
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        print("Form submitted successfully!");

        print("response : ${response.body}");

        // Upload image if present
        if (selectedImage.value != null) {
          //   await uploadImage(frmkey);
        }
      } else {
        print("Form submission failed: ${response.body}");
      }
    } catch (e) {
      print("API error: $e");
    }
  }
}
