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
    // Step 1: Set `val` field in each form item based on its type
    for (var field in formFields) {
      final tid = field['tid'];
      final name = field['nm'];

      switch (tid) {
        case 1: // Text
          field['val'] = textEditingControllers[name]?.text ?? '';
          break;
        case 2: // Radio
        case 8: // Custom Radio-like
        case 9: // Custom Radio-like
          field['val'] =
              selectedValue.value; // Or use a map if you have multiple radios
          break;
        case 4: // Multi-select
          field['val'] = selectedValues.toList();
          break;
        case 3: // Image
        case 13: // Custom image type
          field['val'] = selectedImage.value?.name ?? '';
          break;
        default:
          print("Unhandled field type: $tid");
          break;
      }
    }

    final fullFormData = {
      'frm': formFields,
    };

    print("fullFormData = $fullFormData");

    String frmkey = selectedImage.value != null
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : '';

    if (!networkController.isOnline.value) {
      await AddFormSyncTable.insert(
          geo: geo,
          oid: oid,
          formId: formId,
          ftid: ftid,
          fdata: fullFormData,
          frmkey: frmkey);
      Get.snackbar("Offline", "Form saved locally. It will sync when online.");
      return;
    }

    final apiUrl =
        'https://$baseUrl/mobi?token=$token&nspace=$nsp&geo=$geo&rid=$rid&action=saveorderform&oid=$oid&id=$formId&ftid=$ftid&fdata=${Uri.encodeComponent(jsonEncode(fullFormData))}&frmkey=$frmkey&index1=NULL&index2=NULL&index3=NULL&index4=NULL&index5=NULL&index6=NULL&stmp=${DateTime.now().millisecondsSinceEpoch}';

    print("API URL: $apiUrl");

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        print("Form submitted successfully!");
        print("Response: ${response.body}");

        if (selectedImage.value != null) {
          // await uploadImage(frmkey);
        }
      } else {
        print("Form submission failed: ${response.body}");
      }
    } catch (e) {
      print("API error: $e");
    }
  }
}
