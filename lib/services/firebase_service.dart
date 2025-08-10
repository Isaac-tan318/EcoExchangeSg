import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_application_1/models/user.dart' as UserModel;
import 'package:flutter_application_1/models/event.dart' as EventModel;
import 'package:flutter_application_1/models/post.dart';

class FirebaseService {
  // Firestore collection for posts
  final CollectionReference<Map<String, dynamic>> _postsCollection =
      FirebaseFirestore.instance.collection('posts');
  // Firestore collection for events
  final CollectionReference<Map<String, dynamic>> _eventsCollection =
      FirebaseFirestore.instance.collection('events');

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

  // Role helpers
  Future<String?> _getCurrentUserRole() async {
    final user = getCurrentUser();
    if (user == null) return null;
    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      return snap.data()?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isCurrentUserOrganiser() async {
    final role = await _getCurrentUserRole();
    return role == 'organiser' || role == 'organizer';
  }

  // Gets current user's info, if not supplies default information
  Stream<UserModel.User> getUser() {
    final uid = getCurrentUser()?.uid;
    if (uid == null) {
      // If no authenticated user yet, return a single default value to avoid null doc IDs.
      return Stream.value(
        UserModel.User(
          username: 'Unknown User',
          bio:
              "Environmental advocate passionate in promoting sustainable living and conservation",
          posts: const [],
        ),
      );
    }
  return FirebaseFirestore.instance.collection('users').doc(uid).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return UserModel.User(
      pfp: (data['pfp'] ?? ''),
          username: (data['username'] ?? 'Unknown User'),
          bio:
              (data['bio'] ??
                  "Environmental advocate passionate in promoting sustainable living and conservation"),
          posts: const [],
        );
      } else {
        // Return default user if document doesn't exist
        return UserModel.User(
      pfp: '',
          username: 'Unknown User',
          bio:
              "Environmental advocate passionate in promoting sustainable living and conservation",
          posts: const [],
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

  // Update current user's profile fields (e.g., pfp, username, bio)
  Future<void> updateCurrentUserProfile(Map<String, dynamic> data) async {
    final user = getCurrentUser();
    if (user == null) throw Exception('Not authenticated');
    final payload = Map<String, dynamic>.from(data);
    payload.removeWhere((k, v) => v == null);
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      payload,
      SetOptions(merge: true),
    );
  }

  // Posts CRUD

  // validation
  bool _isBlank(dynamic v) => v == null || (v is String && v.trim().isEmpty);

  void _validatePostCreate(Post post) {
    if (_isBlank(post.title)) {
      throw Exception('Title is required');
    }
    if (_isBlank(post.description)) {
      throw Exception('Description is required');
    }
  }

  void _validatePostUpdate(Map<String, dynamic> data) {
    if (data.isEmpty) {
      throw Exception('No fields to update');
    }
    if (data.containsKey('title') && _isBlank(data['title'])) {
      throw Exception('Title cannot be empty');
    }
    if (data.containsKey('description') && _isBlank(data['description'])) {
      throw Exception('Description cannot be empty');
    }
  }

  // Create a new post. Returns the created document ID.
  Future<String> createPost(Post post) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    // Validate required fields
    _validatePostCreate(post);

    final docRef = _postsCollection.doc();

    // Fetch username for poster label (fallback to email if unavailable)
    String posterName = user.email ?? 'Unknown User';
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final uname = userDoc.data()?['username'];
      if (uname is String && uname.trim().isNotEmpty) {
        posterName = uname.trim();
      }
    } catch (_) {
      // ignore and use fallback
    }

    final data = <String, dynamic>{
      'title': (post.title is String) ? post.title : post.title?.toString(),
      'description':
          (post.description is String)
              ? post.description
              : post.description?.toString(),
      'poster': post.poster ?? posterName,
      'authorId': user.uid,
      'date_posted': FieldValue.serverTimestamp(),
      if (post.imageBase64 != null && post.imageBase64!.isNotEmpty)
        'imageBase64': post.imageBase64,
    };

    await docRef.set(data);
    return docRef.id;
  }

