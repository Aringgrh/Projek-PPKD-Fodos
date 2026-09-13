import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:fodos/models/product_model.dart';
import 'package:fodos/models/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreModel {
  final String id;
  final String namaToko;
  final String kategori;
  final String alamatToko;
  final bool isOpen;
  final DateTime createdAt;

  StoreModel({
    required this.id,
    required this.namaToko,
    required this.kategori,
    required this.alamatToko,
    this.isOpen = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  StoreModel copyWith({
    String? id,
    String? namaToko,
    String? kategori,
    String? alamatToko,
    bool? isOpen,
    DateTime? createdAt,
  }) {
    return StoreModel(
      id: id ?? this.id,
      namaToko: namaToko ?? this.namaToko,
      kategori: kategori ?? this.kategori,
      alamatToko: alamatToko ?? this.alamatToko,
      isOpen: isOpen ?? this.isOpen,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'namaToko': namaToko,
    'kategori': kategori,
    'alamatToko': alamatToko,
    'isOpen': isOpen,
    'createdAt': createdAt.toIso8601String(),
  };

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id']?.toString() ?? '',
      namaToko: json['namaToko']?.toString() ?? '',
      kategori: json['kategori']?.toString() ?? '',
      alamatToko: json['alamatToko']?.toString() ?? '',
      isOpen: json['isOpen'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SellerOrderModel {
  final String orderId;
  final String customerName;
  final String itemsSummary;
  final double totalPrice;
  final String status; // 'Pesanan Baru', 'Diproses', 'Selesai', 'Ditolak'
  final DateTime createdAt;

  SellerOrderModel({
    required this.orderId,
    required this.customerName,
    required this.itemsSummary,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });
}

class SellerService {
  static const String _keyHasStore = 'seller_has_store';
  static const String _keyStoreData = 'seller_store_data';
  static const String _keySellerProducts = 'seller_products_list';

  /// Cek apakah pengguna saat ini sudah memiliki toko terdaftar
  static Future<bool> hasStore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid;

      // Local check first
      final userStoreKey = uid != null ? '${_keyHasStore}_$uid' : _keyHasStore;
      final localHasStore = prefs.getBool(userStoreKey) ?? false;
      if (localHasStore) return true;

      // Firestore check if available
      if (uid != null && uid.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final store = StoreModel.fromJson(doc.data()!);
          await prefs.setBool(userStoreKey, true);
          await prefs.setString(
            '${_keyStoreData}_$uid',
            jsonEncode(store.toJson()),
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("Error checking store status: $e");
      return false;
    }
  }

  /// Mengambil data toko penjual aktif
  static Future<StoreModel?> getStore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final key = uid != null ? '${_keyStoreData}_$uid' : _keyStoreData;
      final raw = prefs.getString(key);

      if (raw != null && raw.isNotEmpty) {
        return StoreModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }

      // Try fetching from Firestore if user is authenticated
      if (uid != null && uid.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final store = StoreModel.fromJson(doc.data()!);
          await prefs.setBool('${_keyHasStore}_$uid', true);
          await prefs.setString(key, jsonEncode(store.toJson()));
          return store;
        }
      }
    } catch (e) {
      debugPrint("Error getting store model: $e");
    }
    return null;
  }

  /// Mendaftarkan toko baru
  static Future<StoreModel> registerStore({
    required String namaToko,
    required String kategori,
    required String alamatToko,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_seller';
    final store = StoreModel(
      id: uid,
      namaToko: namaToko,
      kategori: kategori,
      alamatToko: alamatToko,
      isOpen: true,
      createdAt: DateTime.now(),
    );

    final prefs = await SharedPreferences.getInstance();
    final userHasStoreKey = uid != 'guest_seller'
        ? '${_keyHasStore}_$uid'
        : _keyHasStore;
    final userStoreDataKey = uid != 'guest_seller'
        ? '${_keyStoreData}_$uid'
        : _keyStoreData;

    await prefs.setBool(userHasStoreKey, true);
    await prefs.setString(userStoreDataKey, jsonEncode(store.toJson()));

    // Seed dummy products for new store
    await _seedInitialProducts(store);

    // Sync to Firestore if authenticated
    try {
      if (uid != 'guest_seller') {
        await FirebaseFirestore.instance
            .collection('stores')
            .doc(uid)
            .set(store.toJson(), SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Firestore sync store registration info: $e");
    }

    return store;
  }

  /// Memperbarui status Buka / Tutup Toko
  static Future<void> toggleStoreStatus(bool isOpen) async {
    final store = await getStore();
    if (store == null) return;

    final updatedStore = store.copyWith(isOpen: isOpen);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_seller';
    final prefs = await SharedPreferences.getInstance();
    final key = uid != 'guest_seller' ? '${_keyStoreData}_$uid' : _keyStoreData;

    await prefs.setString(key, jsonEncode(updatedStore.toJson()));

    try {
      if (uid != 'guest_seller') {
        await FirebaseFirestore.instance.collection('stores').doc(uid).update({
          'isOpen': isOpen,
        });
      }
    } catch (e) {
      debugPrint("Error updating store open status on firestore: $e");
    }
  }

  /// Seed produk awal untuk demo toko baru
  static Future<void> _seedInitialProducts(StoreModel store) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_seller';
    final prefs = await SharedPreferences.getInstance();
    final key = '${_keySellerProducts}_$uid';

    final initialProducts = [
      ProductModel(
        id: 'p1',
        namaProduk: 'Nasi Goreng Spesial',
        namaToko: store.namaToko,
        alamatToko: store.alamatToko,
        kategori: store.kategori,
        gambarUrl:
            'https://images.unsplash.com/photo-1603133872878-684f208fb84b?q=80&w=400',
        harga: 25000,
        stok: 15,
        deskripsi:
            'Nasi goreng lezat dengan komplit telor, ayam suwir, dan kerupuk.',
      ),
      ProductModel(
        id: 'p2',
        namaProduk: 'Es Teh Manis Jumbo',
        namaToko: store.namaToko,
        alamatToko: store.alamatToko,
        kategori: 'Minuman',
        gambarUrl:
            'https://images.unsplash.com/photo-1556679343-c7306c1976bc?q=80&w=400',
        harga: 6000,
        stok: 30,
        deskripsi: 'Es teh segar melati ukuran jumbo.',
      ),
    ];

    final jsonList = initialProducts.map((p) => p.toJson()).toList();
    await prefs.setString(key, jsonEncode(jsonList));
  }

  /// Mengambil daftar produk milik toko penjual
  static Future<List<ProductModel>> getSellerProducts() async {
    try {
      final store = await getStore();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_seller';
      final prefs = await SharedPreferences.getInstance();
      final key = '${_keySellerProducts}_$uid';

      // Fetch from Firestore first if store name exists
      if (store != null && store.namaToko.isNotEmpty) {
        try {
          final query = await FirebaseFirestore.instance
              .collection('products')
              .where('namaToko', isEqualTo: store.namaToko)
              .get();

          if (query.docs.isNotEmpty) {
            final fsProducts = query.docs
                .map((doc) => ProductModel.fromFirestore(doc))
                .toList();
            // Cache locally
            final jsonList = fsProducts.map((p) => p.toJson()).toList();
            await prefs.setString(key, jsonEncode(jsonList));
            return fsProducts;
          }
        } catch (e) {
          debugPrint("Firestore fetch seller products error: $e");
        }
      }

      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching seller products: $e");
    }
    return [];
  }

  /// Menambah produk baru oleh penjual (Tersinkronisasi ke Firestore 'products' & Local)
  static Future<void> addSellerProduct(ProductModel product) async {
    try {
      // 1. Simpan ke Firestore agar langsung muncul di POV Pembeli (Home/Search)
      try {
        await FirebaseFirestore.instance.collection('products').add({
          'namaProduk': product.namaProduk,
          'namaToko': product.namaToko,
          'alamatToko': product.alamatToko,
          'kategori': product.kategori,
          'gambarUrl': product.gambarUrl,
          'harga': product.harga,
          'stok': product.stok,
          'deskripsi': product.deskripsi,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint("Firestore add product warning: $e");
      }

      // 2. Simpan ke local cache penjual
      final list = await getSellerProducts();
      list.insert(0, product);

      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_seller';
      final prefs = await SharedPreferences.getInstance();
      final key = '${_keySellerProducts}_$uid';

      final jsonList = list.map((p) => p.toJson()).toList();
      await prefs.setString(key, jsonEncode(jsonList));
    } catch (e) {
      debugPrint("Error adding seller product: $e");
    }
  }

  /// Memperbarui produk penjual
  static Future<void> updateSellerProduct(ProductModel product) async {
    try {
      try {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(product.id)
            .update({
              'namaProduk': product.namaProduk,
              'harga': product.harga,
              'stok': product.stok,
              'kategori': product.kategori,
              'gambarUrl': product.gambarUrl,
              'deskripsi': product.deskripsi,
            });
      } catch (e) {
        debugPrint("Firestore update product warning: $e");
      }

      final list = await getSellerProducts();
      final index = list.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        list[index] = product;
        final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_seller';
        final prefs = await SharedPreferences.getInstance();
        final key = '${_keySellerProducts}_$uid';

        final jsonList = list.map((p) => p.toJson()).toList();
        await prefs.setString(key, jsonEncode(jsonList));
      }
    } catch (e) {
      debugPrint("Error updating seller product: $e");
    }
  }

  /// Menghapus produk penjual
  static Future<void> deleteSellerProduct(String productId) async {
    try {
      try {
        await FirebaseFirestore.instance.collection('products').doc(productId).delete();
      } catch (e) {
        debugPrint("Firestore delete product warning: $e");
      }

      final list = await getSellerProducts();
      list.removeWhere((p) => p.id == productId);

      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_seller';
      final prefs = await SharedPreferences.getInstance();
      final key = '${_keySellerProducts}_$uid';

      final jsonList = list.map((p) => p.toJson()).toList();
      await prefs.setString(key, jsonEncode(jsonList));
    } catch (e) {
      debugPrint("Error deleting product: $e");
    }
  }

  /// Mengambil daftar pesanan masuk dummy untuk demo
  static List<SellerOrderModel> getDummyOrders() {
    return [
      SellerOrderModel(
        orderId: 'FD-8901',
        customerName: 'Budi Santoso',
        itemsSummary: '2x Nasi Goreng Spesial, 2x Es Teh Jumbo',
        totalPrice: 62000,
        status: 'Pesanan Baru',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      SellerOrderModel(
        orderId: 'FD-8898',
        customerName: 'Siti Rahma',
        itemsSummary: '1x Nasi Goreng Spesial',
        totalPrice: 25000,
        status: 'Pesanan Baru',
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      SellerOrderModel(
        orderId: 'FD-8876',
        customerName: 'Andi Pratama',
        itemsSummary: '3x Es Teh Manis Jumbo',
        totalPrice: 18000,
        status: 'Diproses',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }

  /// Mengambil daftar pesanan masuk sungguhan dari Firestore
  static Future<List<SellerOrderModel>> getSellerOrders() async {
    try {
      final store = await getStore();
      if (store == null || store.namaToko.isEmpty) return [];

      final query = await FirebaseFirestore.instance.collection('orders').get();

      List<SellerOrderModel> result = [];
      for (var doc in query.docs) {
        final order = OrderModelFirebase.fromFirestore(doc);
        // Cek item untuk toko ini
        final storeItems = order.items
            .where((item) => item.namaToko == store.namaToko)
            .toList();
        if (storeItems.isNotEmpty) {
          final itemsSummary = storeItems
              .map((e) => '${e.jumlah}x ${e.namaProduk}')
              .join(', ');
          final totalPrice = storeItems.fold(
            0.0,
            (acc, item) => acc + item.subtotal,
          );

          result.add(
            SellerOrderModel(
              orderId: order.id.isNotEmpty ? order.id : doc.id,
              customerName: order.userName.isNotEmpty
                  ? order.userName
                  : 'Pembeli',
              itemsSummary: itemsSummary,
              totalPrice: totalPrice,
              status: order.status,
              createdAt: order.createdAt,
            ),
          );
        }
      }
      // Urutkan dari yang terbaru
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return result;
    } catch (e) {
      debugPrint("Error fetching real orders: $e");
      return [];
    }
  }

  /// Mengambil daftar pesanan masuk secara real-time dari Firestore
  static Stream<List<SellerOrderModel>> streamSellerOrders(String namaToko) {
    if (namaToko.isEmpty) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('orders')
        .snapshots()
        .map((snapshot) {
      List<SellerOrderModel> result = [];
      for (var doc in snapshot.docs) {
        final order = OrderModelFirebase.fromFirestore(doc);
        final storeItems = order.items
            .where((item) => item.namaToko == namaToko)
            .toList();
        if (storeItems.isNotEmpty) {
          final itemsSummary = storeItems
              .map((e) => '${e.jumlah}x ${e.namaProduk}')
              .join(', ');
          final totalPrice = storeItems.fold(
            0.0,
            (acc, item) => acc + item.subtotal,
          );

          result.add(
            SellerOrderModel(
              orderId: order.id.isNotEmpty ? order.id : doc.id,
              customerName: order.userName.isNotEmpty
                  ? order.userName
                  : 'Pembeli',
              itemsSummary: itemsSummary,
              totalPrice: totalPrice,
              status: order.status,
              createdAt: order.createdAt,
            ),
          );
        }
      }
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return result;
    });
  }
}
