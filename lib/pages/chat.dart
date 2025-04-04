import 'dart:async';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/material.dart';
import 'package:myapp/pages/data.dart'; // Import for AttendanceDatabase

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isFirstMessage = true;
  bool _isLoading = false;

  void _sendMessage() {
    if (_textController.text.isNotEmpty) {
      String message = _textController.text;

      if (_isFirstMessage) {
        // Get the attendance report for the first message
        final database = AttendanceDatabase();
        final attendanceReport = database.getAttendanceReport();
        
        // Set first message with original text (no date)
        setState(() {
          _messages.add(ChatMessage(
            text: message, 
            sender: "User", 
            isUser: true
          ));
          _isFirstMessage = false;
        });
        
        // Pass the attendance report with the first message
        _getGeminiResponse(message, attendanceReport, true);
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: message, 
            sender: "User", 
            isUser: true
          ));
        });
        _getGeminiResponse(message, null, false);
      }
      
      _textController.clear();
    }
    Timer(const Duration(milliseconds: 300), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _getGeminiResponse(String prompt, String? attendanceReport, bool isFirstMessage) async {
    // Get the API key
    final apiKey = "AIzaSyAAOVMb74nOYOLzXzPstlylVzVg9gZZsrE";

    // Set the loading state
    setState(() {
      _isLoading = true;
    });
    try {
      // Initialize the Gemini model
      final model = GenerativeModel(model: 'gemini-2.0-flash-lite', apiKey: apiKey);

      // System instructions for the teacher persona
      String systemInstructions = "You are an AI assistant for an attendance management system. Your task is to answer only attendance-related queries based on student records, including names, classes attended, and absences. Answer questions like:  - What is [Student's Name]'s attendance percentage?  - How many classes has [Student's Name] attended?  - Who has low attendance?  - Has [Student's Name] been absent more than X times?  - Show me today's attendance record.  - List students with less than 75% attendance.  *Strictly refuse unrelated queries with: 'I only assist with attendance-related questions.'";

      // Add attendance report to system instructions
      if (attendanceReport != null) {
        systemInstructions += "\n\nHere is the complete attendance data:\n$attendanceReport";
      }

      // For first message, specifically ask the model to display the attendance report
      if (isFirstMessage) {
        prompt = "Please show me the complete attendance report with all students and their attendance percentages, then answer my question: " + prompt;
      }

      // Concatenate previous messages into a single string for context
      List<Content> history = [];
      history.add(Content.text(systemInstructions));
      for (ChatMessage message in _messages) {
        history.add(Content(
            message.isUser ? 'user' : 'model', [TextPart(message.text)]));
      }

      // Add the user input prompt
      history.add(Content('user', [TextPart(prompt)]));

      // Prepare the chat session with the history
      final chat = model.startChat(history: history);
      final response = await chat.sendMessage(Content.text(""));

      // Check if there are any text parts in the response
      if (response.text != null) {
        // Add the response to the messages list
        setState(() {
          _messages.add(ChatMessage(
              text: response.text ?? "", sender: "Gemini", isUser: false));
        });
        // Scroll to the end of the list
        Timer(const Duration(milliseconds: 300), () {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      }
    } catch (e) {
      print('Error getting response from Gemini: $e');
      setState(() {
        _messages.add(ChatMessage(
            text: "Sorry, I encountered an error processing your request. Please try again.",
            sender: "Gemini",
            isUser: false));
      });
    } finally {
      // Reset the loading state
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuikAsk'),
        actions: [
          // Show a loading indicator when waiting for a response
          if (_isLoading) const CircularProgressIndicator(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index];
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final String sender;
  final bool isUser;

  const ChatMessage(
      {super.key, required this.text, required this.sender, required this.isUser});

  @override
  Widget build(BuildContext context) {

    return ListTile(
      leading: CircleAvatar(
        child: Text(sender[0]),
      ),
      title: Text(sender),
      subtitle: Text(text),
      trailing: isUser
          ? const Icon(Icons.person)
          : const Icon(Icons.smart_toy) ,
    );
  }
}