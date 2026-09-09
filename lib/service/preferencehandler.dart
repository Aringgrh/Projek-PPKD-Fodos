import 'dart:convert';
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

  static Future<void> setLogin(bool isLogin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLogin, isLogin);
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

  static String getSelectedLocation() {
    try {
      return _prefs.getString(_keySelectedLocation) ?? "Jl. Sudirman No. 45";
    } catch (_) {
      return "Jl. Sudirman No. 45";
    }
  }

  static String getSelectedLocationDetail() {
    try {
      return _prefs.getString(_keySelectedLocationDetail) ?? "Sekitar kamu";
    } catch (_) {
      return "Sekitar kamu";
    }
  }

  static Future<void> setSelectedLocation(
    String title, {
    String detail = "Sekitar kamu",
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedLocation, title);
    await prefs.setString(_keySelectedLocationDetail, detail);
  }

  // --- Saved Addresses ---

  static List<AddressModel> _getDefaultAddresses() {
    return [
      AddressModel(
        id: 'default-1',
        label: 'Rumah',
        address: 'Jl. Sudirman No. 45',
        detail: 'Kebayoran Baru, Jakarta Pusat (Dekat Gerbang Utama)',
        receiverName: 'Budi Santoso',
        receiverPhone: '081234567890',
        isDefault: true,
      ),
      AddressModel(
        id: 'default-2',
        label: 'Kantor',
        address: 'SCBD Lot 8, Gedung Energy Lt. 15',
        detail: 'Jl. Jend. Sudirman Kav. 52-53, Jakarta Selatan',
        receiverName: 'Budi Santoso',
        receiverPhone: '081234567890',
        isDefault: false,
      ),
      AddressModel(
        id: 'default-3',
        label: 'Apartemen',
        address: 'Green Pramuka City Tower Chrysant',
        detail: 'Lantai 12 Unit 08A, Cempaka Putih, Jakarta Pusat',
        receiverName: 'Budi Santoso',
        receiverPhone: '081234567890',
        isDefault: false,
      ),
      AddressModel(
        id: 'default-4',
        label: 'Kos',
        address: 'Jl. Kemang Raya No. 14',
        detail: 'Mampang Prapatan, Jakarta Selatan (Pagar Hitam)',
        receiverName: 'Budi Santoso',
        receiverPhone: '081234567890',
        isDefault: false,
      ),
    ];
  }

  static List<AddressModel> getSavedAddresses() {
    try {
      final raw = _prefs.getString(_keySavedAddresses);
      if (raw == null || raw.isEmpty) {
        return _getDefaultAddresses();
      }
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => AddressModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _getDefaultAddresses();
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
    await prefs.remove(_keyIsLogin);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserProfileImage);
  }
}
