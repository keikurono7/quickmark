import 'package:flutter/material.dart';
import 'package:myapp/pages/data.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceDatabase _database = AttendanceDatabase();
  late Map<String, Map<String, dynamic>> _attendanceData;
  String _selectedSubject = 'All';
  bool _isLoading = true;
  List<String> _subjects = ['All'];
  String _sortField = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    _attendanceData = _database.getAllAttendanceData();
    
    // Extract unique subjects
    Set<String> subjects = {'All'};
    _attendanceData.forEach((_, studentData) {
      final studentSubjects = (studentData['subjects'] as Map<String, dynamic>).keys;
      subjects.addAll(studentSubjects);
    });
    
    _subjects = subjects.toList()..sort();

    setState(() {
      _isLoading = false;
    });
  }
  
  Widget _buildOverallStats() {
    int totalStudents = _attendanceData.length;
    int belowThreshold = 0;
    double overallPercentage = 0;
    
    _attendanceData.forEach((_, studentData) {
      final subjects = studentData['subjects'] as Map<String, dynamic>;
      
      if (_selectedSubject == 'All') {
        // Calculate average across all subjects
        double totalPercentage = 0;
        int subjectCount = 0;
        
        subjects.forEach((_, details) {
          totalPercentage += details['percentage'] as double;
          subjectCount++;
          
          if ((details['percentage'] as double) < 75) {
            belowThreshold++;
          }
        });
        
        if (subjectCount > 0) {
          double avgPercentage = totalPercentage / subjectCount;
          overallPercentage += avgPercentage;
          
          if (avgPercentage < 75) {
            belowThreshold++;
          }
        }
      } else {
        // Check specific subject
        if (subjects.containsKey(_selectedSubject)) {
          final details = subjects[_selectedSubject];
          overallPercentage += details['percentage'] as double;
          
          if ((details['percentage'] as double) < 75) {
            belowThreshold++;
          }
        }
      }
    });
    
    if (totalStudents > 0) {
      overallPercentage /= totalStudents;
    }
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Attendance Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('Total Students', '$totalStudents'),
                _statItem('Average Attendance', '${overallPercentage.toStringAsFixed(1)}%'),
                _statItem('Below 75%', '$belowThreshold'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getSortedStudentList() {
    List<Map<String, dynamic>> students = [];
    
    _attendanceData.forEach((usn, data) {
      final name = data['name'] as String;
      final subjects = data['subjects'] as Map<String, dynamic>;
      
      if (_selectedSubject == 'All') {
        double totalPercentage = 0;
        int count = 0;
        
        subjects.forEach((_, subjectData) {
          totalPercentage += subjectData['percentage'] as double;
          count++;
        });
        
        final avgPercentage = count > 0 ? totalPercentage / count : 0.0;
        
        students.add({
          'usn': usn,
          'name': name,
          'percentage': avgPercentage,
          'present': null,  // Not applicable for average
          'total': null,    // Not applicable for average
        });
      } else {
        if (subjects.containsKey(_selectedSubject)) {
          final subjectData = subjects[_selectedSubject];
          
          students.add({
            'usn': usn,
            'name': name,
            'percentage': subjectData['percentage'] as double,
            'present': subjectData['present'] as int,
            'total': subjectData['total'] as int,
          });
        }
      }
    });
    
    // Sort based on selected criteria
    students.sort((a, b) {
      if (_sortField == 'name') {
        return _sortAscending 
            ? a['name'].compareTo(b['name'])
            : b['name'].compareTo(a['name']);
      } else if (_sortField == 'usn') {
        return _sortAscending 
            ? a['usn'].compareTo(b['usn'])
            : b['usn'].compareTo(a['usn']);
      } else {
        // percentage
        return _sortAscending 
            ? a['percentage'].compareTo(b['percentage'])
            : b['percentage'].compareTo(a['percentage']);
      }
    });
    
    return students;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final students = _getSortedStudentList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
      ),
      body: Column(
        children: [
          // Subject filter
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('Filter by subject: '),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedSubject,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedSubject = newValue;
                        });
                      }
                    },
                    items: _subjects.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Overall stats
          _buildOverallStats(),
          
          // Table header
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_sortField == 'usn') {
                          _sortAscending = !_sortAscending;
                        } else {
                          _sortField = 'usn';
                          _sortAscending = true;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey[200],
                      child: Row(
                        children: [
                          Text(
                            'USN',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_sortField == 'usn')
                            Icon(
                              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_sortField == 'name') {
                          _sortAscending = !_sortAscending;
                        } else {
                          _sortField = 'name';
                          _sortAscending = true;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey[200],
                      child: Row(
                        children: [
                          Text(
                            'Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_sortField == 'name')
                            Icon(
                              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_sortField == 'percentage') {
                          _sortAscending = !_sortAscending;
                        } else {
                          _sortField = 'percentage';
                          _sortAscending = true;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey[200],
                      child: Row(
                        children: [
                          Text(
                            'Attendance',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_sortField == 'percentage')
                            Icon(
                              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Student list
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final percentage = student['percentage'] as double;
                final color = percentage < 75 ? Colors.red : 
                             percentage < 85 ? Colors.orange : 
                             Colors.green;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(student['name']),
                    subtitle: Text(student['usn']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedSubject != 'All' && 
                            student['present'] != null &&
                            student['total'] != null)
                          Text('${student['present']}/${student['total']}  '),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}