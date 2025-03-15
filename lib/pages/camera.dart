import 'package:flutter/material.dart';

class CameraScreen extends StatelessWidget {
  final dynamic title;

  const CameraScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text(title),
    );
  }
}