  // Get a single post by ID
  Future<Post?> getPost(String id) async {
    final snap = await _postsCollection.doc(id).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    return _postFromMap({...data, 'id': snap.id});
  }

  // Stream posts with optional ordering and date range filtering
  // - Select with filter criteria (other than identifier)
  // - Select with multiple filter criteria (same field)
  // - Select with multiple filter criteria (different fields)
  // - Select with sort order
  Stream<List<Post>> getAllPostsAsStream({
    String? authorId,
    bool descending = true,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query<Map<String, dynamic>> q = _postsCollection;
    final bool hasAuthor = authorId != null;
    final bool hasRange = startDate != null || endDate != null;
    bool serverOrders = false; // whether we apply server-side orderBy

    // Select with filter criteria (other than identifier):
    // Filter posts by authorId if provided.
    if (authorId != null) {
      q = q.where('authorId', isEqualTo: authorId);
    }

    // Select with multiple filter criteria (same field):
    // Date range filters on the same field 'date_posted'.
    if (startDate != null) {
      q = q.where(
        'date_posted',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      q = q.where(
        'date_posted',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    // Select with sort order:
    // If there is a date range inequality, Firestore requires orderBy on that field.
    // If there is no range and no author filter, we can order on server.
    // If filtering by author only, skip server-side order to avoid composite index,
    // and we will sort on client instead.
    if (hasRange) {
      q = q.orderBy('date_posted', descending: descending);
      serverOrders = true;
    } else if (!hasAuthor) {
      q = q.orderBy('date_posted', descending: descending);
      serverOrders = true;
    } else {
      serverOrders = false;
    }

    // Select with multiple filter criteria (different fields):
    // The combination of where('authorId' == ...) and where on 'date_posted'
    // above constitutes multi-field filtering. This may require a composite index
    // in Firestore (authorId asc, date_posted asc/desc). If you see an index error,
    // follow the link in the error to create the suggested index.

    return q.snapshots().map((s) {
      final list =
          s.docs.map((d) => _postFromMap({...d.data(), 'id': d.id})).toList();
      if (!serverOrders) {
        list.sort(
          (a, b) =>
              descending
                  ? b.date_posted.compareTo(a.date_posted)
                  : a.date_posted.compareTo(b.date_posted),
        );
      }
      return list;
    });
  }

  // Update an existing post by ID
  Future<void> updatePost(String id, Post post) async {
    // Build update map and normalize types
    final data = <String, dynamic>{
      'title': (post.title is String) ? post.title : post.title?.toString(),
      'description':
          (post.description is String)
              ? post.description
              : post.description?.toString(),
      'poster': (post.poster is String) ? post.poster : post.poster?.toString(),
    };
    // Remove nulls to avoid accidentally clearing fields;
    data.removeWhere((key, value) => value == null);

    // Validate update payload
    _validatePostUpdate(data);

    await _postsCollection.doc(id).update(data);
  }

  // Delete a post by ID
  Future<void> deletePost(String id) async {
    final postRef = _postsCollection.doc(id);
    // Primary: delete the post document.
    await postRef.delete();
  }

  // Increment awards counter on a post (creates field if missing)
  Future<void> incrementPostAwards(String id) async {
    await _postsCollection.doc(id).set(
      {
        'awards': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );
  }

  // Helper to convert Firestore map to the Post model
  Post _postFromMap(Map<String, dynamic> map) {
    final ts = map['date_posted'];
    DateTime? postedAt;
    if (ts is Timestamp) {
      postedAt = ts.toDate();
    } else if (ts is DateTime) {
      postedAt = ts;
    }
    final posterVal = map['poster'];
    return Post(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      poster:
          posterVal is String
              ? posterVal
              : (posterVal?.toString() ?? 'Unknown User'),
      authorId: map['authorId'],
      date_posted: postedAt ?? DateTime.now(),
      imageBase64: map['imageBase64'] as String?,
    );
  }

  // =========================
  // Events CRUD
  // =========================

  EventModel.Event _eventFromMap(Map<String, dynamic> map) {
    final startTs = map['startDateTime'];
    final endTs = map['endDateTime'];
    DateTime? start;
    DateTime? end;
    if (startTs is Timestamp) start = startTs.toDate();
    if (endTs is Timestamp) end = endTs.toDate();
    return EventModel.Event(
      id: map['id'] as String?,
      title: map['title'] as String?,
      description: map['description'] as String?,
      location: map['location'] as String?,
      startDateTime: start,
      endDateTime: end,
      authorId: map['authorId'] as String?,
      createdAt:
          (map['createdAt'] is Timestamp)
              ? (map['createdAt'] as Timestamp).toDate()
              : null,
      imageBase64: map['imageBase64'] as String?,
    );
  }

  Future<String> createEvent(EventModel.Event event) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final isOrg = await isCurrentUserOrganiser();
    if (!isOrg) throw Exception('Only organisers can create events');

    if (_isBlank(event.title)) throw Exception('Title is required');
    if (_isBlank(event.description)) throw Exception('Description is required');
    if (_isBlank(event.location)) throw Exception('Location is required');
    if (event.startDateTime == null || event.endDateTime == null) {
      throw Exception('Start and end date/time are required');
    }

    final docRef = _eventsCollection.doc();
    await docRef.set({
      'title': event.title,
      'description': event.description,
      'location': event.location,
      'startDateTime': Timestamp.fromDate(event.startDateTime!),
      'endDateTime': Timestamp.fromDate(event.endDateTime!),
      'authorId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      if (event.imageBase64 != null && event.imageBase64!.isNotEmpty)
        'imageBase64': event.imageBase64,
    });
    return docRef.id;
  }

  Stream<List<EventModel.Event>> getEventsAsStream({
    bool orderByStartAsc = true,
  }) {
    // Select with sort order: order events by startDateTime.
    Query<Map<String, dynamic>> q = _eventsCollection.orderBy(
      'startDateTime',
      descending: !orderByStartAsc,
    );
    return q.snapshots().map(
      (s) =>
          s.docs.map((d) => _eventFromMap({...d.data(), 'id': d.id})).toList(),
    );
  }

  Future<EventModel.Event?> getEvent(String id) async {
    final snap = await _eventsCollection.doc(id).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    return _eventFromMap({...data, 'id': snap.id});
  }

  // Select with aggregation:
  // Example helper using Firestore count() aggregation for posts.
  Future<int> countPosts({
    String? authorId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query<Map<String, dynamic>> q = _postsCollection;
    if (authorId != null) {
      q = q.where('authorId', isEqualTo: authorId);
    }
    if (startDate != null) {
      q = q.where(
        'date_posted',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      q = q.where(
        'date_posted',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }
    final aggSnap = await q.count().get();
    return aggSnap.count ?? 0;
  }

  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    if (data.isEmpty) throw Exception('No fields to update');
    // sanitize
    final payload = Map<String, dynamic>.from(data);
    payload.removeWhere((k, v) => v == null);
    if (payload.containsKey('startDateTime') &&
        payload['startDateTime'] is DateTime) {
      payload['startDateTime'] = Timestamp.fromDate(payload['startDateTime']);
    }
    if (payload.containsKey('endDateTime') &&
        payload['endDateTime'] is DateTime) {
      payload['endDateTime'] = Timestamp.fromDate(payload['endDateTime']);
    }
    await _eventsCollection.doc(id).update(payload);
  }

  Future<void> deleteEvent(String id) async {
    await _eventsCollection.doc(id).delete();
  }

  // Increment awards counter on an event (creates field if missing)
  Future<void> incrementEventAwards(String id) async {
    await _eventsCollection.doc(id).set(
      {
        'awards': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );
  }
}
