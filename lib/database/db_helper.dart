import 'package:fodos/model/favorit_model.dart';
import 'package:fodos/model/keranjang_model.dart';
import 'package:fodos/model/login_user_model.dart';
import 'package:fodos/model/pesanan_aktif_model.dart';
import 'package:fodos/model/produk_model.dart';
import 'package:fodos/model/riwayat_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fodos.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama TEXT UNIQUE,
            nomorhp TEXT,
            email TEXT UNIQUE,
            password TEXT,
            alamat TEXT,
            gambar TEXT
          )
        ''');
        await _createProdukTable(db);
        await _insertDummyProduk(db);
        await _createFavoritTable(db);
        await _createKeranjangTable(db);
        await _createRiwayatTable(db);
        await _createPesananAktifTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createProdukTable(db);
          await _insertDummyProduk(db);
        }
        if (oldVersion < 3) {
          await _createFavoritTable(db);
          await _createKeranjangTable(db);
          await _createRiwayatTable(db);
          await _createPesananAktifTable(db);
        }
        if (oldVersion < 4) {
          try {
            await db.execute("ALTER TABLE users ADD COLUMN gambar TEXT;");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE produk ADD COLUMN gambar TEXT;");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE keranjang ADD COLUMN gambar TEXT;");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE riwayat ADD COLUMN gambar TEXT;");
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE pesanan_aktif ADD COLUMN gambar TEXT;",
            );
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _createFavoritTable(Database db) async {
    await db.execute('''
      CREATE TABLE favorit(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        produk_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (produk_id) REFERENCES produk(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createKeranjangTable(Database db) async {
    await db.execute('''
      CREATE TABLE keranjang(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        produk_id INTEGER,
        jumlah INTEGER,
        catatan TEXT,
        gambar TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (produk_id) REFERENCES produk(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createRiwayatTable(Database db) async {
    await db.execute('''
      CREATE TABLE riwayat(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        produk_id INTEGER,
        jumlah INTEGER,
        total_harga REAL,
        tanggal TEXT,
        status TEXT,
        gambar TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (produk_id) REFERENCES produk(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createPesananAktifTable(Database db) async {
    await db.execute('''
      CREATE TABLE pesanan_aktif(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        produk_id INTEGER,
        jumlah INTEGER,
        total_harga REAL,
        tanggal TEXT,
        status TEXT,
        gambar TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (produk_id) REFERENCES produk(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createProdukTable(Database db) async {
    await db.execute('''
      CREATE TABLE produk(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_produk TEXT,
        nama_toko TEXT,
        harga REAL,
        stok INTEGER,
        kategori TEXT,
        gambar TEXT
      )
    ''');
  }

  Future<void> _insertDummyProduk(Database db) async {
    final dummyProduk = [
      {
        'nama_produk': 'Roti Tawar Gandum',
        'nama_toko': 'Sari Roti Bakery',
        'harga': 18000.0,
        'stok': 15,
        'kategori': 'roti',
        'gambar': 'assets/images/roti.jpg',
      },
      {
        'nama_produk': 'Croissant',
        'nama_toko': 'Holland Bakery',
        'harga': 12000.0,
        'stok': 25,
        'kategori': 'roti',
        'gambar': 'assets/images/cr.jpg',
      },
      {
        'nama_produk': 'Nasi Goreng Ayam',
        'nama_toko': 'Warung Nasi Goreng Mas Agus',
        'harga': 20000.0,
        'stok': 10,
        'kategori': 'makanan berat',
        'gambar': 'assets/images/nasi goreng.jpg',
      },
      {
        'nama_produk': 'Mie Goreng',
        'nama_toko': 'Resto Rasa Nusantara',
        'harga': 22000.0,
        'stok': 8,
        'kategori': 'makanan berat',
        'gambar': 'assets/images/mie.jpg',
      },
    ];

    for (var produk in dummyProduk) {
      await db.insert('produk', produk);
    }
  }

  Future<bool> registerUser(UserModelLoginSQL pengguna) async {
    final db = await database;

    try {
      await db.insert('users', pengguna.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<UserModelLoginSQL?> loginUser(String email, String password) async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (results.isNotEmpty) {
      return UserModelLoginSQL.fromMap(results.first);
    }
    return null;
  }

  Future<List<UserModelLoginSQL>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query('users');
    return results.map((map) => UserModelLoginSQL.fromMap(map)).toList();
  }

  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> updateUser(UserModelLoginSQL pengguna) async {
    final db = await database;

    try {
      int count = await db.update(
        'users',
        pengguna.toMap(),
        where: 'id = ?',
        whereArgs: [pengguna.id],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  Future<UserModelLoginSQL?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      return UserModelLoginSQL.fromMap(results.first);
    }
    return null;
  }

  Future<UserModelLoginSQL?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (results.isNotEmpty) {
      return UserModelLoginSQL.fromMap(results.first);
    }
    return null;
  }
  // --- PRODUK OPERATIONS ---

  Future<bool> insertProduk(ProdukModel produk) async {
    final db = await database;
    try {
      await db.insert('produk', produk.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<ProdukModel>> getAllProduk() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query('produk');
    return results.map((map) => ProdukModel.fromMap(map)).toList();
  }

  Future<List<ProdukModel>> getProdukByKategori(String kategori) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'produk',
      where: 'kategori = ?',
      whereArgs: [kategori],
    );
    return results.map((map) => ProdukModel.fromMap(map)).toList();
  }

  Future<ProdukModel?> getProdukById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'produk',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return ProdukModel.fromMap(results.first);
    }
    return null;
  }

  Future<bool> kurangiStokProduk(int produkId, int jumlah) async {
    final db = await database;
    try {
      int count = await db.rawUpdate(
        'UPDATE produk SET stok = MAX(0, stok - ?) WHERE id = ?',
        [jumlah, produkId],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProduk(ProdukModel produk) async {
    final db = await database;
    try {
      int count = await db.update(
        'produk',
        produk.toMap(),
        where: 'id = ?',
        whereArgs: [produk.id],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProduk(int id) async {
    final db = await database;
    try {
      int count = await db.delete('produk', where: 'id = ?', whereArgs: [id]);
      return count > 0;
    } catch (e) {
      return false;
    }
  }
  // --- FAVORIT OPERATIONS ---

  Future<bool> insertFavorit(FavoritModel favorit) async {
    final db = await database;
    try {
      await db.insert('favorit', favorit.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<FavoritModel>> getFavoritByUserId(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'favorit',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return results.map((map) => FavoritModel.fromMap(map)).toList();
  }

  Future<bool> isFavorit(int userId, int produkId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'favorit',
      where: 'user_id = ? AND produk_id = ?',
      whereArgs: [userId, produkId],
    );
    return results.isNotEmpty;
  }

  Future<bool> deleteFavorit(int userId, int produkId) async {
    final db = await database;
    try {
      int count = await db.delete(
        'favorit',
        where: 'user_id = ? AND produk_id = ?',
        whereArgs: [userId, produkId],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  // --- KERANJANG OPERATIONS ---

  Future<bool> insertKeranjang(KeranjangModel item) async {
    final db = await database;
    try {
      // Check if item already exists in user's cart
      final List<Map<String, dynamic>> existing = await db.query(
        'keranjang',
        where: 'user_id = ? AND produk_id = ?',
        whereArgs: [item.userId, item.produkId],
      );

      if (existing.isNotEmpty) {
        // Update quantity
        final int currentJumlah = existing.first['jumlah'] as int;
        int count = await db.update(
          'keranjang',
          {'jumlah': currentJumlah + item.jumlah},
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
        return count > 0;
      } else {
        // Insert new
        await db.insert('keranjang', item.toMap());
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  Future<List<KeranjangModel>> getKeranjangByUserId(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'keranjang',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return results.map((map) => KeranjangModel.fromMap(map)).toList();
  }

  Future<bool> updateKeranjangJumlah(int id, int jumlah) async {
    final db = await database;
    try {
      int count = await db.update(
        'keranjang',
        {'jumlah': jumlah},
        where: 'id = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteKeranjang(int id) async {
    final db = await database;
    try {
      int count = await db.delete(
        'keranjang',
        where: 'id = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearKeranjangByUserId(int userId) async {
    final db = await database;
    try {
      int count = await db.delete(
        'keranjang',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  // --- RIWAYAT OPERATIONS ---

  Future<bool> insertRiwayat(RiwayatModel riwayat) async {
    final db = await database;
    try {
      await db.insert('riwayat', riwayat.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<RiwayatModel>> getRiwayatByUserId(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'riwayat',
      where: 'user_id = ?',
      orderBy: 'tanggal DESC',
      whereArgs: [userId],
    );
    return results.map((map) => RiwayatModel.fromMap(map)).toList();
  }

  // --- PESANAN AKTIF OPERATIONS ---

  Future<bool> insertPesananAktif(PesananAktifModel pesanan) async {
    final db = await database;
    try {
      await db.insert('pesanan_aktif', pesanan.toMap());
      // Kurangi stok produk secara otomatis saat pembelian berhasil
      await db.rawUpdate(
        'UPDATE produk SET stok = MAX(0, stok - ?) WHERE id = ?',
        [pesanan.jumlah, pesanan.produkId],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<PesananAktifModel>> getPesananAktifByUserId(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'pesanan_aktif',
      where: 'user_id = ?',
      orderBy: 'tanggal DESC',
      whereArgs: [userId],
    );
    return results.map((map) => PesananAktifModel.fromMap(map)).toList();
  }

  Future<bool> updatePesananAktifStatus(int id, String status) async {
    final db = await database;
    try {
      int count = await db.update(
        'pesanan_aktif',
        {'status': status},
        where: 'id = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePesananAktif(int id) async {
    final db = await database;
    try {
      int count = await db.delete(
        'pesanan_aktif',
        where: 'id = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  // --- JOIN OPERATIONS ---

  Future<List<ProdukModel>> getFavoritProductsByUserId(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT p.* FROM produk p
      INNER JOIN favorit f ON p.id = f.produk_id
      WHERE f.user_id = ?
    ''',
      [userId],
    );
    return results.map((map) => ProdukModel.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getCartWithProductDetails(
    int userId,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT k.id as cart_id, k.jumlah, k.catatan, p.id as produk_id, p.nama_produk, p.nama_toko, p.harga, p.gambar
      FROM keranjang k
      INNER JOIN produk p ON k.produk_id = p.id
      WHERE k.user_id = ?
    ''',
      [userId],
    );
  }

  // --- JOIN OPERATIONS FOR PESANAN ---

  Future<List<Map<String, dynamic>>> getPesananAktifWithProductDetails(
    int userId,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT pa.id as pesanan_id, pa.jumlah, pa.total_harga, pa.tanggal, pa.status, pa.gambar,
             p.id as produk_id, p.nama_produk, p.nama_toko, p.harga
      FROM pesanan_aktif pa
      INNER JOIN produk p ON pa.produk_id = p.id
      WHERE pa.user_id = ?
      ORDER BY pa.tanggal DESC
      ''',
      [userId],
    );
  }

  Future<List<Map<String, dynamic>>> getRiwayatWithProductDetails(
    int userId,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT r.id as riwayat_id, r.jumlah, r.total_harga, r.tanggal, r.status, r.gambar,
             p.id as produk_id, p.nama_produk, p.nama_toko, p.harga
      FROM riwayat r
      INNER JOIN produk p ON r.produk_id = p.id
      WHERE r.user_id = ?
      ORDER BY r.tanggal DESC
      ''',
      [userId],
    );
  }

  Future<bool> selesaikanPesanan(int pesananAktifId) async {
    final db = await database;
    try {
      // 1. Dapatkan detail pesanan aktif
      final List<Map<String, dynamic>> results = await db.query(
        'pesanan_aktif',
        where: 'id = ?',
        whereArgs: [pesananAktifId],
      );
      if (results.isEmpty) return false;
      final pesananMap = results.first;

      // 2. Masukkan ke riwayat dengan status Selesai
      await db.insert('riwayat', {
        'user_id': pesananMap['user_id'],
        'produk_id': pesananMap['produk_id'],
        'jumlah': pesananMap['jumlah'],
        'total_harga': pesananMap['total_harga'],
        'tanggal': DateTime.now().toLocal().toString().substring(0, 16),
        'status': 'Selesai',
        'gambar': pesananMap['gambar'],
      });

      // 3. Hapus dari pesanan aktif
      int count = await db.delete(
        'pesanan_aktif',
        where: 'id = ?',
        whereArgs: [pesananAktifId],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> batalkanPesanan(int pesananAktifId) async {
    final db = await database;
    try {
      // 1. Dapatkan detail pesanan aktif
      final List<Map<String, dynamic>> results = await db.query(
        'pesanan_aktif',
        where: 'id = ?',
        whereArgs: [pesananAktifId],
      );
      if (results.isEmpty) return false;
      final pesananMap = results.first;

      // 2. Masukkan ke riwayat dengan status Dibatalkan
      await db.insert('riwayat', {
        'user_id': pesananMap['user_id'],
        'produk_id': pesananMap['produk_id'],
        'jumlah': pesananMap['jumlah'],
        'total_harga': pesananMap['total_harga'],
        'tanggal': DateTime.now().toLocal().toString().substring(0, 16),
        'status': 'Dibatalkan',
        'gambar': pesananMap['gambar'],
      });

      // 3. Kembalikan stok produk jika pesanan dibatalkan
      final int pesananJumlah = (pesananMap['jumlah'] ?? 0) as int;
      final int pesananProdukId = (pesananMap['produk_id'] ?? 0) as int;
      await db.rawUpdate(
        'UPDATE produk SET stok = stok + ? WHERE id = ?',
        [pesananJumlah, pesananProdukId],
      );

      // 4. Hapus dari pesanan aktif
      int count = await db.delete(
        'pesanan_aktif',
        where: 'id = ?',
        whereArgs: [pesananAktifId],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }
}
