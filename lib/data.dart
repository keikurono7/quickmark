import 'package:hive/hive.dart';

class AttendanceDatabase {
  final _attendanceBox = Hive.box('attendanceBox');
  final _timetableBox = Hive.box('timetableBox');

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
}