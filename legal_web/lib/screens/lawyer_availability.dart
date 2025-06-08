import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LawyerAvailability extends StatefulWidget {
  const LawyerAvailability({Key? key}) : super(key: key);

  @override
  _LawyerAvailabilityState createState() => _LawyerAvailabilityState();
}

class _LawyerAvailabilityState extends State<LawyerAvailability> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<DocumentSnapshot> _availabilities = [];
  int _currentIndex = 2; // Availability is selected
  DateTime? _selectedDate;
  bool _isAvailable = true;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailabilities();
  }

  Future<void> _loadAvailabilities() async {
    try {
      setState(() => _isLoading = true);
      
      final String lawyerId = _auth.currentUser!.uid;
      final QuerySnapshot snapshot = await _firestore
          .collection('availabilities')
          .where('lawyerId', isEqualTo: lawyerId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .where('status', isEqualTo: 'active')
          .orderBy('date')
          .get();

      setState(() {
        _availabilities = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading availabilities: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF353E55),
      appBar: AppBar(
        title: const Text('Availability'),
        backgroundColor: const Color(0xFF353E55),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD0A554)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/lawyer/dashboard');
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selection
            _buildSection(
              icon: Icons.calendar_today,
              title: 'Date',
              child: InkWell(
                onTap: _selectDate,
                child: Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Select Date',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Availability Toggle
            _buildSection(
              icon: Icons.event_available,
              title: 'Available',
              child: Switch(
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
                activeColor: const Color(0xFFD0A554),
              ),
            ),
            const SizedBox(height: 20),
            
            // Time Slot
            _buildSection(
              icon: Icons.access_time,
              title: 'Add Sections',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectStartTime,
                          child: Text(
                            _startTime != null
                                ? _startTime!.format(context)
                                : 'Start Time',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const Text(' to ', style: TextStyle(color: Colors.white)),
                      Expanded(
                        child: InkWell(
                          onTap: _selectEndTime,
                          child: Text(
                            _endTime != null
                                ? _endTime!.format(context)
                                : 'End Time',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Save Button
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD0A554),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: _saveAvailability,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Color(0xFF353E55),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFD0A554)),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFD0A554),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF3D4559),
            borderRadius: BorderRadius.circular(10),
          ),
          child: child,
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD0A554),
              onPrimary: Color(0xFF353E55),
              surface: Color(0xFF3D4559),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD0A554),
              onPrimary: Color(0xFF353E55),
              surface: Color(0xFF3D4559),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD0A554),
              onPrimary: Color(0xFF353E55),
              surface: Color(0xFF3D4559),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _saveAvailability() async {
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date and time slots'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      final String lawyerId = _auth.currentUser!.uid;
      
      // Convert TimeOfDay to string for storage
      final String startTimeStr = '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
      final String endTimeStr = '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';

      // Check for existing availability
      final QuerySnapshot existingSlots = await _firestore
          .collection('availabilities')
          .where('lawyerId', isEqualTo: lawyerId)
          .where('date', isEqualTo: Timestamp.fromDate(_selectedDate!))
          .get();

      if (existingSlots.docs.isNotEmpty) {
        // Update existing availability
        await _firestore.collection('availabilities')
            .doc(existingSlots.docs.first.id)
            .update({
          'isAvailable': _isAvailable,
          'startTime': startTimeStr,
          'endTime': endTimeStr,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new availability
        await _firestore.collection('availabilities').add({
          'lawyerId': lawyerId,
          'date': Timestamp.fromDate(_selectedDate!),
          'isAvailable': _isAvailable,
          'startTime': startTimeStr,
          'endTime': endTimeStr,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'active'
        });
      }

      // Reload availabilities
      await _loadAvailabilities();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Availability saved successfully'),
          backgroundColor: Color(0xFFD0A554),
        ),
      );
    } catch (e) {
      print('Error saving availability: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving availability: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        if (_currentIndex != index) {
          setState(() => _currentIndex = index);
          
          switch (index) {
            case 0: // Dashboard
              Navigator.pushReplacementNamed(context, '/lawyer/dashboard');
              break;
            case 1: // Bookings
              Navigator.pushReplacementNamed(context, '/lawyer/bookings');
              break;
            case 2: // Availability
              // Already on availability page
              break;
            case 3: // Profile
              Navigator.pushReplacementNamed(context, '/lawyer/profile');
              break;
          }
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF3D4559),
      selectedItemColor: const Color(0xFFD0A554),
      unselectedItemColor: Colors.grey[400],
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.access_time),
          label: 'Availability',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}