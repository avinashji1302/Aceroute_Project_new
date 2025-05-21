import 'package:ace_routes/database/Tables/eform_data_table.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/eform_controller.dart';
import '../model/GTypeModel.dart';

import 'other_form.dart';

class EformSelect extends StatelessWidget {
  final String oid;

  EformSelect({super.key, required this.oid});

  final EFormController controller = Get.put(EFormController());

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return AlertDialog(
      title: Center(
        child: Text(
          'Select Form',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      content: SizedBox(
        height: height * 0.5, // 50% of screen height
        width: width * 0.8, // 80% of screen width
        child: Obx(() {
          if (controller.gTypeList.isEmpty) {
            return Center(child: CircularProgressIndicator());
          } else {
            List<GTypeModel> filteredGTypes = controller.gTypeList
                .where((gType) => gType.typeId == '10')
                .toList()
              ..sort((a, b) => a.name.compareTo(b.name));
            return ListView.builder(
              itemCount: filteredGTypes.length,
              itemBuilder: (context, index) {
                GTypeModel gType = filteredGTypes[index];
                bool isDetailsNotEmpty = gType.details.isNotEmpty;

                print("ALl the data : ${gType}");

                if (!isDetailsNotEmpty) return SizedBox.shrink();

                return Column(
                  children: [
                    ListTile(
                      onTap: () async {
                        Navigator.of(context).pop();
                        final rules = gType.details['rules'] ?? {};
                        final formCount =
                            int.tryParse(rules['cnt']?.toString() ?? '1') ?? 1;
                        final formStatus = rules['sts']?.toString() ?? '';

                        print(
                            " Tapped : ${gType} count :   $formCount  status :  $formStatus");

                        // if (gType.id == 'BW Form') {
                        //   Get.to(AddBwForm(gType: gType, oid: oid));
                        // } else if (gType.name == 'Voltage Form') {
                        //   Get.to(VoltageForm(gType: gType));
                        // } else {
                        //   Get.to(OtherForm(gType: gType, oid: oid));
                        // }

                        // Check if form already exists in database
                        final existingForms =
                            await EFormDataTable.getFormsByType(gType.id);
                        if (formCount == 1 && existingForms.isNotEmpty) {
                          print(
                              "ALready exsits $formCount ${existingForms.first.id} ${existingForms.first.formFields}");
                          // Only allow editing existing form
                          Get.to(DynamicFormPage(
                            id: existingForms.first.id, // Use existing form ID
                            frm: existingForms.first.formFields,
                            name: gType.name,
                            oid: oid,
                            ftid: gType.id.toString(),
                            isEditMode: true,
                            editOrsaveId: existingForms.first
                                .id, // Add this flag to your DynamicFormPage
                          ));
                        } else {
                          // Allow new form creation
                          Get.to(DynamicFormPage(
                            id: gType.id,
                            frm: gType.details['frm'],
                            name: gType.name,
                            oid: oid,
                            ftid: gType.id.toString(),
                            isEditMode: false,
                            editOrsaveId: '0',
                          ));
                        }
                      },
                      title: Text("${gType.name}  ${gType.id}"),
                    ),
                    Divider(),
                  ],
                );
              },
            );
          }
        }),
      ),
      actions: [
        Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ),
      ],
    );
  }
}
