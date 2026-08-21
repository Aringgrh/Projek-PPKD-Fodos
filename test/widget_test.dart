import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fodos/service/preferencehandler.dart';
import 'package:fodos/model/produk_model.dart';
import 'package:fodos/splash_screen.dart';
import 'package:fodos/views/login/halaman_login.dart';
import 'package:fodos/views/login/halaman_pendaftaran.dart';
import 'package:fodos/views/home/bottom_nav.dart';
import 'package:fodos/views/home/home.dart';
import 'package:fodos/views/home/detail_makanan.dart';
import 'package:fodos/views/home/halaman_keranjang.dart';
import 'package:fodos/views/home/halaman_favorit.dart';
import 'package:fodos/views/pesanan/pesanan.dart';
import 'package:fodos/views/pesanan/pesanan_aktif_view.dart';
import 'package:fodos/views/pesanan/riwayat_view.dart';
import 'package:fodos/views/search/search.dart';
import 'package:fodos/views/profile/profile.dart';
import 'package:fodos/views/profile/informasi_pribadi.dart';
import 'package:fodos/views/profile/profil_alamat.dart';
import 'package:fodos/views/profile/profil_keamanan.dart';
import 'package:fodos/views/profile/profil_metode_pembayaran.dart';
import 'package:fodos/views/profile/profil_tentang_aplikasi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferenceHandler.init();
  });

  final dummyProduk = ProdukModel(
    id: 1,
    namaProduk: 'Donat Coklat Premium Penyelamatan Super Lezat',
    namaToko: 'Toko Roti & Pastry Berkah Sejahtera',
    kategori: 'roti',
    harga: 15000.0,
    stok: 5,
    gambar: 'assets/images/logoo.png',
  );

  Widget createTestWidget(Widget child, {Size size = const Size(360, 640)}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    );
  }

  testWidgets('Test Splash Screen on small viewport', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(createTestWidget(const SplashScreenTugas12(), size: const Size(320, 568)));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(SplashScreenTugas12), findsOneWidget);
  });

  testWidgets('Test Halaman Login on small viewport', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(createTestWidget(const HalamanLoginFodos(), size: const Size(320, 568)));
    expect(find.byType(HalamanLoginFodos), findsOneWidget);
  });

  testWidgets('Test Halaman Pendaftaran on small viewport', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(createTestWidget(const HalamanPendaftaranFodos(), size: const Size(320, 568)));
    expect(find.byType(HalamanPendaftaranFodos), findsOneWidget);
  });

  testWidgets('Test Bottom Navigation and Home View', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    await tester.pumpWidget(createTestWidget(const BottomNavTugas12(), size: const Size(360, 640)));
    expect(find.byType(BottomNavTugas12), findsOneWidget);
  });

  testWidgets('Test HomeFodos View directly', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(createTestWidget(const HomeFodos(), size: const Size(320, 568)));
    expect(find.byType(HomeFodos), findsOneWidget);
  });

  testWidgets('Test DetailMakanan View on narrow screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(createTestWidget(DetailMakanan(produk: dummyProduk), size: const Size(320, 568)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DetailMakanan), findsOneWidget);
  });

  testWidgets('Test HalamanKeranjang View', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(createTestWidget(const HalamanKeranjang(), size: const Size(320, 568)));
    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(HalamanKeranjang), findsOneWidget);
  });

  testWidgets('Test HalamanFavorit View', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(createTestWidget(const HalamanFavorit(), size: const Size(320, 568)));
    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(HalamanFavorit), findsOneWidget);
  });

  testWidgets('Test PesananTugas12 View', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    await tester.pumpWidget(createTestWidget(const PesananTugas12(), size: const Size(360, 640)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PesananTugas12), findsOneWidget);
  });

  testWidgets('Test PesananAktifView View', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(createTestWidget(const PesananAktifView(userId: 1), size: const Size(320, 568)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PesananAktifView), findsOneWidget);
  });

  testWidgets('Test RiwayatView View', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(createTestWidget(const RiwayatView(userId: 1), size: const Size(320, 568)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(RiwayatView), findsOneWidget);
  });

  testWidgets('Test HalamanPencarianFodos View', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(createTestWidget(const HalamanPencarianFodos(), size: const Size(320, 568)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(HalamanPencarianFodos), findsOneWidget);
  });

  testWidgets('Test ProfileTugas12 View', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(createTestWidget(const ProfileTugas12(), size: const Size(320, 568)));
    expect(find.byType(ProfileTugas12), findsOneWidget);
  });

  testWidgets('Test InformasiPribadi View', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(createTestWidget(const InformasiPribadi(), size: const Size(320, 568)));
    expect(find.byType(InformasiPribadi), findsOneWidget);
  });

  testWidgets('Test ProfilAlamat View', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(createTestWidget(const ProfilAlamat(), size: const Size(320, 568)));
    expect(find.byType(ProfilAlamat), findsOneWidget);
  });

  testWidgets('Test ProfilKeamanan View', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(createTestWidget(const ProfilKeamanan(), size: const Size(320, 568)));
    expect(find.byType(ProfilKeamanan), findsOneWidget);
  });

  testWidgets('Test MetodePembayaranProfile View', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(createTestWidget(const MetodePembayaranProfile(), size: const Size(320, 568)));
    expect(find.byType(MetodePembayaranProfile), findsOneWidget);
  });

  testWidgets('Test ProfilTentangAplikasi View', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(createTestWidget(const ProfilTentangAplikasi(), size: const Size(320, 568)));
    expect(find.byType(ProfilTentangAplikasi), findsOneWidget);
  });
}
