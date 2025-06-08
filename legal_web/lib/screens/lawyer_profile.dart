import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LawyerProfile extends StatefulWidget {
  const LawyerProfile({Key? key}) : super(key: key);

  @override
  _LawyerProfileState createState() => _LawyerProfileState();
}

class _LawyerProfileState extends State<LawyerProfile> {
  // Add form key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Add Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  String? _profileImageUrl;
  File? _profileImage;
  int _currentIndex = 3;  // Profile tab selected

  // Controllers for text fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();  // Singular form
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _practiceCourtsController = TextEditingController();

  // Update _pickImage method to directly use the picked image
  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);
      
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
          _isLoading = false;
        });
        // Upload to local storage
        await _uploadProfileImage();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Image picker error: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update _uploadProfileImage method
  Future<void> _uploadProfileImage() async {
    if (_profileImage == null) return;

    try {
      setState(() => _isLoading = true);
      
      final String uid = _auth.currentUser!.uid;
      final directory = await getApplicationDocumentsDirectory().catchError((e) {
        print('Error getting directory: $e');
        throw Exception('Failed to access local storage');
      });
      
      final String fileName = 'profile_$uid.jpg';
      final String localPath = '${directory.path}/$fileName';
      
      // Copy the image to local storage
      await _profileImage!.copy(localPath).catchError((e) {
        print('Error copying file: $e');
        throw Exception('Failed to save image to local storage');
      });
      
      // Update the profile image path in Firestore
      await _firestore.collection('lawyers').doc(uid).update({
        'profileImagePath': localPath,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      setState(() {
        _profileImageUrl = localPath;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Upload error: $e'); // Debug print
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLawyerProfile();
  }

  // Update the _loadLawyerProfile method to load profile image
  Future<void> _loadLawyerProfile() async {
    try {
      final String uid = _auth.currentUser!.uid;
      final DocumentSnapshot doc = await _firestore
          .collection('lawyers')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          // Update to use firstName and lastName directly from database
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _genderController.text = data['gender'] ?? '';
          _educationController.text = data['education'] ?? '';
          _experienceController.text = data['experience']?.toString() ?? '';
          _languageController.text = data['language'] ?? '';
          _specializationController.text = data['specialization'] ?? '';
          _practiceCourtsController.text = data['practiceCourts'] ?? '';
          _profileImageUrl = data['profileImage'];
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
      _isLoading = false;
    }
  }

  // Update the _saveProfile method to use local storage
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final String uid = _auth.currentUser!.uid;
      String? localImagePath = _profileImageUrl;

      // Save new image if selected
      if (_profileImage != null) {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName = 'profile_$uid.jpg';
        final String newPath = '${appDir.path}/$fileName';
        
        // Copy the image to local storage
        await _profileImage!.copy(newPath);
        localImagePath = newPath;
      }      // Generate search keywords for better searchability
      List<String> searchKeywords = [];
      
      // Add name keywords
      String fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      searchKeywords.addAll(fullName.toLowerCase().split(' '));
      searchKeywords.add(_firstNameController.text.trim().toLowerCase());
      searchKeywords.add(_lastNameController.text.trim().toLowerCase());
      
      // Add current user's email prefix for existing lawyers
      String? email = _auth.currentUser?.email;
      if (email != null && email.contains('@')) {
        String emailPrefix = email.split('@')[0].toLowerCase();
        searchKeywords.add(emailPrefix);
        // Also add parts if email has dots or numbers
        if (emailPrefix.contains('.')) {
          searchKeywords.addAll(emailPrefix.split('.'));
        }
      }
      
      // Add specialization keywords
      if (_specializationController.text.trim().isNotEmpty) {
        searchKeywords.add(_specializationController.text.trim().toLowerCase());
        // Add words from specialization
        searchKeywords.addAll(_specializationController.text.trim().toLowerCase().split(' '));
      }
      
      // Add education keywords
      if (_educationController.text.trim().isNotEmpty) {
        searchKeywords.addAll(_educationController.text.trim().toLowerCase().split(' '));
      }
      
      // Add practice courts keywords
      if (_practiceCourtsController.text.trim().isNotEmpty) {
        searchKeywords.addAll(_practiceCourtsController.text.trim().toLowerCase().split(',').map((e) => e.trim()));
      }
      
      // Add language keywords
      if (_languageController.text.trim().isNotEmpty) {
        searchKeywords.addAll(_languageController.text.trim().toLowerCase().split(',').map((e) => e.trim()));
      }
      
      // Remove duplicates and empty strings
      searchKeywords = searchKeywords.where((keyword) => keyword.isNotEmpty).toSet().toList();

      // Update Firestore document with separate fields
      await _firestore.collection('lawyers').doc(uid).update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'gender': _genderController.text,
        'education': _educationController.text,
        'experience': int.tryParse(_experienceController.text) ?? 0,
        'language': _languageController.text,
        'specialization': _specializationController.text,
        'practiceCourts': _practiceCourtsController.text.trim(),
        'searchKeywords': searchKeywords, // Add the generated search keywords
        'profileImagePath': localImagePath,
        'profileComplete': true, // Mark profile as complete
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _genderController.dispose();
    _educationController.dispose();
    _experienceController.dispose();
    _languageController.dispose();
    _specializationController.dispose();
    _practiceCourtsController.dispose();
    _profileImage?.delete().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF353E55),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/lawyer/dashboard');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              _saveProfile();
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF353E55),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Replace the existing GestureDetector with this new implementation
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFFD0A554),
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (_profileImageUrl != null
                              ? FileImage(File(_profileImageUrl!))
                              : null),
                      child: (_profileImage == null && _profileImageUrl == null)
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0A554),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: PopupMenuButton<ImageSource>(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onSelected: _pickImage,
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: ImageSource.camera,
                              child: ListTile(
                                leading: Icon(Icons.camera_alt),
                                title: Text('Take Photo'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: ImageSource.gallery,
                              child: ListTile(
                                leading: Icon(Icons.photo_library),
                                title: Text('Choose from Gallery'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildProfileField('First Name', _firstNameController),
                _buildProfileField('Last Name', _lastNameController),
                _buildProfileField('Gender', _genderController),
                _buildProfileField('Education', _educationController),
                _buildProfileField('Experience', _experienceController),
                _buildProfileField('Language', _languageController),  // Changed from Languages to Language
                _buildProfileField('Specialization', _specializationController),
                _buildProfileField('Practice Courts', _practiceCourtsController, 
                  hint: 'e.g., Supreme Court, High Court'),
              ],
            ),
          ),
        ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveProfile,
        backgroundColor: const Color(0xFFD0A554),
        icon: const Icon(Icons.save),
        label: const Text('Save Profile'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF3D4559),
        selectedItemColor: const Color(0xFFD0A554),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/lawyer/dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/lawyer/bookings');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/lawyer/availability');
              break;
            case 3:
              // Already on profile page
              break;
          }
        },
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
      ),
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
          labelStyle: const TextStyle(color: Color(0xFFD0A554)),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFD0A554)),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          // Additional validation for practice courts
          if (label == 'Practice Courts' && !value.contains(',') && value.length < 10) {
            return 'Please enter multiple courts separated by commas';
          }
          return null;
        },
      ),
    );
  }
}