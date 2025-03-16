import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _controller = TextEditingController();
  final Box notesBox = Hive.box('notesBox');

  void _addNote() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      notesBox.add(text);
      _controller.clear();
      setState(() {}); // Refresh UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = notesBox.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter Note',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addNote,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Stored Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(notes[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
