import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fodos/models/address_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHandler {
  static late SharedPreferences _prefs;
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const _keyIsLogin = "isLogin";
  static const _keyUserEmail = "userEmail";
  static const _keyUserProfileImage = "userProfileImage";
  static const _keySelectedLocation = "selectedLocation";
  static const _keySelectedLocationDetail = "selectedLocationDetail";
  static const _keySavedAddresses = "savedAddresses";
  static const _keyIsSellerMode = "isSellerMode";

  static Future<void> setLogin(bool isLogin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLogin, isLogin);
  }

  static Future<void> setSellerMode(bool isSeller) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsSellerMode, isSeller);
  }

  static bool get isSellerMode {
    try {
      return _prefs.getBool(_keyIsSellerMode) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, email);
  }

  static String? getUserEmail() {
    try {
      return _prefs.getString(_keyUserEmail);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setUserProfileImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserProfileImage, path);
  }

  static String? getUserProfileImage() {
    try {
      return _prefs.getString(_keyUserProfileImage);
    } catch (_) {
      return null;
    }
  }

  static bool get isLogin {
    try {
      return _prefs.getBool(_keyIsLogin) ?? false;
    } catch (_) {
      return false;
    }
  }

  // --- Location Management ---

  static String _getUserLocationKey([String? uid]) {
    final currentUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null && currentUid.isNotEmpty) {
      return "${_keySelectedLocation}_$currentUid";
    }
    return _keySelectedLocation;
  }

  static String _getUserLocationDetailKey([String? uid]) {
    final currentUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null && currentUid.isNotEmpty) {
      return "${_keySelectedLocationDetail}_$currentUid";
    }
    return _keySelectedLocationDetail;
  }

  static String getSelectedLocation([String? uid]) {
    try {
      final key = _getUserLocationKey(uid);
      final val = _prefs.getString(key);
      if (val != null && val.isNotEmpty) {
        return val;
      }
      return "Pilih Lokasi Anda";
    } catch (_) {
      return "Pilih Lokasi Anda";
    }
  }

  static String getSelectedLocationDetail([String? uid]) {
    try {
      final key = _getUserLocationDetailKey(uid);
      final val = _prefs.getString(key);
      if (val != null && val.isNotEmpty) {
        return val;
      }
      return "Sekitar kamu";
    } catch (_) {
      return "Sekitar kamu";
    }
  }

  static Future<void> setSelectedLocation(
    String title, {
    String detail = "Sekitar kamu",
    String? uid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUid = uid ?? FirebaseAuth.instance.currentUser?.uid;

    if (currentUid != null && currentUid.isNotEmpty) {
      await prefs.setString("${_keySelectedLocation}_$currentUid", title);
      await prefs.setString("${_keySelectedLocationDetail}_$currentUid", detail);

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .update({
          'alamat': title,
          'alamatDetail': detail,
        });
      } catch (_) {}
    } else {
      await prefs.setString(_keySelectedLocation, title);
      await prefs.setString(_keySelectedLocationDetail, detail);
    }
  }

  // --- Saved Addresses ---

  static List<AddressModel> getSavedAddresses() {
    try {
      final raw = _prefs.getString(_keySavedAddresses);
      if (raw == null || raw.isEmpty) {
        return [];
      }
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = decoded
          .map((item) => AddressModel.fromJson(item as Map<String, dynamic>))
          .where((item) => !item.id.startsWith('default-'))
          .toList();

      if (raw.contains('default-')) {
        saveAddresses(list);
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAddresses(List<AddressModel> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = addresses.map((a) => a.toJson()).toList();
    await prefs.setString(_keySavedAddresses, jsonEncode(jsonList));
  }

  static Future<void> addSavedAddress(AddressModel address) async {
    final list = getSavedAddresses();
    list.insert(0, address);
    await saveAddresses(list);
  }

  static Future<void> deleteSavedAddress(String id) async {
    final list = getSavedAddresses();
    list.removeWhere((item) => item.id == id);
    await saveAddresses(list);
  }

  static Future<void> updateSavedAddress(AddressModel updated) async {
    final list = getSavedAddresses();
    final index = list.indexWhere((item) => item.id == updated.id);
    if (index != -1) {
      list[index] = updated;
      await saveAddresses(list);
    }
  }

  static Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      await prefs.remove("${_keySelectedLocation}_$uid");
      await prefs.remove("${_keySelectedLocationDetail}_$uid");
    }
    await prefs.remove(_keySelectedLocation);
    await prefs.remove(_keySelectedLocationDetail);
    await prefs.remove(_keySavedAddresses);
    await prefs.remove(_keyIsLogin);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserProfileImage);
  }
}
