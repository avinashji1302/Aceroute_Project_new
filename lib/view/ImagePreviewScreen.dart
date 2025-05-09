import 'dart:io';
import 'package:ace_routes/view/pic_upload_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/picUploadController.dart';

class ImagePreviewScreen extends StatefulWidget {
  final File imageFile;
  final int eventId;

  ImagePreviewScreen({required this.imageFile, required this.eventId});

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  final TextEditingController descriptionController = TextEditingController();
  bool isUploading = false;

  void _uploadImage(PicUploadController controller) async {
    if (isUploading) return;

    setState(() {
      isUploading = true;
    });

    controller.images.add(widget.imageFile);
    await controller.uploadImage(
      widget.imageFile,
      widget.eventId.toString(),
      "1",
      descriptionController.text,
    );

    setState(() {
      isUploading = false;
    });

    Get.to(() => PicUploadScreen(eventId: widget.eventId));
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PicUploadController>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Preview Image"),
        actions: [
          isUploading
              ? Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
            ),
          )
              : IconButton(
            icon: Icon(Icons.cloud_upload),
            tooltip: 'Upload Image',
            onPressed: () => _uploadImage(controller),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Image.file(widget.imageFile, fit: BoxFit.cover, width: double.infinity),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: descriptionController,
              maxLines: 1,
              decoration: InputDecoration(
                hintText: 'Enter description...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          /*ElevatedButton(
            onPressed: isUploading ? null : () => _uploadImage(controller),
            child: isUploading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
                : Text("Upload & Continue"),
          ),*/
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
