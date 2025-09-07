import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Check if user is anonymous
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  // Sign in anonymously
  Future<UserCredential?> signInAnonymously() async {
    try {
      final UserCredential result = await _auth.signInAnonymously();
      print('Anonymous sign in successful: ${result.user?.uid}');
      return result;
    } catch (e) {
      print('Anonymous sign in failed: $e');
      return null;
    }
  }

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await result.user?.updateDisplayName(displayName);

      // Reload user to get updated display name
      await result.user?.reload();
      final updatedUser = _auth.currentUser;

      print('Updated display name: ${updatedUser?.displayName}');

      // Create user document in Firestore
      await _firestore.collection('users').doc(result.user?.uid).set({
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'isAnonymous': false,
      });

      print('Email sign up successful: ${result.user?.uid}');
      return result;
    } catch (e) {
      print('Email sign up failed: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Email sign in successful: ${result.user?.uid}');
      return result;
    } catch (e) {
      print('Email sign in failed: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('Sign out successful');
    } catch (e) {
      print('Sign out failed: $e');
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // Delete user posts
        await _firestore
            .collection('user_posts')
            .where('userId', isEqualTo: user.uid)
            .get()
            .then((snapshot) {
              for (final doc in snapshot.docs) {
                doc.reference.delete();
              }
            });

        // Delete the user account
        await user.delete();
        print('Account deleted successfully');
        return true;
      }
      return false;
    } catch (e) {
      print('Delete account failed: $e');
      return false;
    }
  }

  // Get user display name
  String get userDisplayName {
    final user = _auth.currentUser;
    if (user?.isAnonymous == true) {
      return 'Anonymous';
    }
    final displayName =
        user?.displayName ?? user?.email?.split('@').first ?? 'User';
    print(
      'userDisplayName: $displayName, user.displayName: ${user?.displayName}, user.email: ${user?.email}',
    );
    return displayName;
  }

  // Get user email
  String? get userEmail => _auth.currentUser?.email;
}
