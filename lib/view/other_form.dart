import 'dart:io';

import 'package:ace_routes/controller/dynamic_form_controller.dart';
import 'package:ace_routes/controller/eform_data_controller.dart';
import 'package:ace_routes/core/Constants.dart';
import 'package:ace_routes/core/colors/Constants.dart';
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
  final controller = Get.put(DynamicFormController());
  final eformDataControlle = Get.find<EFormDataController>();

  DynamicFormPage(
      {required this.id,
      required this.frm,
      required this.name,
      required this.oid,
      required this.ftid,
      super.key});

  

  void populateFormValues(List<dynamic> frm) {
    for (var field in frm) {
      final tid = field['tid'];
      final name = field['nm'];

      switch (tid) {
        case 1: // Text field
          field['val'] = controller.textControllers[name]?.text ?? '';
          break;
        case 8: // Radio
          field['val'] = controller.selectedRadio[name] ?? '';
          break;
        case 9: // Multi-select
          final selectedOptions = controller.selectedMulti[name];
          field['val'] =
              selectedOptions != null ? selectedOptions.join(',') : '';
          break;
        case 13: // Image
          // We'll handle the upload separately and set this below
          break;
        default:
          break;
      }
    }
  }

  Future<void> uploadImage(String frmkey, XFile imageFile) async {
    final url = Uri.parse(
        "https://$baseUrl/mobi?token=$token&nspace=$nsp&rid=$rid&action=fileupload");

    var request = http.MultipartRequest('POST', url);
    request.fields['frmkey'] = frmkey;
    request.files
        .add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      print('Image upload successful');
    } else {
      print('Image upload failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasImageField = frm.any((e) => e['tid'] == 13);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          name,
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

              //  geo: "28.6139,77.2090", // Replace with actual location

              //       oid: widget.oid,
              //       formId: "0", // Or actual ID if editing
              //       ftid: widget.gType.id.toString(),
              //       formFields: widget.gType.details['frm'],

              final frmkey = DateTime.now().millisecondsSinceEpoch.toString();

              populateFormValues(frm);

              // if (hasImageField && controller.pickedImage.value != null) {
              //   await uploadImage(frmkey, controller.pickedImage.value!);
              //   frm.firstWhere((e) => e['tid'] == 13)['val'] =
              //       controller.pickedImage.value!.name;
              // }

              controller.submitForm(
                  id, '28.6139,77.2090', oid, '0', ftid, name, frm, frmkey);
              print("eform save is clicked ::");
              eformDataControlle.loadFormsFromDb();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var field in frm) ..._buildField(field),
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
  }

  List<Widget> _buildField(Map<String, dynamic> field) {
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
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
        ];

      case 8: // Radio
        final options = (field['ddn'] as String?)?.split(',') ?? [];
        // List<String> values = field['ddnval'].split(',');
        // Group options in chunks of 2
        List<List<String>> optionPairs = [];
        for (int i = 0; i < options.length; i += 2) {
          optionPairs.add(options.sublist(
              i, i + 2 > options.length ? options.length : i + 2));
        }

        return [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Obx(() => Column(
                children: optionPairs.map((pair) {
                  return Row(
                    children: pair.map((opt) {
                      return Expanded(
                        child: RadioListTile<String>(
                          value: opt,
                          groupValue: controller.selectedRadio[name],
                          title: Flexible(
                              child: Text(
                            opt,
                            softWrap: true,
                          )),
                          onChanged: (val) =>
                              controller.selectedRadio[name] = val!,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      );
                    }).toList(),
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
                    title: Text(
                      opt,
                      softWrap: true,
                    ),
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
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(image.path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 150,
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
