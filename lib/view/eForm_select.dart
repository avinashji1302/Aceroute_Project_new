import 'package:ace_routes/view/e_from.dart';
import 'package:ace_routes/view/voltage_form.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../controller/eform_controller.dart';
import '../model/GTypeModel.dart';
import 'add_bw_from.dart';
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
        width: width * 0.8,   // 80% of screen width
        child: Obx(() {
          if (controller.gTypeList.isEmpty) {
            return Center(child: CircularProgressIndicator());
          } else {
            List<GTypeModel> sortedGTypes = List.from(controller.gTypeList)
              ..sort((a, b) => a.name.compareTo(b.name));
            return ListView.builder(
              itemCount: sortedGTypes.length,
              itemBuilder: (context, index) {
                GTypeModel gType = sortedGTypes[index];
                bool isDetailsNotEmpty = gType.details.isNotEmpty;

                if (!isDetailsNotEmpty) return SizedBox.shrink();

                return Column(
                  children: [
                    ListTile(
                      onTap: () {
                        Navigator.of(context).pop();

                        if (gType.name == 'BW Form') {
                          Get.to(AddBwForm(gType: gType, oid: oid));
                        } else if (gType.name == 'Voltage Form') {
                          Get.to(VoltageForm(gType: gType));
                        } else {
                          Get.to(OtherForm(gType: gType));
                        }
                      },
                      title: Text(gType.name),
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
