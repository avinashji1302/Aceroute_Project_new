/*
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import '../controller/signature_controller.dart';

class AddSignatureScreen extends StatelessWidget {
  final int blockIndex;
  final String eventId;
  AddSignatureScreen({Key? key, required this.blockIndex,  required this.eventId,}) : super(key: key);

  final SignatureController signatureController = Get.find();
  final _signaturePadKey = GlobalKey<SfSignaturePadState>();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preview & Sign"),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Submit Signature',
            icon: Icon(Icons.check, color: Colors.black),
            onPressed: () async {
              final signature =
              await _signaturePadKey.currentState?.toImage();
              if (signature != null) {
                signatureController.addSignature(signature);
                Navigator.of(context).pop(); // Go back after saving
              } else {
                Get.snackbar("Error", "Signature could not be saved.");
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                color: Colors.grey[200],
                child: SfSignaturePad(
                  key: _signaturePadKey,
                  backgroundColor: Colors.grey[200],
                  strokeColor: Colors.black,
                  minimumStrokeWidth: 1.0,
                  maximumStrokeWidth: 4.0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 1,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/


import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import '../controller/signature_controller.dart';
import 'dart:ui' as ui;


class AddSignatureScreen extends StatelessWidget {
  final int blockIndex;
  final String eventId;

  AddSignatureScreen({Key? key, required this.blockIndex, required this.eventId})
      : super(key: key);

  final SignatureController signatureController = Get.find();
  final _signaturePadKey = GlobalKey<SfSignaturePadState>();
  final TextEditingController _descriptionController = TextEditingController();
  bool isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preview & Sign"),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Submit Signature',
            icon: Icon(Icons.check, color: Colors.black),
            onPressed: () async {
              if (isUploading) return; // Prevent multiple clicks

              setState(() {
                isUploading = true; // Show loading indicator
              });

              // Capture the signature as an Image
              final signature = await _signaturePadKey.currentState?.toImage();

              if (signature != null) {
                // Convert the Image to ByteData and then to Uint8List
                final byteData = await signature.toByteData(format: ui.ImageByteFormat.png);
                final signatureBytes = byteData?.buffer.asUint8List();

                if (signatureBytes != null) {
                  // Optionally, you can add the description from the text field here
                  final description = _descriptionController.text;

                  // Upload the signature using your controller method (assuming it handles the API call)
                  await signatureController.uploadSignature(
                    signature,
                    eventId,
                    description, // You can send the description along with the signature
                  );

                  // Add signature to controller (if needed for local management)
                  signatureController.addSignature(signature);

                  setState(() {
                    isUploading = false; // Hide loading indicator
                  });

                  Get.snackbar("Success", "Signature uploaded successfully.");
                  Navigator.of(context).pop(); // Go back after successful upload
                } else {
                  setState(() {
                    isUploading = false;
                  });
                  Get.snackbar("Error", "Signature could not be saved.");
                }
              } else {
                setState(() {
                  isUploading = false;
                });
                Get.snackbar("Error", "Signature could not be captured.");
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                color: Colors.grey[200],
                child: SfSignaturePad(
                  key: _signaturePadKey,
                  backgroundColor: Colors.grey[200],
                  strokeColor: Colors.black,
                  minimumStrokeWidth: 1.0,
                  maximumStrokeWidth: 4.0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 1,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void setState(Function() param) {
    // This method ensures that the state of the widget gets updated.
    param();
  }
}
