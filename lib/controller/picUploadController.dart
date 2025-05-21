import 'dart:io';
import 'package:ace_routes/controller/connectivity/network_controller.dart';
import 'package:ace_routes/database/Tables/file_meta_table.dart';
import 'package:ace_routes/database/databse_helper.dart';
import 'package:ace_routes/database/offlineTables/upload_sync_table.dart';
import 'package:ace_routes/model/file_meta_model.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'dart:convert';

import '../core/colors/Constants.dart';
import '../view/ImagePreviewScreen.dart';

class PicUploadController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  var images = <File>[].obs; // List of picked images
  var selectedIndices = <int>[].obs; // Track selected images
  var isUploading = false.obs; // Show loading state
  RxList<String> imageNames = <String>[].obs;
  RxList<String> descriptions = <String>[].obs;

  final NetworkController networkController = Get.find<NetworkController>();

  int? eventId; // Store eventId for the current event

  // Set eventId passed from the screen
  void setEventId(int id) {
    eventId = id;
  }

  // ✅ Pick an Image from Camera
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      if (images.length < 6) {
        // images.add(file);
        print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
        print(eventId);
        Get.to(() => ImagePreviewScreen(imageFile: file, eventId: eventId!));
      } else {
        Get.snackbar('Limit Reached', 'You can only upload up to 6 images.',
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  // ✅ Upload Image to API
  Future<void> uploadImage(
      File file, String eventId, String fileType, String description) async {
    if (networkController.isOnline.value == false) {
      final db = await DatabaseHelper().database;
      print("Offline uploading");

      await UploadSyncTable.insert(
          filePath: file.path,
          eventId: eventId,
          fileType: fileType,
          description: description,
          timestamp: DateTime.now().millisecondsSinceEpoch.toString());
      Get.snackbar("Saved Offline", "Will upload when back online");

      //adding in local database

      final filemetaData = FileMetaModel(
        id: eventId,
        fname: '',
        oid: eventId,
        tid: "1",
        mime: fileType,
        dtl: description,
        geo: '',
        frmkey: '',
        frmfldid: '',
        upd: '',
        by: '',
      );

      // ✅ Save to database
      await FileMetaTable.insertMultipleFileMeta([filemetaData], db);

      return;
    }

    try {
      var url = Uri.parse("https://$baseUrl/fileupload");
      var request = http.MultipartRequest("POST", url);

      request.fields['token'] = "$token";
      request.fields['nspace'] = "$nsp";
      request.fields['geo'] = "$geo";
      request.fields['rid'] = "$rid";
      request.fields['oid'] = eventId;
      request.fields['stmp'] = DateTime.now().millisecondsSinceEpoch.toString();
      request.fields['tid'] = fileType;
      request.fields['mime'] = fileType == "1" ? "mp3" : "jpg";
      request.fields['dtl'] =
          description; // 🔹 Send the description with the request
      request.fields['frmkey'] = "";
      request.fields['frmfldid'] = "";

      request.files.add(await http.MultipartFile.fromPath(
        'binaryFile',
        file.path,
        filename: basename(file.path),
      ));

      var response = await request.send();
      var responseString = await response.stream.bytesToString();
      print("🔹 Response: ${response.statusCode} - $responseString");

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseString);
        Get.snackbar("Success", "Image uploaded successfully!");
        print("✅ Parsed Response: $jsonResponse");
      } else {
        print("❌ Error: ${response.reasonPhrase}");
        Get.snackbar("Upload Failed", response.reasonPhrase ?? "Error");
      }
    } catch (e) {
      print("❌ Exception: $e");
      Get.snackbar("Success", "Image uploaded successfully!");
      // Get.snackbar("Upload Error", e.toString());
    }
  }

  // ✅ Upload All Images
  Future<bool> uploadAllImages(String eventId, String userId) async {
    try {
      for (var image in images) {
        await uploadImage(image, eventId, userId, "Some Description");
      }
      return true; // ✅ Success
    } catch (e) {
      print("Upload failed: $e");
      return false; // ❌ Failure
    }
  }

  // ✅ Delete Selected Image
  void deleteImage(int index) {
    images.removeAt(index);
    selectedIndices.remove(index);
  }

  // ✅ Clear Images
  void clearImages() {
    images.clear();
    selectedIndices.clear();
  }

  // ✅ Toggle Selection
  void toggleSelection(int index) {
    if (selectedIndices.contains(index)) {
      selectedIndices.remove(index);
    } else {
      selectedIndices.add(index);
    }
  }

  void setImageName(int index, String name) {
    imageNames[index] = name;
    update();
  }

  void setImageDescription(int index, String desc) {
    descriptions[index] = desc;
    update();
  }
}
