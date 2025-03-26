import 'package:hive/hive.dart';
import 'dart:math';

class AttendanceDatabase {
  final _attendanceBox = Hive.box('attendanceBox');
  final _timetableBox = Hive.box('timetableBox');
  final _studentsBox = Hive.box('studentsBox');

  // Initialize with sample data
  Future<void> initializeSampleData() async {
    // Clear existing data
    await _attendanceBox.clear();
    await _timetableBox.clear();
    await _studentsBox.clear();
    
    // Add student data - expanded to 15 students
    final students = {
      'CSE101': 'Rahul Sharma',
      'CSE102': 'Priya Patel',
      'CSE103': 'Amit Kumar',
      'CSE104': 'Sneha Singh',
      'CSE105': 'Vikram Raj',
      'CSE106': 'Neha Gupta',
      'CSE107': 'Rajesh Khanna',
      'CSE108': 'Meera Kapoor',
      'CSE109': 'Sunil Verma',
      'CSE110': 'Kavita Sharma',
      'CSE111': 'Ajay Singh',
      'CSE112': 'Suman Patel',
      'CSE113': 'Divya Reddy',
      'CSE114': 'Mohan Kumar',
      'CSE115': 'Aishwarya Rao',
    };
    
    await _studentsBox.putAll(students);
    
    // Add timetable data - expanded to 8 subjects with subject names
    final subjects = {
      'CS101': 'Programming Fundamentals',
      'CS102': 'Algorithms',
      'CS103': 'Software Engineering',
      'CS104': 'Data Structures',
      'CS105': 'Database Systems',
      'CS106': 'Computer Networks',
      'CS107': 'Operating Systems',
      'CS108': 'Web Development'
    };
    
    // Create timetable - assign students to subjects
    // We'll create class groups so not all students are in all classes
    final random = Random(42); // Using seed for consistent results
    
    for (var subject in subjects.keys) {
      // Randomly assign 8-12 students to each subject
      List<String> classStudents = [];
      for (var usn in students.keys) {
        // ~70% chance of adding each student to each subject
        if (random.nextDouble() < 0.7) {
          classStudents.add(usn);
        }
      }
      // Ensure at least 8 students per class
      while (classStudents.length < 8) {
        String usn = students.keys.elementAt(random.nextInt(students.length));
        if (!classStudents.contains(usn)) {
          classStudents.add(usn);
        }
      }
      await _timetableBox.put(subject, classStudents);
    }
    
    // Add attendance records
    final now = DateTime.now();
    
    // Create attendance for the past 15 days (more history)
    for (int i = 0; i < 15; i++) {
      final date = now.subtract(Duration(days: i)).toString().split(' ')[0];
      
      for (var subject in subjects.keys) {
        List<String> classStudents = _timetableBox.get(subject, defaultValue: []);
        
        for (var usn in classStudents) {
          // Create realistic attendance patterns:
          // - Some students have perfect attendance
          // - Some students have poor attendance
          // - Most have random absences
          
          bool isPresent;
          
          if (['CSE101', 'CSE108', 'CSE112'].contains(usn)) {
            // Good students (~95% attendance)
            isPresent = random.nextDouble() < 0.95;
          } else if (['CSE105', 'CSE110', 'CSE114'].contains(usn)) {
            // Poor attendance (~65% attendance)
            isPresent = random.nextDouble() < 0.65;
          } else {
            // Average students (~85% attendance)
            isPresent = random.nextDouble() < 0.85;
          }
          
          // Special case: weekends have lower attendance
          if (i % 7 == 0 || i % 7 == 6) {
            isPresent = isPresent && random.nextDouble() < 0.7;
          }
          
          final key = '${usn}_$subject\_$date';
          await _attendanceBox.put(key, isPresent);
        }
      }
    }
  }

  // Mark attendance for a student
  Future<void> markAttendance(String usn, String subject, String date) async {
    final String key = '${usn}_${subject}_$date';
    await _attendanceBox.put(key, true);
  }

  // Check if student exists in timetable
  bool isValidStudent(String usn, String subject) {
    final timetable = _timetableBox.get(subject, defaultValue: []);
    return timetable.contains(usn);
  }

