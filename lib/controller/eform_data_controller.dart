import 'dart:convert';
import 'package:ace_routes/controller/background/location_service.dart';
import 'package:ace_routes/database/Tables/eform_data_table.dart';
import 'package:ace_routes/database/offlineTables/delete_sync_eform.dart';
import 'package:ace_routes/model/eform_data_model.dart';
import 'package:get/get.dart';
import 'package:xml/xml.dart';
import 'package:http/http.dart' as http;
import '../core/colors/Constants.dart';

class EFormDataController extends GetxController {
  // Fetch EForm from the server and parse it

  final String oid;

  EFormDataController({required this.oid});
  var eFormsData = <EFormDataModel>[].obs; // Observable list
  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  void _initializeData() async {
    await fetchEForm(); // Wait for server data to be fetched and saved to DB
    await loadFormsFromDb(); // Now load updated DB
  }

  Future<void> fetchEForm() async {
    final url =
        'https://$baseUrl/mobi?token=$token&nspace=$nsp&geo=$geo&rid=$rid&action=getorderform&oid=$oid';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final ofrms = document.findAllElements('ofrm');

        for (var ofrm in ofrms) {
          final id = ofrm.getElement('id')?.text ?? '';
          final oid = ofrm.getElement('oid')?.text ?? '';
          final ftid = ofrm.getElement('ftid')?.text ?? '';
          final frmKey = ofrm.getElement('frmkey')?.text ?? '';
          final updatedBy = ofrm.getElement('by')?.text ?? '';
          final updatedTimestamp = ofrm.getElement('upd')?.text ?? '';
          final fdata = ofrm.getElement('fdata')?.text ?? '';

          dynamic decodedData;
          try {
            decodedData = json.decode(fdata);

            // Normalize the data structure
            List<dynamic> formFieldsList;
            if (decodedData is Map && decodedData.containsKey('frm')) {
              formFieldsList = decodedData['frm'];
            } else if (decodedData is List) {
              formFieldsList = decodedData;
            } else {
              formFieldsList = [];
            }

            final model = EFormDataModel(
              id: id,
              oid: oid,
              ftid: ftid,
              frmKey: frmKey,
              formFields: formFieldsList,
              updatedTimestamp: updatedTimestamp,
              updatedBy: updatedBy,
            );

            await EFormDataTable.insertEForm(model);
          } catch (e) {
            print('Error processing form data: $e');
          }
        }
      }
    } catch (e) {
      print("Fetch error: $e");
    }
  }

  Future<void> loadFormsFromDb() async {
    try {
      print("Loading forms from DB...");
      final forms = await EFormDataTable.getAllEFormsFromDb();
      eFormsData.assignAll(forms);
      print("Loaded ${forms.length} forms from DB");
    } catch (e) {
      print("DB read error: $e");
    }
  }

  // void showSavedForms() async {
  //   print("Inside showSavedForms()...");
  //   try {
  //     final forms = await EFormDataTable.getAllEFormsFromDb();
  //     print("Total forms retrieved from DB: ${forms.length}");

  //     for (var form in forms) {
  //       print('Form ID: ${form.id}');
  //       print('Form Fields: ${form.formFields}');
  //     }
  //   } catch (e) {
  //     print("Error reading from DB: $e");
  //   }
  // }

  //----------------Deletig the Eform------------------

  // Future<void> deleteForm(String id) async {
  //   final url =
  //       'https://$baseUrl/mobi?token=$token&nspace=$nsp&geo=$geo&rid=$rid&action=deleteorderform&id=$id';

  //   EFormDataTable.deleteForm(id);

  //   try {
  //     final response = await http.get(Uri.parse(url));

  //     if (response.statusCode == 200) {
  //       print(jsonDecode(response.body));
  //       print("Deleted the form successfully");
  //     }
  //   } catch (e) {
  //     print("somethig went wrong while deletng $e");
  //   }
  // }

  Future<void> deleteForm(String id) async {
    // Always delete locally first
    await EFormDataTable.deleteForm(id);

    print("id is $id");

    if (networkController.isOnline.value) {
      // If online, try to delete immediately
      await performDeleteOnServer(id);
    } else {
      // If offline, queue the delete action
      await DeleteSyncEformTable.queueDelete(
        formId: id,
        geo: '28.6139,77.2090', // Use current location or default
      );
    }
  }

  Future<bool> performDeleteOnServer(String formId) async {
    final url =
        'https://$baseUrl/mobi?token=$token&nspace=$nsp&geo=$geo&rid=$rid&action=deleteorderform&id=$formId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print("✅ Deleted form $formId from server");
        return true;
      } else {
        print("❌ Server error deleting form $formId: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Network error deleting form $formId: $e");
      return false;
    }
  }

  //------------Editing Here:-----------------------------------------------
}
