import 'dart:io';

import 'package:ace_routes/controller/background/location_service.dart';
import 'package:ace_routes/controller/dynamic_form_controller.dart';
import 'package:ace_routes/controller/eform_data_controller.dart';
import 'package:ace_routes/core/colors/Constants.dart';
import 'package:ace_routes/database/Tables/file_meta_table.dart';
import 'package:ace_routes/database/databse_helper.dart';
import 'package:ace_routes/database/offlineTables/upload_sync_table.dart';
import 'package:ace_routes/model/file_meta_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:http/http.dart' as http;

class DynamicFormPage extends StatelessWidget {
  final String id;
  final List<dynamic> frm;
  final String oid;
  final String name;
  final String ftid;
  final bool isEditMode;
  final String editOrsaveId; // 0 for save existing id  for edit
  final DynamicFormController controller;
  final eformDataControlle = Get.find<EFormDataController>();

  DynamicFormPage({
    required this.id,
    required this.frm,
    required this.name,
    required this.oid,
    required this.ftid,
    required this.editOrsaveId,
    this.isEditMode = false,
    Key? key,
  })  : controller = Get.put(DynamicFormController()),
        super(key: key) {
    // Initialize form data
    _initializeFormData(frm);
  }

  void _initializeFormData(List<dynamic> fields) {
    print(" is edited mode : $isEditMode");
    if (!isEditMode) {
      print(" clearing...");
      controller.textControllers.clear(); // or loop over and clear each
      controller.selectedMulti.clear();
      controller.selectedRadio.clear();
      controller.pickedImage.value = null;
      return;
    }
    ;

    for (var field in fields) {
      final tid = field['tid'];
      final name = field['nm'];
      final value = field['val'];

      switch (tid) {
        case 1: // Text field
          controller.textControllers[name] =
              TextEditingController(text: value?.toString() ?? '');
          break;

        case 8: // Radio
          if (value != null) {
            final options = (field['ddn'] as String?)?.split(',') ?? [];
            final values = (field['ddnval'] as String?)?.split(',') ?? [];
            final valueStr = value.toString();
            final index = values.indexOf(valueStr);
            if (index != -1) {
              controller.selectedRadio[name] = options[index];
            }
          }
          break;

        case 9: // Multi-select
          if (value != null) {
            final options = (field['ddn'] as String?)?.split(',') ?? [];
            final values = (field['ddnval'] as String?)?.split(',') ?? [];
            final selectedOptions = <String>{};

            // Handle both string and list inputs
            if (value is String) {
              final selectedValues = value.split(',');
              for (var val in selectedValues) {
                final index = values.indexOf(val);
                if (index != -1) {
                  selectedOptions.add(options[index]);
                }
              }
            } else if (value is int || value is double) {
              final valStr = value.toString();
              final index = values.indexOf(valStr);
              if (index != -1) {
                selectedOptions.add(options[index]);
              }
            }

            controller.selectedMulti[name] = selectedOptions;
          }
          break;
      }
    }
  }

  String? getDropdownValue(Map<String, dynamic> field, String selectedText) {
    if (field['ddn'] == null || field['ddnval'] == null) return selectedText;

    final options = field['ddn'].split(',');
    final values = field['ddnval'].split(',');

    final index = options.indexOf(selectedText);
    return index != -1 ? values[index] : selectedText;
  }

  String imageFormFieldId = '';

  void populateFormValues(List<dynamic> frm) {
    for (var field in frm) {
      final tid = field['tid'];
      final name = field['nm'];

      switch (tid) {
        case 1: // Text field
          field['val'] = controller.textControllers[name]?.text ?? '';
          break;
        case 8: // Radio (single select dropdown)
          if (controller.selectedRadio[name] != null) {
            field['val'] =
                getDropdownValue(field, controller.selectedRadio[name]!);
          }
          break;
        case 9: // Multi-select
          final selectedOptions = controller.selectedMulti[name];
          if (selectedOptions != null && selectedOptions.isNotEmpty) {
            // For multi-select, we'll join the converted values with commas
            field['val'] = selectedOptions
                .map((opt) => getDropdownValue(field, opt))
                .join(',');
          }
          break;
        case 13: // Image
          // Handle image separately
          imageFormFieldId = field['id'].toString();
          print("id image is $imageFormFieldId");
          break;
        default:
          break;
      }
    }
  }

