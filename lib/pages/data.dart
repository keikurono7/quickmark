import 'package:hive/hive.dart';



@HiveType(typeId: 0)
class AttendanceRecord {
  @HiveField(0)
  String usn;

  @HiveField(1)
  String studentName;

  @HiveField(2)
  Map<String, List<DateTime>> subjects; // Subject: [List of attendance dates]

  AttendanceRecord({
    required this.usn,
    required this.studentName,
    required this.subjects,
  });
}

@HiveType(typeId: 1)
class Timetable {
  @HiveField(0)
  Map<String, Map<String, String>> schedule; // Day: {TimeSlot: Subject}

  @HiveField(1)
  Map<String, int> subjectClassCount; // Subject: Number of classes conducted

  Timetable({
    required this.schedule,
    required this.subjectClassCount,
  });
}
