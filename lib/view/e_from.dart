import 'dart:convert';

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
  late final EFormDataController eFormDataController;

  @override
  void initState() {
    super.initState();
    // Now we can pass the tid to the controller when the screen is initialized
    eFormDataController = Get.put(EFormDataController(oid: widget.oid));
    eFormDataController.fetchEForm();
    Get.find<EFormController>().GetGenOrderDataForForm(widget.tid);
    //   eFormDataController.fetchSavedDataFromDb();

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
      body: Container(
        child: Container(
          child: FutureBuilder(
            future: eFormDataController.fetchSavedDataFromDb(),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              final data = snapshot.data;

              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final rawFormFields = data[index]['formFields'];

                  // Decode JSON if it's a string
                  Map<String, dynamic> formFields;
                  if (rawFormFields is String) {
                    try {
                      formFields = jsonDecode(rawFormFields);
                    } catch (e) {
                      print("Error decoding JSON: $e");
                      return Text("Error decoding form fields");
                    }
                  } else {
                    formFields = rawFormFields;
                  }

                  final frm = formFields['frm'];
                  String technicianVal = "N/A";
                  String paymentVal = "N/A";

                  try {
                    if (frm is List) {
                      // Technician field
                      final techField = frm.firstWhere(
                        (item) => item['nm'] == 'tech',
                        orElse: () => null,
                      );
                      if (techField != null && techField['val'] != null) {
                        technicianVal = techField['val'].toString();
                      }

                      // Payment field
                      final paymentField = frm.firstWhere(
                        (item) => item['nm'] == 'payment',
                        orElse: () => null,
                      );
                      if (paymentField != null && paymentField['val'] != null) {
                        paymentVal = paymentField['val'].toString();
                      }
                    }
                  } catch (e) {
                    print("Error extracting values: $e");
                  }

                  return Card(
                    elevation: 10,
                    child: ListTile(
                      title: Text(
                        "BW Form",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(135, 35, 30, 30),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Technician: $technicianVal"),
                          Text("Payment: $paymentVal"),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
