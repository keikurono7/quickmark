import 'package:flutter/material.dart';
import 'camera.dart';
import 'attendance.dart';
import 'notes.dart';

class Tabs extends StatefulWidget {
  final dynamic title;

  const Tabs({super.key, required this.title});

  @override
  _TabsState createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      CameraScreen(title: widget.title),
      const AttendanceScreen(),
       const NotesScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.purple, // Active icon color
        unselectedItemColor: Colors.grey, // Inactive icon color
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: "Camera",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: "Attendance",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: "Notes", // New Tab
          ),
        ],
      ),
    );
  }
}
