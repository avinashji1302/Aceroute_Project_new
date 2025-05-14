import 'dart:convert';

import 'package:ace_routes/Widgets/dismissed.dart';
import 'package:ace_routes/controller/eform_data_controller.dart';
import 'package:ace_routes/core/Constants.dart';
import 'package:ace_routes/database/Tables/eform_data_table.dart';
import 'package:ace_routes/model/eform_data_model.dart';
import 'package:ace_routes/view/add_bw_from.dart';
import 'package:ace_routes/view/other_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../controller/eform_controller.dart';
import '../controller/fontSizeController.dart';
import 'eForm_select.dart';

class EFormScreen extends StatefulWidget {
  final String tid; // Declare a final variable to hold the tid
  final String oid;

  EFormScreen(
      {super.key,
      required this.tid,
      required this.oid}); // Add tid to the constructor

  @override
  State<EFormScreen> createState() => _EFormScreenState();
}

class _EFormScreenState extends State<EFormScreen> {
  final fontSizeController = Get.find<FontSizeController>();
  late final EFormDataController eFormDataController;

  @override
  void initState() {
    super.initState();
    // Now we can pass the tid to the controller when the screen is initialized
    eFormDataController = Get.put(EFormDataController(oid: widget.oid));
    // eFormDataController.fetchEForm();
    Get.find<EFormController>().GetGenOrderDataForForm(widget.tid);
    //   eFormDataController.fetchSavedDataFromDb();
    eFormDataController.loadFormsFromDb();
    print("eform called");
    print("eform called oid :  ${widget.oid}  tid ${widget.tid}");
  }

  @override
  Widget build(BuildContext context) {
    AllTerms.getTerm();
    return Scaffold(
        appBar: AppBar(
          title: Obx(() => Text(
                AllTerms.formName.value,
                style: TextStyle(color: Colors.white),
              )),
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
                Icons.add_circle_outline,
                color: Colors.white,
                size: 40.0,
              ),
              onPressed: () {
                //    Get.to(AddBwForm());
                showDialog(
                  context: context,
                  builder: (context) => EformSelect(oid: widget.oid),
                );
              },
            ),
          ],
        ),
        body: Obx(() {
          final forms = eFormDataController.eFormsData;

          if (forms.isEmpty) {
            return Center(child: Text('No forms found.'));
          }

          return ListView.builder(
            itemCount: forms.length,
            itemBuilder: (context, index) {
              final form = forms[index];
              return Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.horizontal,
                background: dismissedRight(),
                secondaryBackground: dismissedLeft(),
                onDismissed: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    SnackBar(
                      content: Text("Deleted"),
                    );

                    await eFormDataController.deleteForm(form.id);
                    // await eFormDataController.loadFormsFromDb();
                  } else if (direction == DismissDirection.startToEnd) {
                    print("Editing the app");

                    // Get.to(DynamicFormPage(id: id, frm: frm, name: name, oid: oid, ftid: ftid));
                  }
                },
                child: Container(
                  width: double.infinity,
                  child: Card(
                    margin: EdgeInsets.all(10),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Form ID: ${form.id}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 5),
                          Text('Form Values:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ...form.formFields.map<Widget>((field) {
                            final val = field['lst']?.toString() == '1'
                                ? field['val']?.toString()
                                : '';
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text('val: $val'),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }));
  }
}
