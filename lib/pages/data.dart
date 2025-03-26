import 'package:hive/hive.dart';

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
    
    // Add student data
    final students = {
      'CSE101': 'Rahul Sharma',
      'CSE102': 'Priya Patel',
      'CSE103': 'Amit Kumar',
      'CSE104': 'Sneha Singh',
      'CSE105': 'Vikram Raj',
    };
    
    await _studentsBox.putAll(students);
    
    // Add timetable data (which students belong to which subjects)
    final subjects = ['CS101', 'CS102', 'CS103'];
    for (var subject in subjects) {
      await _timetableBox.put(subject, students.keys.toList());
    }
    
    // Add attendance records
    final now = DateTime.now();
    
    // Create attendance for the past 10 days
    for (int i = 0; i < 10; i++) {
      final date = now.subtract(Duration(days: i)).toString().split(' ')[0];
      
      for (var subject in subjects) {
        for (var usn in students.keys) {
          // Randomly mark some students absent (80% present, 20% absent)
          final isPresent = i == 0 || (usn != 'CSE105' && usn != 'CSE103') || (i % 3 != 0);
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
    
    data.forEach((usn, studentData) {
      report.writeln("\nStudent: ${studentData['name']} ($usn)");
      
      final subjects = studentData['subjects'] as Map<String, dynamic>;
      subjects.forEach((subject, details) {
        final percentage = (details['percentage'] as double).toStringAsFixed(1);
        report.writeln("  $subject: $percentage% (${details['present']}/${details['total']} classes)");
      });
    });
    
    return report.toString();
  }
}