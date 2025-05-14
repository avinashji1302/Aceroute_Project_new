import 'dart:convert';
import 'package:ace_routes/database/Tables/eform_data_table.dart';
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

    print("Fetching EForm from: $url");

    try {
      final response = await http.get(Uri.parse(url));
      print("Response Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final ofrms = document.findAllElements('ofrm');
        print("Found ${ofrms.length} <ofrm> elements");

        for (var ofrm in ofrms) {
          final id = ofrm.getElement('id')?.text ?? '';
          final oid = ofrm.getElement('oid')?.text ?? '';
          final ftid = ofrm.getElement('ftid')?.text ?? '';
          final frmKey = ofrm.getElement('frmkey')?.text ?? '';
          final updatedBy = ofrm.getElement('by')?.text ?? '';
          final updatedTimestamp = ofrm.getElement('upd')?.text ?? '';
          final fdata = ofrm.getElement('fdata')?.text ?? '';

          print("Raw fdata: $document");

          dynamic decodedData;
          try {
            decodedData = json.decode(fdata);
            print("Decoded JSON: $decodedData");
          } catch (e) {
            print('JSON decode error: $e');
            continue;
          }

          final model = EFormDataModel(
            id: id,
            oid: oid,
            ftid: ftid,
            frmKey: frmKey,
            formFields: decodedData,
            updatedTimestamp: updatedTimestamp,
            updatedBy: updatedBy,
          );

          print("Constructed Model: $model");

          try {
            await EFormDataTable.insertEForm(model);
            print("Model saved to DB successfully");
          } catch (e) {
            print("DB insert error: $e");
          }

          showSavedForms();
        }
      } else {
        print('Failed to fetch data: ${response.statusCode}');
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

  void showSavedForms() async {
    print("Inside showSavedForms()...");
    try {
      final forms = await EFormDataTable.getAllEFormsFromDb();
      print("Total forms retrieved from DB: ${forms.length}");

      for (var form in forms) {
        print('Form ID: ${form.id}');
        print('Form Fields: ${form.formFields}');
      }
    } catch (e) {
      print("Error reading from DB: $e");
    }
  }

  //----------------Deletig the Eform------------------

  Future<void> deleteForm(String id) async {
    final url =
        'https://$baseUrl/mobi?token=$token&nspace=$nsp&geo=$geo&rid=$rid&action=deleteorderform&id=$id';

    EFormDataTable.deleteForm(id);

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print(jsonDecode(response.body));
        print("Deleted the form successfully");
      }
    } catch (e) {
      print("somethig went wrong while deletng $e");
    }
  }

  //------------Editing Here:-----------------------------------------------




}
