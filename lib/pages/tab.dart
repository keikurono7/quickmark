import 'package:flutter/material.dart';
import 'camera.dart';
import 'attendance.dart';


class Tabs extends StatelessWidget {
  final dynamic title;

  const Tabs({super.key, required this.title});

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
          ),
          body: TabBarView(
            children: [
              CameraScreen(title: title,),
              AttendanceScreen(),
            ],
          ),
        ),
      ),
    );
  }
}