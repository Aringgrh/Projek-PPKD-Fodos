import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fodos/models/user_model.dart';
import 'package:fodos/service/preferencehandler.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseAuth get auth => _auth;
  GoogleSignIn get googleSignIn => _googleSignIn;
  User? get currentUser => _auth.currentUser;

  /// Melakukan proses Login menggunakan akun Google dan menghubungkannya ke Firebase Authentication.
  /// Mengembalikan [UserCredential] jika berhasil, atau `null` jika pengguna membatalkan dialog.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Membuka dialog pemilih akun Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Pengguna menutup / membatalkan dialog
        return null;
      }

      // 2. Mengambil detail autentikasi (token) dari Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Membuat kredensial Firebase menggunakan token Google
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Masuk ke Firebase Auth menggunakan kredensial
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // 5. Cek apakah dokumen user sudah ada di Firestore 'users'
        final docRef = _firestore.collection('users').doc(user.uid);
        final docSnap = await docRef.get();

        if (!docSnap.exists) {
          // Simpan data awal user ke Firestore
          final newUser = UserModelFirebase(
            uid: user.uid,
            name: user.displayName ?? (googleUser.displayName ?? 'Pengguna Fodos'),
            nomor: user.phoneNumber ?? '',
            email: user.email ?? (googleUser.email),
            alamat: '',
            createdAt: DateTime.now(),
          );
          await docRef.set(newUser.toMap());
        }

        // 6. Simpan sesi ke PreferenceHandler
        await PreferenceHandler.setLogin(true);
        await PreferenceHandler.setUserEmail(user.email ?? googleUser.email);
        if (user.photoURL != null && user.photoURL!.isNotEmpty) {
          await PreferenceHandler.setUserProfileImage(user.photoURL!);
        } else if (googleUser.photoUrl != null && googleUser.photoUrl!.isNotEmpty) {
          await PreferenceHandler.setUserProfileImage(googleUser.photoUrl!);
        }
      }

      return userCredential;
    } catch (e) {
      debugPrint('AuthService.signInWithGoogle error: $e');
      rethrow;
    }
  }

  /// Melakukan proses Login menggunakan Email dan Password via Firebase Authentication.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await PreferenceHandler.setLogin(true);
        await PreferenceHandler.setUserEmail(user.email ?? email);
        if (user.photoURL != null && user.photoURL!.isNotEmpty) {
          await PreferenceHandler.setUserProfileImage(user.photoURL!);
        }
      }

      return userCredential;
    } catch (e) {
      debugPrint('AuthService.signInWithEmail error: $e');
      rethrow;
    }
  }

  /// Melakukan proses Registrasi Akun baru menggunakan Email & Password,
  /// lalu menyimpan profil lengkap pengguna ke Cloud Firestore (`users`).
  Future<UserCredential> signUpWithEmail({
    required String name,
    required String nomor,
    required String email,
    required String password,
    String alamat = '',
  }) async {
    try {
      // 1. Buat akun di Firebase Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(name);

        // 2. Simpan data user ke Firestore
        final newUser = UserModelFirebase(
          uid: user.uid,
          name: name,
          nomor: nomor,
          email: email,
          alamat: alamat,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newUser.toMap());
      }

      return userCredential;
    } catch (e) {
      debugPrint('AuthService.signUpWithEmail error: $e');
      rethrow;
    }
  }

  /// Mengirimkan tautan reset kata sandi ke email pengguna.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('AuthService.sendPasswordResetEmail error: $e');
      rethrow;
    }
  }

  /// Mengambil data profil user dari Cloud Firestore berdasarkan UID.
  Future<UserModelFirebase?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModelFirebase.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('AuthService.getUserData error: $e');
      return null;
    }
  }

  /// Sign out dari Firebase Auth, Google Sign-In, serta menghapus cache lokal SharedPreferences.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('AuthService._auth.signOut error: $e');
    }

    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('AuthService._googleSignIn.signOut error: $e');
    }

    try {
      await PreferenceHandler.logOut();
    } catch (e) {
      debugPrint('AuthService.PreferenceHandler.logOut error: $e');
    }
  }
}
