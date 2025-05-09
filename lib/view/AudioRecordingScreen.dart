import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controller/audio_controller.dart';
import '../controller/file_meta_controller.dart';
import 'audio.dart'; // Import your AudioRecord screen

class AudioRecordingScreen extends StatefulWidget {
  final String eventId;

  const AudioRecordingScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  _AudioRecordingScreenState createState() => _AudioRecordingScreenState();
}

class _AudioRecordingScreenState extends State<AudioRecordingScreen> {
  final AudioController _controller = Get.put(AudioController());
  final FileMetaController fileMetaController = Get.put(FileMetaController());
  final TextEditingController _descriptionController = TextEditingController();
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    await _requestPermissions();
    await _controller.init();
    setState(() {});
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.microphone.request();
    if (status.isDenied) {
      _showPermissionDeniedDialog();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Microphone Permission Denied'),
        content: Text('This app needs microphone access to record audio. Please enable it in settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
          TextButton(
            onPressed: () => openAppSettings(),
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _uploadAudioFiles() async {
    if (_controller.recordings.isEmpty) {
      Get.snackbar("Error", "No recordings to upload.");
      return;
    }

    setState(() => isUploading = true);

    for (var recording in _controller.recordings) {
      await _controller.uploadAudio(
        recording,
        widget.eventId.toString(),
        "Recorded Event Audio",
      );
    }

    // ✅ Store the last uploaded recording path
    String lastRecordingPath = _controller.recordings.last;

    // ✅ Clear recordings after upload
    _controller.recordings.clear();

    setState(() => isUploading = false);

    // ✅ Fetch uploaded audio again to update UI
    fileMetaController
        .fetchFileAudioDataFromDatabase(widget.eventId.toString());

    // ✅ Show success dialog and pass the last uploaded recording path
    _showSuccessDialog(lastRecordingPath);
  }

  void _showSuccessDialog(String recordingPath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Upload Successful"),
        content: Text("Your audio has been uploaded successfully!"),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close Dialog
              Get.offAll(() => AudioRecord(eventId: int.parse(widget.eventId))); // Go back to AudioRecord screen
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Recording"),
        actions: [
          IconButton(
            tooltip: 'Submit Recording',
            icon: isUploading
                ? Padding(
              padding: const EdgeInsets.all(10),
              child: CircularProgressIndicator(color: Colors.black),
            )
                : Icon(Icons.check, color: Colors.black),
            onPressed: isUploading ? null : _uploadAudioFiles,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //Text("Event ID: ${widget.eventId}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Icon(
              Icons.mic,
              size: 100,
              color: _controller.isRecording ? Colors.red : Colors.black,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _controller.isRecording
                  ? () async {
                await _controller.stopRecording();
                setState(() {});
              }
                  : () async {
                await _controller.startRecording();
                setState(() {});
              },
              child: Text(_controller.isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
            SizedBox(height: 30),
            TextFormField(
              controller: _descriptionController,
              maxLines: 1,
              decoration: InputDecoration(
                labelText: 'Enter Audio Description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