  Future<void> uploadImageForm(
      String frmkey, XFile imageFile, String oid) async {
    try {
      print(
          "🖼️ Uploading form image: fieldId = $imageFormFieldId, frmkey = $frmkey");

      // ------------------------- Offline Mode -------------------------
      if (!networkController.isOnline.value) {
        final db = await DatabaseHelper().database;
        print("⚠️ Offline uploading");

        await UploadSyncTable.insert(
          filePath: imageFile.path,
          eventId: oid,
          fileType: '1', // assuming '2' = image/jpg
          frmkey: frmkey,
          frmfldid: imageFormFieldId,
          description: '',
          timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
        );

        final filemetaData = FileMetaModel(
          id: oid,
          fname: '',
          oid: oid,
          tid: "1",
          mime: 'jpg',
          dtl: '',
          geo: '',
          frmkey: frmkey,
          frmfldid: imageFormFieldId,
          upd: '',
          by: '',
        );

        await FileMetaTable.insertMultipleFileMeta([filemetaData], db);

        Get.snackbar("Saved Offline", "Will upload when back online");
        return;
      }

      // ------------------------- Online Upload -------------------------
      var url = Uri.parse("https://$baseUrl/fileupload");
      var request = http.MultipartRequest("POST", url);

      request.fields.addAll({
        'token': token,
        'nspace': nsp,
        'geo': '28.6139,77.2090', // hardcoded geo location
        'rid': rid,
        'oid': oid,
        'stmp': DateTime.now().millisecondsSinceEpoch.toString(),
        'tid': '1',
        'mime': 'jpg',
        'dtl': '',
        'frmkey': frmkey,
        'frmfldid': imageFormFieldId,
      });

      request.files.add(await http.MultipartFile.fromPath(
        'binaryFile',
        imageFile.path,
      ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print('✅ Image upload successful');
        print('📦 Response: $responseBody');
        Get.snackbar("Success", "Image uploaded successfully!");
      } else {
        print('❌ Upload failed with status ${response.statusCode}');
        print('📦 Error Response: $responseBody');
        Get.snackbar("Upload Failed", response.reasonPhrase ?? "Error");
      }
    } catch (e) {
      print("❌ Exception during image upload: $e");
      Get.snackbar("Upload Error", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasImageField = frm.any((e) => e['tid'] == 13);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Edit $name' : 'Create $name',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[900],
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
            eformDataControlle.loadFormsFromDb();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.done,
              color: Colors.white,
              size: 40.0,
            ),
            onPressed: () async {
              print('Dam $frm $ftid $oid');

              final frmkey = DateTime.now().millisecondsSinceEpoch.toString();
              populateFormValues(frm);

              controller.submitForm(id, '28.6139,77.2090', oid, editOrsaveId,
                  ftid, name, frm, frmkey);
              print("eform save is clicked ::");
              eformDataControlle.loadFormsFromDb();

              controller.textControllers.clear();
              Navigator.of(context).pop();

              //form images

              if (hasImageField && controller.pickedImage.value != null) {
                await uploadImageForm(
                    frmkey, controller.pickedImage.value!, oid);
                frm.firstWhere((e) => e['tid'] == 13)['val'] =
                    controller.pickedImage.value!.name;
              }
            },
          ),
        ],
      ),
     body: LayoutBuilder(
  builder: (context, constraints) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: constraints.maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var field in frm) ..._buildField(field, constraints.maxWidth),
            if (!hasImageField)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text("No image field found. Here's your form."),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  },
),

    );
  }

  List<Widget> _buildField(Map<String, dynamic> field, double maxWidth) {
  final tid = field['tid'];
  final name = field['nm'];
  final label = field['lbl'] ?? '';

  switch (tid) {
    case 1: // Text input
      controller.textControllers.putIfAbsent(
        name,
        () => TextEditingController(),
      );
      return [
        TextField(
          controller: controller.textControllers[name],
          decoration: InputDecoration(
            hintText: '$label',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
      ];

    case 8: // Radio buttons
      final options = (field['ddn'] as String?)?.split(',') ?? [];
      return [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Obx(() => Wrap(
              spacing: 8,
              runSpacing: 4,
              children: options.map((opt) {
                return SizedBox(
                  width: maxWidth > 400 ? (maxWidth / 2) - 24 : maxWidth - 32,
                  child: RadioListTile<String>(
                    value: opt,
                    groupValue: controller.selectedRadio[name],
                    title: Text(opt, softWrap: true),
                    onChanged: (val) =>
                        controller.selectedRadio[name] = val!,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                );
              }).toList(),
            )),
        const SizedBox(height: 16),
      ];

    case 9: // Multi-select
      final options = (field['ddn'] as String?)?.split(',') ?? [];
      return [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Obx(() => Column(
              children: options.map((opt) {
                final selected =
                    controller.selectedMulti[name]?.contains(opt) ?? false;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(opt, softWrap: true),
                  trailing: Checkbox(
                    value: selected,
                    onChanged: (_) => controller.toggleMultiSelect(name, opt),
                  ),
                  onTap: () => controller.toggleMultiSelect(name, opt),
                );
              }).toList(),
            )),
        const SizedBox(height: 16),
      ];

    case 13: // Image picker
      return [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: controller.pickImage,
          icon: const Icon(Icons.add_a_photo),
          label: const Text("Pick or Capture Image"),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final image = controller.pickedImage.value;
          if (image == null) return const SizedBox();
          return Container(
            width: double.infinity,
            height: maxWidth > 500 ? 250 : 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(image.path),
                fit: BoxFit.cover,
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ];

    default:
      return [];
  }
}
}