import 'package:ace_routes/core/colors/Constants.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class FormSaveController extends GetxController {


  Future<void> fetchDataFromDbforSaveFrom() async{

    

  }
  Future<void> saveForm({
    required String geo,
    required String oid,
    required String id,
    required String ftid,
    required String fdata,
    required String frmkey,
    required String stmp,
  }) async {
    final url = Uri.parse(
      'https://<your-url>/mobi'
      '?token=$token'
      '&nspace=$nsp'
      '&geo=$geo'
      '&rid=$rid'
      '&action=saveorderform'
      '&oid=$oid'
      '&id=$id'
      '&ftid=$ftid'
      '&fdata=$fdata'
      '&frmkey=$frmkey'
      '&index1=NULL'
      '&index2=NULL'
      '&index3=NULL'
      '&index4=NULL'
      '&index5=NULL'
      '&index6=NULL'
      '&stmp=$stmp',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print("Response: ${response.body}");
      } else {
        print("Failed to save form. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in saveForm: $e");
    }
  }
}
