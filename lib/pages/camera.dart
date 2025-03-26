import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:convert';
import 'data.dart'; // Make sure this path is correct

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  final AttendanceDatabase _database = AttendanceDatabase();
  bool _isCameraInitialized = false;
  String? _imagePath;
  Uint8List? _imageBytes; // Added for web support
  bool _isProcessing = false;
  bool _isRegistering = false;
  final TextEditingController _usnController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _usnController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras found'))
          );
        }
        return;
      }

      // Use the first available camera
      final camera = cameras.first;
      final controller = CameraController(camera, ResolutionPreset.medium);
      
      // Initialize the controller
      await controller.initialize();
      
      if (mounted) {
        setState(() {
          _controller = controller;
          _initializeControllerFuture = Future.value();
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera initialization error: ${e.toString()}'))
        );
      }
    }
  }

    Future<String?> _sendImageToApi(String imagePath, Uint8List? imageBytes) async {
    try {
      // Replace with your actual API endpoint
      final uri = Uri.parse('http://127.0.0.1:8000/recognize/');
      http.Response response;
      
      if (kIsWeb) {
        // Web implementation
        if (imageBytes == null) {
          throw Exception('Image bytes are null');
        }
        
        var request = http.MultipartRequest('POST', uri);
        request.files.add(http.MultipartFile.fromBytes(
          'file',  // Changed from 'image' to 'file'
          imageBytes,
          filename: 'image.jpg',
        ));
        
        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Mobile implementation
        var request = http.MultipartRequest('POST', uri);
        request.files.add(await http.MultipartFile.fromPath('file', imagePath));  // Changed from 'image' to 'file'
        
        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      }
      
      if (response.statusCode == 200) {
        print('API Response: ${response.body}');
        return response.body; // This should contain the USN
      } else {
        print('API Error: Status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error sending image to API: $e');
      return null;
    }
  }

  Future<bool> _registerFace(String imagePath, String usn, Uint8List? imageBytes) async {
    try {
      // Include the name/usn as a query parameter instead of a form field
      final uri = Uri.parse('http://127.0.0.1:8000/learn/').replace(
        queryParameters: {'name': usn},
      );
      http.Response response;
      
      if (kIsWeb) {
        // Web implementation
        if (imageBytes == null) {
          throw Exception('Image bytes are null');
        }
        
        var request = http.MultipartRequest('POST', uri);
        request.files.add(http.MultipartFile.fromBytes(
          'file',  // Changed from 'image' to 'file'
          imageBytes,
          filename: 'image.jpg',
        ));
        // Remove the fields since we're using query parameter now
        // request.fields['name'] = usn;
        
        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Mobile implementation
        var request = http.MultipartRequest('POST', uri);
        request.files.add(await http.MultipartFile.fromPath('file', imagePath));  // Changed from 'image' to 'file'
        // Remove the fields since we're using query parameter now
        // request.fields['name'] = usn;
        
        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      }
      
      if (response.statusCode == 200) {
        print('Registration Response: ${response.body}');
        return true;
      } else {
        print('API Error: Status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error registering face: $e');
      return false;
    }
  }

  Future<String?> _showUsnInputDialog() async {
    _usnController.clear();
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Register New Face'),
          content: TextField(
            controller: _usnController,
            decoration: const InputDecoration(
              labelText: 'Enter USN',
              hintText: 'e.g., CSE123',
            ),
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null); // Explicitly return null when canceled
              },
            ),
            TextButton(
              child: const Text('Register'),
              onPressed: () {
                if (_usnController.text.isNotEmpty) {
                  Navigator.of(context).pop(_usnController.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid USN'))
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _captureAndRegisterFace() async {
    if (_isProcessing || _isRegistering) return;
    
    if (_controller == null || !_controller!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not ready'))
      );
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      // Make sure controller is initialized
      if (_initializeControllerFuture != null) {
        await _initializeControllerFuture;
      }
      
      // Take picture
      final image = await _controller!.takePicture();
      Uint8List? bytes;
      
      if (kIsWeb) {
        // For web, we need to get bytes
        bytes = await image.readAsBytes();
      }
      
      if (image.path.isEmpty && bytes == null) {
        throw Exception('Failed to capture image');
      }
      
      if (mounted) {
        setState(() {
          _imagePath = image.path;
          _imageBytes = bytes;
        });
      }

      // Get USN from user input
      final String? usn = await _showUsnInputDialog();
      
      if (usn != null && usn.isNotEmpty) {
        // Register the face with the USN
        final success = await _registerFace(image.path, usn, bytes);
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Face registered for USN: $usn'))
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to register face'))
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration cancelled'))
          );
        }
      }
    } catch (e) {
      print('Error registering face: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'))
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  Future<void> _processImage() async {
    if (_isProcessing || _isRegistering) return;
    
    if (_controller == null || !_controller!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not ready'))
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Make sure controller is initialized
      if (_initializeControllerFuture != null) {
        await _initializeControllerFuture;
      }
      
      // Take picture
      final image = await _controller!.takePicture();
      Uint8List? bytes;
      
      if (kIsWeb) {
        // For web, we need to get bytes
        bytes = await image.readAsBytes();
      }
      
      if (image.path.isEmpty && bytes == null) {
        throw Exception('Failed to capture image');
      }
      
      if (mounted) {
        setState(() {
          _imagePath = image.path;
          _imageBytes = bytes;
        });
      }

      // Send image to API and get USN
      final usn = await _sendImageToApi(image.path, bytes);

      if (usn != null && usn.isNotEmpty) {
        // Get current subject from timetable based on current time
        final currentSubject = 'SUBJECT_CODE'; // Replace with actual logic
        
        try {
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
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invalid student or subject: $usn')),
              );
            }
          }
        } catch (dbError) {
          print('Database error: $dbError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Database error: ${dbError.toString()}')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No student ID detected')),
          );
        }
      }
    } catch (e) {
      print('Error processing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take Attendance')),
      body: Column(
        children: [
          Expanded(
            child: _isCameraInitialized && _controller != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: CameraPreview(_controller!),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Capture button for attendance
              ElevatedButton.icon(
                onPressed: (_isProcessing || _isRegistering) ? null : _processImage,
                icon: _isProcessing 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.camera, size: 30, color: Colors.white),
                label: Text(
                  _isProcessing ? "Processing" : "Capture",
                  style: const TextStyle(color: Colors.white)
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              
              // Register face button
              ElevatedButton.icon(
                onPressed: (_isProcessing || _isRegistering) ? null : _captureAndRegisterFace,
                icon: _isRegistering 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add, size: 30, color: Colors.white),
                label: Text(
                  _isRegistering ? "Registering" : "Register Face",
                  style: const TextStyle(color: Colors.white)
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Image preview
          if (_imagePath != null || _imageBytes != null)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: kIsWeb && _imageBytes != null
                  ? Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                    )
                  : _imagePath != null
                      ? Image.file(
                          File(_imagePath!),
                          fit: BoxFit.cover,
                        )
                      : const Center(child: Text('No Image')),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}