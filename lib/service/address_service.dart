import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:fodos/models/address_model.dart';
import 'package:fodos/service/preferencehandler.dart';

class AddressService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mengambil daftar alamat tersimpan pengguna saat ini dari Firebase Firestore (`users/{uid}/addresses`).
  static Future<List<AddressModel>> getUserAddresses() async {
    final user = _auth.currentUser;
    if (user == null) {
      return PreferenceHandler.getSavedAddresses();
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .get();

      final addresses = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return AddressModel.fromJson(data);
      }).toList();

      // Filter out any legacy dummy addresses if present
      final cleanAddresses = addresses
          .where((item) => !item.id.startsWith('default-'))
          .toList();

      // Sinkronkan ke cache lokal
      await PreferenceHandler.saveAddresses(cleanAddresses);
      return cleanAddresses;
    } catch (e) {
      debugPrint('AddressService.getUserAddresses error: $e');
      return PreferenceHandler.getSavedAddresses();
    }
  }

  /// Menambahkan alamat baru ke Firestore pengguna saat ini (`users/{uid}/addresses/{id}`).
  static Future<void> addAddress(AddressModel address) async {
    final user = _auth.currentUser;

    // Simpan lokal dulu sebagai fallback
    await PreferenceHandler.addSavedAddress(address);

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .doc(address.id)
            .set(address.toJson());
      } catch (e) {
        debugPrint('AddressService.addAddress error: $e');
      }
    }
  }

  /// Memperbarui data alamat yang sudah ada di Firestore.
  static Future<void> updateAddress(AddressModel address) async {
    final user = _auth.currentUser;

    await PreferenceHandler.updateSavedAddress(address);

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .doc(address.id)
            .set(address.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('AddressService.updateAddress error: $e');
      }
    }
  }

  /// Menghapus alamat dari Firestore.
  static Future<void> deleteAddress(String id) async {
    final user = _auth.currentUser;

    await PreferenceHandler.deleteSavedAddress(id);

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .doc(id)
            .delete();
      } catch (e) {
        debugPrint('AddressService.deleteAddress error: $e');
      }
    }
  }

  /// Menjadikan salah satu alamat sebagai alamat utama (default).
  static Future<void> setDefaultAddress(
    AddressModel item,
    List<AddressModel> currentList,
  ) async {
    final user = _auth.currentUser;

    final updatedList = currentList.map((a) {
      return a.copyWith(isDefault: a.id == item.id);
    }).toList();

    await PreferenceHandler.saveAddresses(updatedList);
    await PreferenceHandler.setSelectedLocation(
      item.address,
      detail: item.detail.isNotEmpty ? item.detail : item.label,
    );

    if (user != null) {
      try {
        // Update user document primary address field 'alamat'
        await _firestore.collection('users').doc(user.uid).update({
          'alamat': item.address,
        });

        // Batch update isDefault status across user addresses
        final batch = _firestore.batch();
        final collectionRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('addresses');

        for (var addr in updatedList) {
          batch.update(collectionRef.doc(addr.id), {
            'isDefault': addr.isDefault,
          });
        }
        await batch.commit();
      } catch (e) {
        debugPrint('AddressService.setDefaultAddress error: $e');
      }
    }
  }
}
