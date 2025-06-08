import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LawyerBookings extends StatefulWidget {
  const LawyerBookings({Key? key}) : super(key: key);

  @override
  _LawyerBookingsState createState() => _LawyerBookingsState();
}

class _LawyerBookingsState extends State<LawyerBookings> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 1;
  String _selectedTab = 'Today';
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      setState(() => _isLoading = true);
      final String lawyerId = _auth.currentUser!.uid;
      final DateTime now = DateTime.now();
      
      Query query = _firestore.collection('bookings')
          .where('lawyerId', isEqualTo: lawyerId)
          .where('status', isEqualTo: 'pending');

      if (_selectedTab == 'Today') {
        final DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
        query = query
            .where('date', isGreaterThanOrEqualTo: now)
            .where('date', isLessThanOrEqualTo: endOfDay);
      } else {
        query = query
            .where('date', isGreaterThan: DateTime(now.year, now.month, now.day + 1));
      }

      final QuerySnapshot snapshot = await query.get();
      setState(() {
        _bookings = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking $status successfully'),
          backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
        ),
      );
      
      _loadBookings(); // Reload the bookings list
    } catch (e) {
      print('Error updating booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update booking status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF353E55),
      appBar: AppBar(
        title: const Text('Bookings'),
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
      body: Column(
        children: [
          // Tab selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabButton('Today', _bookings.where((doc) => 
                  (doc.data() as Map<String, dynamic>)['date'].toDate().day == DateTime.now().day
                ).length),
                _buildTabButton('Upcoming', _bookings.where((doc) => 
                  (doc.data() as Map<String, dynamic>)['date'].toDate().isAfter(DateTime.now())
                ).length),
              ],
            ),
          ),
          const Divider(color: Color(0xFFD0A554), height: 1),
          // Booking cards
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _bookings.isEmpty
                    ? const Center(
                        child: Text(
                          'No bookings found',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final booking = _bookings[index].data() as Map<String, dynamic>;
                          final DateTime bookingDate = booking['date'].toDate();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildBookingCard(
                              bookingId: _bookings[index].id,
                              date: '${bookingDate.year}-${bookingDate.month.toString().padLeft(2, '0')}-${bookingDate.day.toString().padLeft(2, '0')}',
                              name: booking['clientName'] ?? 'N/A',
                              service: booking['serviceType'] ?? 'N/A',
                              number: booking['clientPhone'] ?? 'N/A',
                              reason: booking['reason'] ?? 'N/A',
                              timeSlot: booking['timeSlot'] ?? 'N/A',
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildTabButton(String title, int count) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = title;
          _loadBookings(); // Reload bookings when tab changes
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: _selectedTab == title ? const Color(0xFFD0A554) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: _selectedTab == title ? const Color(0xFF353E55) : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _selectedTab == title ? const Color(0xFF353E55) : const Color(0xFFD0A554),
                shape: BoxShape.circle,
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: _selectedTab == title ? const Color(0xFFD0A554) : const Color(0xFF353E55),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard({
    required String bookingId,
    required String date,
    required String name,
    required String service,
    required String number,
    required String reason,
    required String timeSlot,
  }) {
    return Card(
      color: const Color(0xFF3D4559),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: $date',
              style: const TextStyle(
                color: Color(0xFFD0A554),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Name:', name),
            _buildDetailRow('Service:', service),
            _buildDetailRow('Number:', number),
            _buildDetailRow('Reason:', reason),
            const SizedBox(height: 16),
            Text(
              'Time Slot: $timeSlot',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _updateBookingStatus(bookingId, 'rejected'),
                  child: const Text(
                    'Reject',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD0A554),
                  ),
                  onPressed: () => _updateBookingStatus(bookingId, 'accepted'),
                  child: const Text(
                    'Accept',
                    style: TextStyle(
                      color: Color(0xFF353E55),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD0A554),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/lawyer/dashboard');
            break;
          case 1:
            // Already on bookings page
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/lawyer/availability');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/lawyer/profile');
            break;
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