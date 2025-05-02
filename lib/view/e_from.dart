import 'package:ace_routes/controller/eform_data_controller.dart';
import 'package:ace_routes/core/Constants.dart';
import 'package:ace_routes/view/add_bw_from.dart';
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
  final EFormDataController eFormDataController =
      Get.put(EFormDataController());

  @override
  void initState() {
    super.initState();
    // Now we can pass the tid to the controller when the screen is initialized
    eFormDataController.fetchEForm();
    Get.find<EFormController>().GetGenOrderDataForForm(widget.tid);
    print("eform called");
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
      body: Container(
        child: Container(
          child: Text("data eform screen"),
        ),
      ),
    );
  }
}
