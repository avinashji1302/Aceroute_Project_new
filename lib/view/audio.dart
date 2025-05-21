import 'package:ace_routes/controller/audio_controller.dart';
import 'package:ace_routes/controller/audio_player_controller.dart';
import 'package:ace_routes/view/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:siri_wave/siri_wave.dart';
import '../controller/event_controller.dart';
import '../controller/file_meta_controller.dart';
import 'AudioRecordingScreen.dart';
import 'audioPlayerScreen.dart';

class AudioRecord extends StatefulWidget {
  final int eventId;

  AudioRecord({required this.eventId});

  @override
  State<AudioRecord> createState() => _AudioRecordState();
}

class _AudioRecordState extends State<AudioRecord> {
  final AudioController _controller = AudioController();
  final FileMetaController fileMetaController = Get.put(FileMetaController());
  final AudioPlayerController audioPlayerController = Get.put(AudioPlayerController());
  final EventController eventController = Get.put(EventController());

  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _initController();
    fileMetaController.fetchFileAudioDataFromDatabase(widget.eventId.toString());
  }

  Future<void> _initController() async {
    await _requestPermissions();
    await _controller.init();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        title: const Text('Microphone Permission Denied'),
        content: const Text('This app needs microphone access to record audio. Please enable microphone permissions in your device settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () => openAppSettings(),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
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

    String lastRecordingPath = _controller.recordings.last;
    _controller.recordings.clear();

    setState(() => isUploading = false);

    fileMetaController.fetchFileAudioDataFromDatabase(widget.eventId.toString());
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
            onPressed: () async {
              await _controller.deleteRecording(recordingPath);
              setState(() {});
              Get.back();
              Get.offAll(() => HomeScreen());
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String audioId, String eventId) {
    Get.dialog(
      AlertDialog(
        title: const Text("Delete Audio", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this audio?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _controller.deleteAudio(audioId, eventId);
              fileMetaController.fetchFileAudioDataFromDatabase(eventId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedAudioList(String eventId) {
    return Expanded(
      child: Obx(() {
        if (fileMetaController.fileMetaData.isEmpty) {
          return Center(child: Text('No uploaded audio available.'));
        }

        // ✅ Create a reversed copy of the list
        final reversedList = fileMetaController.fileMetaData.reversed.toList();

        return ListView.builder(
          shrinkWrap: true,
          itemCount: reversedList.length,
          itemBuilder: (context, index) {
            final fileMeta = reversedList[index];
            final audioId = fileMeta.id.toString();
            final audioTitle = fileMeta.fname ?? 'Unknown Audio';

            return GestureDetector(
              onTap: () {
                Get.to(() => AudioPlayerScreen(
                    audioId: audioId, audioTitle: audioTitle));
              },
              child: ListTile(
                leading: Icon(Icons.audiotrack, color: Colors.blue, size: 40),
                title: Text(audioTitle),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 40),
                  onPressed: () async {
                    _showDeleteConfirmationDialog(audioId, eventId);
                  },
                ),
              ),
            );
          },
        );
      }),
    );
  }


  Widget _buildLocalRecordings() {
    return ListView.separated(
      itemCount: _controller.recordings.length,
      separatorBuilder: (context, index) => SizedBox(height: 10),
      itemBuilder: (context, index) {
        final recordingPath = _controller.recordings[index];
        final isPlaying = _controller.playingPath == recordingPath;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            title: Text('Recording ${index + 1}'),
            leading: IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.play_arrow,
                color: Colors.black,
                size: 36,
              ),
              onPressed: () async {
                await _controller.togglePlayback(recordingPath, () => setState(() {}));
              },
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await _controller.deleteRecording(recordingPath);
                setState(() {});
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload Audio", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue[900],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {

            _controller.clearAudio();
            // Get.offAll(() => HomeScreen());
             Get.to(()=>HomeScreen());
          },
        ),
        actions: [
          IconButton(
            onPressed: isUploading ? null : _uploadAudioFiles,
            icon: isUploading
                ? Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
                : Icon(Icons.cloud_upload, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("📤 Uploaded Audios", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(child: _buildUploadedAudioList(widget.eventId.toString())),

            Divider(thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("🎙️ Record New Audio", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            if (_controller.isRecording)
              SiriWaveform.ios9(options: IOS9SiriWaveformOptions(height: 100, width: 300)),

            Icon(Icons.mic, size: 70, color: _controller.isRecording ? Colors.green : Colors.black),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AudioRecordingScreen(eventId: widget.eventId.toString())),
                  );
                  if (result != null && result is String) {
                    setState(() {
                      _controller.recordings.add(result);
                    });
                  }
                },
                icon: Icon(Icons.fiber_manual_record),
                label: Text("Start Recording"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            Expanded(child: _buildLocalRecordings()),
          ],
        ),
      ),
    );
  }
}
