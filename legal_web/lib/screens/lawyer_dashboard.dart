import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LawyerDashboard extends StatefulWidget {
  const LawyerDashboard({Key? key}) : super(key: key);

  @override
  _LawyerDashboardState createState() => _LawyerDashboardState();
}

class _LawyerDashboardState extends State<LawyerDashboard> {
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? lawyerData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLawyerData();
  }

  Future<void> _loadLawyerData() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final DocumentSnapshot doc = await _firestore
            .collection('lawyers')
            .doc(currentUser.uid)
            .get();

        if (doc.exists) {
          setState(() {
            lawyerData = doc.data() as Map<String, dynamic>;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading lawyer data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF353E55),
      appBar: AppBar(
        title: Text(lawyerData?['name'] ?? 'Lawyer Dashboard'),
        backgroundColor: const Color(0xFF353E55),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD0A554)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await _auth.signOut();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/lawyer/signin'); // Changed from '/welcome' to '/lawyer/signin'
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error signing out: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Lawyer Stats Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D4559),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Total Clients',
                            lawyerData?['totalClients']?.toString() ?? '0'),
                        _buildStatItem('Pending Cases',
                            lawyerData?['pendingCases']?.toString() ?? '0'),
                        _buildStatItem('Completed Cases',
                            lawyerData?['completedCases']?.toString() ?? '0'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Grid Items
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildDashboardItem(
                          context,
                          Icons.person,
                          'Profile',
                          const Color(0xFFD0A554),
                          () {}, // Empty callback as we handle navigation in _buildDashboardItem
                        ),
                        _buildDashboardItem(
                          context,
                          Icons.calendar_today,
                          'Bookings',
                          const Color(0xFF6C8EBF),
                          () {}, // Empty callback as we handle navigation in _buildDashboardItem
                        ),
                        _buildDashboardItem(
                          context,
                          Icons.access_time,
                          'Availability',
                          const Color(0xFF82B366),
                          () {}, // Empty callback as we handle navigation in _buildDashboardItem
                        ),
                        _buildDashboardItem(
                          context,
                          Icons.people,
                          'Clients',
                          const Color(0xFFD6B656),
                          () {}, // Empty callback as we handle navigation in _buildDashboardItem
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD0A554),
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  // Update the grid items navigation method
  Widget _buildDashboardItem(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      color: const Color(0xFF3D4559),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          switch (title) {
            case 'Profile':
              Navigator.pushReplacementNamed(context, '/lawyer/profile');
              break;
            case 'Bookings':
              Navigator.pushReplacementNamed(context, '/lawyer/bookings');
              break;
            case 'Availability':
              Navigator.pushReplacementNamed(context, '/lawyer/availability');
              break;
            case 'Clients':
              Navigator.pushReplacementNamed(context, '/lawyer/clients');
              break;
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update the bottom navigation bar method
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
              Navigator.pushReplacementNamed(context, '/lawyer/availability');
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
      showSelectedLabels: true,
      showUnselectedLabels: true,
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