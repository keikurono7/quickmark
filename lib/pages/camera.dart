import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/foundation.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String? _imagePath;
  int detectedStudents = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception("No cameras available");
      }
      _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print("Camera initialization error: $e");
    }
  }

  Future<void> _captureImage() async {
    if (!_isCameraInitialized || _cameraController == null) return;
    try {
      final XFile image = await _cameraController!.takePicture();
      setState(() {
        _imagePath = image.path;
      });
      _detectStudents(image.path);
    } catch (e) {
      print("Image capture error: $e");
    }
  }

  Future<void> _detectStudents(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faceDetector = GoogleMlKit.vision.faceDetector();
      final faces = await faceDetector.processImage(inputImage);

      setState(() {
        detectedStudents = faces.length;
      });
      await faceDetector.close();
    } catch (e) {
      print("Face detection error: $e");
    }
  }

  @override
  void dispose() {
    if (_cameraController != null) {
      _cameraController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Capture"),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _isCameraInitialized
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: _cameraController!.value.aspectRatio,
                          child: CameraPreview(_cameraController!),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: 10),
              Text(
                'Students Detected: $detectedStudents',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _captureImage,
                    icon: const Icon(Icons.camera, size: 30, color: Colors.white,),
                    label: const Text("Capture", style: TextStyle(color: Colors.white,),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                  if (_imagePath != null)
                    kIsWeb
                        ? Image.network(
                            _imagePath!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(_imagePath!),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }
}