import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/database/db_helper.dart';
import 'package:fodos/service/preferencehandler.dart';
import 'package:fodos/views/pesanan/pesanan_aktif_view.dart';
import 'package:fodos/views/pesanan/riwayat_view.dart';

class PesananTugas12 extends StatefulWidget {
  const PesananTugas12({super.key});

  @override
  State<PesananTugas12> createState() => _PesananTugas12State();
}

class _PesananTugas12State extends State<PesananTugas12> {
  int userId = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final email = await PreferenceHandler.getUserEmail();
      if (email != null) {
        final user = await DBHelper().getUserByEmail(email);
        if (user != null && user.id != null) {
          setState(() {
            userId = user.id!;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  static const List<Tab> myTabs = <Tab>[
    Tab(text: "Aktif"),
    Tab(text: "Riwayat"),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: myTabs.length,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            "Pesanan Saya",
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0.5,
          bottom: const TabBar(
            tabs: myTabs,
            labelColor: AppColors.secondary,
            unselectedLabelColor: AppColors.textGrey,
            indicatorColor: AppColors.secondary,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          ),
        ),
        body: TabBarView(
          children: [
            PesananAktifView(userId: userId),
            RiwayatView(userId: userId),
          ],
        ),
      ),
    );
  }
}
