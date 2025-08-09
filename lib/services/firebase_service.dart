import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_application_1/models/user.dart' as UserModel;
import 'package:flutter_application_1/models/post.dart';

class FirebaseService {
  // register user and add user data to firestore
  Future<UserCredential> register(
    String email,
    String password,
    String username,
    String role,
  ) async {
    // Create user with email and password in auth
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    // Add user info to Firestore 'users' collection
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({'email': email, 'username': username, 'role': role});
    return userCredential;
  }

  Future<UserCredential> login(email, password, role) async {
    var userCredentials = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    var userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .get();

    if (!userDoc.exists) {
      throw Exception("User record not found in database");
    }

    var roleData = userDoc.data()!["role"];
    if (roleData == role) {
      return userCredentials;
    } else {
      throw Exception("Make sure you login from the correct portal");
    }
  }

  Future<UserCredential> signInWithGoogle(String role) async {
    UserCredential userCredential;
    if (kIsWeb) {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      userCredential = await FirebaseAuth.instance.signInWithPopup(
        googleProvider,
      );
    } else {
      GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled.');
      }
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      var credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
    }

    // Check if user exists in Firestore
    var userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user?.uid)
            .get();
    if (!userDoc.exists) {
      // Add user info to firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
            'email': userCredential.user?.email ?? '',
            'username':
                userCredential.user?.displayName ??
                userCredential.user?.email ??
                'Unknown User',
            'role': role,
          });
    }
    return userCredential;
  }

  Stream<User?> getAuthUser() {
    return FirebaseAuth.instance.authStateChanges();
  }

  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  // Gets current user's info, if not supplies default information
  Stream<UserModel.User> getUser() {
    return FirebaseFirestore.instance.collection('users').doc(getCurrentUser()?.uid).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return UserModel.User(
          username: data['username'] ?? 'Unknown User',
          bio:
              data['bio'] ??
              "Environmental advocate passionate in promoting sustainable living and conservation",
          likes: data['likes'] ?? 200,
          posts: [
            // Default posts
            Post(
              title: "Post title",
              description:
                  "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in",
              likes: 100,
              dislikes: 1,
              poster: data['username'] ?? 'Unknown User',
              date_posted: DateTime.now().subtract(Duration(days: 1)),
            ),
            Post(
              title: "Post title",
              description:
                  "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in",
              likes: 100,
              dislikes: 1,
              poster: data['username'] ?? 'Unknown User',
              date_posted: DateTime.now().subtract(Duration(days: 1)),
            ),
          ],
        );
      } else {
        // Return default user if document doesn't exist
        return UserModel.User(
          username: 'Unknown User',
          bio:
              "Environmental advocate passionate in promoting sustainable living and conservation",
          likes: 200,
          posts: [
            Post(
              title: "Post title",
              description:
                  "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in",
              likes: 100,
              dislikes: 1,
              poster: "Unknown User",
              date_posted: DateTime.now().subtract(Duration(days: 1)),
            ),
            Post(
              title: "Post title",
              description:
                  "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in",
              likes: 100,
              dislikes: 1,
              poster: "Unknown User",
              date_posted: DateTime.now().subtract(Duration(days: 1)),
            ),
          ],
        );
      }
    });
  }

  Future<void> loginWithPhoneNumber(
    String phoneNumber,
    Future<String> Function(BuildContext context) getOtpFromUser,
    BuildContext context,
  ) async {
    FirebaseAuth auth = FirebaseAuth.instance;

    if (kIsWeb) {
      ConfirmationResult confirmationResult = await auth.signInWithPhoneNumber(
        phoneNumber,
      );

      String otp = await getOtpFromUser(context);

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: confirmationResult.verificationId,
        smsCode: otp,
      );
      await auth.signInWithCredential(credential);

      // login with phone number on mobile
    } else {
      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await auth.signInWithCredential(credential);
          } catch (e) {
            debugPrint('Automatic login failed: $e');
            rethrow;
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Verification failed: ${e.message}');
          throw Exception('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) async {
          String smsCode = await getOtpFromUser(context);
          PhoneAuthCredential credential = PhoneAuthProvider.credential(
            verificationId: verificationId,
            smsCode: smsCode,
          );
          await auth.signInWithCredential(credential);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Code auto retrieval timeout: $verificationId');
        },
      );
    }
  }

  // Add phone number to a user
  Future<void> linkPhoneNumberToCurrentUser(
    String phoneNumber,
    Future<String> Function(BuildContext context) getOtpFromUser,
    BuildContext context,
  ) async {
    FirebaseAuth auth = FirebaseAuth.instance;

    if (kIsWeb) {
      try {
        ConfirmationResult confirmationResult = await auth
            .signInWithPhoneNumber(phoneNumber);

        String otp = await getOtpFromUser(context);

        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: confirmationResult.verificationId,
          smsCode: otp,
        );

        await auth.currentUser?.linkWithCredential(credential);

        debugPrint("Phone number linked successfully on web.");
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          throw Exception(
            "This phone number is already linked to another account.",
          );
        } else {
          throw Exception("Failed to link phone number: ${e.message}");
        }
      }
      // For mobile platforms, verifyPhoneNumber method is used instead
    } else {
      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),

        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await auth.currentUser?.linkWithCredential(credential);
            debugPrint('Phone number linked automatically.');
          } catch (e) {
            debugPrint('Automatic linking failed: $e');
            rethrow;
          }
        },

        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Verification failed: ${e.message}');
          throw Exception('Verification failed: ${e.message}');
        },

        codeSent: (String verId, int? resendToken) async {
          String smsCode = await getOtpFromUser(context);

          PhoneAuthCredential credential = PhoneAuthProvider.credential(
            verificationId: verId,
            smsCode: smsCode,
          );

          await FirebaseAuth.instance.currentUser?.linkWithCredential(
            credential,
          );
        },
        codeAutoRetrievalTimeout: (String verId) {
          debugPrint('Code auto retrieval timeout: $verId');
        },
      );
    }
  }

  Future<void> logOut() {
    return FirebaseAuth.instance.signOut();
  }

  Future<void> forgotPassword(String email) {
    return FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  Future<void> changePassword(String newPassword) {
    User? user = FirebaseAuth.instance.currentUser;
    return user!.updatePassword(newPassword);
  }

  Future<void> deleteAccount() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      await user.delete();
    }
  }

  Future<void> updateEmail(String newEmail) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.verifyBeforeUpdateEmail(newEmail);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'email': newEmail},
      );
    }
  }
}