  // Get attendance for a student
  Map<String, bool> getStudentAttendance(String usn, String subject) {
    final List<String> keys = _attendanceBox.keys
        .where((key) => key.toString().startsWith('${usn}_$subject'))
        .cast<String>()
        .toList();

    return Map.fromEntries(
      keys.map((key) => MapEntry(key, _attendanceBox.get(key) ?? false)),
    );
  }

  // Get all attendance data
  Map<String, Map<String, dynamic>> getAllAttendanceData() {
    Map<String, Map<String, dynamic>> result = {};
    
    // Get all students
    final students = Map<String, String>.from(_studentsBox.toMap());
    
    // For each student
    for (var entry in students.entries) {
      final usn = entry.key;
      final name = entry.value;
      
      Map<String, dynamic> studentData = {
        'name': name,
        'subjects': <String, Map<String, dynamic>>{}
      };
      
      // Get subjects from timetable
      final allSubjects = _timetableBox.keys.toList();
      
      // For each subject
      for (var subject in allSubjects) {
        final timetable = _timetableBox.get(subject, defaultValue: []);
        if (timetable.contains(usn)) {
          final attendance = getStudentAttendance(usn, subject);
          
          // Calculate attendance percentage
          int total = attendance.length;
          int present = attendance.values.where((v) => v).length;
          double percentage = total > 0 ? (present / total) * 100 : 0;
          
          studentData['subjects'][subject] = {
            'total': total,
            'present': present,
            'percentage': percentage,
            'details': attendance
          };
        }
      }
      
      result[usn] = studentData;
    }
    
    return result;
  }
  
  // Get formatted attendance report as string
  String getAttendanceReport() {
    final data = getAllAttendanceData();
    StringBuffer report = StringBuffer();
    
    report.writeln("ATTENDANCE REPORT:");
    report.writeln("=================");
    
    // Get subject names from timetable keys
    final subjects = _timetableBox.keys.toList();
    
    // Print overall statistics
    report.writeln("\nOVERALL CLASS STATISTICS:");
    for (var subject in subjects) {
      int totalStudents = 0;
      int studentsBelow75 = 0;
      double averageAttendance = 0;
      
      data.forEach((usn, studentData) {
        final studentSubjects = studentData['subjects'] as Map<String, dynamic>;
        if (studentSubjects.containsKey(subject)) {
          totalStudents++;
          double percentage = studentSubjects[subject]['percentage'] as double;
          averageAttendance += percentage;
          if (percentage < 75) {
            studentsBelow75++;
          }
        }
      });
      
      if (totalStudents > 0) {
        averageAttendance /= totalStudents;
        report.writeln("  $subject: ${averageAttendance.toStringAsFixed(1)}% average, $studentsBelow75/$totalStudents below 75%");
      }
    }
    
    // Print individual student reports
    report.writeln("\nSTUDENT REPORTS:");
    data.forEach((usn, studentData) {
      report.writeln("\nStudent: ${studentData['name']} ($usn)");
      
      final studentSubjects = studentData['subjects'] as Map<String, dynamic>;
      studentSubjects.forEach((subject, details) {
        final percentage = (details['percentage'] as double).toStringAsFixed(1);
        report.writeln("  $subject: $percentage% (${details['present']}/${details['total']} classes)");
        
        // Highlight attendance issues
        if (details['percentage'] as double < 75) {
          report.writeln("    ** ATTENDANCE WARNING: Below 75% threshold **");
        }
      });
      
      // Calculate overall attendance for this student
      double totalPercentage = 0;
      studentSubjects.forEach((subject, details) {
        totalPercentage += details['percentage'] as double;
      });
      if (studentSubjects.isNotEmpty) {
        final overallPercentage = totalPercentage / studentSubjects.length;
        report.writeln("  Overall: ${overallPercentage.toStringAsFixed(1)}%");
      }
    });
    
    return report.toString();
  }
  
  // Get subject names
  Map<String, String> getSubjectNames() {
    // This would be stored in a real app, using hardcoded for demo
    return {
      'CS101': 'Programming Fundamentals',
      'CS102': 'Algorithms',
      'CS103': 'Software Engineering',
      'CS104': 'Data Structures',
      'CS105': 'Database Systems',
      'CS106': 'Computer Networks',
      'CS107': 'Operating Systems',
      'CS108': 'Web Development'
    };
  }
}