import 'package:flutter/material.dart';
import 'package:myapp/pages/chat.dart';
import 'camera.dart';
import 'attendance.dart';

class Tabs extends StatefulWidget {
  const Tabs({super.key});

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
      CameraPage(),
      const AttendanceScreen(),
      Chat()
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
        selectedItemColor: Theme.of(context).colorScheme.primary, // Active icon color
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
            icon: Icon(Icons.android),
            label: "Chat", // New Tab
          ),
        ],
      ),
    );
  }
}