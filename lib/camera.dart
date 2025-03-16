import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'data.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  final AttendanceDatabase _database = AttendanceDatabase();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No cameras found')));
        return;
      }

      setState(() {
        _controller = CameraController(cameras[0], ResolutionPreset.medium);
        _initializeControllerFuture = _controller?.initialize();
      });
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<String?> _sendImageToApi(String imagePath) async {
    try {
      final uri = Uri.parse('YOUR_API_ENDPOINT');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      var response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        return responseData; // Assuming this contains the USN
      }
    } catch (e) {
      print('Error sending image to API: $e');
    }
    return null;
  }

  Future<void> _processImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Camera not ready')));
      return;
    }

    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();

      // Send image to API and get USN
      final usn = await _sendImageToApi(image.path);

      if (usn != null) {
        // Get current subject from timetable based on current time
        final currentSubject = 'SUBJECT_CODE'; // Replace with actual logic

        if (_database.isValidStudent(usn, currentSubject)) {
          await _database.markAttendance(
            usn,
            currentSubject,
            DateTime.now().toString().split(' ')[0],
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Attendance marked for USN: $usn')),
            );
          }
        }
      }
    } catch (e) {
      print('Error processing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take Attendance')),
      body:
          _controller == null
              ? const Center(child: Text('Initializing Camera...'))
              : FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Column(
                      children: [
                        Expanded(child: CameraPreview(_controller!)),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            onPressed: _processImage,
                            child: const Text('Capture'),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
