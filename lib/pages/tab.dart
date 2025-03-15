import 'package:flutter/material.dart';
import 'camera.dart';
import 'attendance.dart';


class Tabs extends StatelessWidget {
  const Tabs ({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.camera_alt), text: "Camera",),
                Tab(icon: Icon(Icons.list), text: "Attendance",),
              ],
            ),
            title: const Text('Tabs Demo'),
          ),
          body: const TabBarView(
            children: [
              CameraScreen(),
              AttendanceScreen(),
            ],
          ),
        ),
      ),
    );
  }
}