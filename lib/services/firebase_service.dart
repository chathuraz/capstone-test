import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication Methods
  static Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Firestore Methods
  static Future<void> createUserProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).set(data);
  }

  static Future<void> createLawyerProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('lawyers').doc(userId).set(data);
  }

  static Future<void> createBooking(Map<String, dynamic> bookingData) async {
    await _firestore.collection('bookings').add(bookingData);
  }

  static Stream<QuerySnapshot> getLawyerBookings(String lawyerId) {
    return _firestore
        .collection('bookings')
        .where('lawyerId', isEqualTo: lawyerId)
        .snapshots();
  }

  static Stream<QuerySnapshot> getUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  static Stream<QuerySnapshot> getAllLawyers() {
    return _firestore.collection('lawyers').snapshots();
  }
}