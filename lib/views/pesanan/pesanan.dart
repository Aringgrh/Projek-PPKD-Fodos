import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/service/preferencehandler.dart';
import 'package:fodos/views/pesanan/pesanan_aktif_view.dart';
import 'package:fodos/views/pesanan/riwayat_view.dart';

class PesananTugas12 extends StatefulWidget {
  const PesananTugas12({super.key});

  @override
  State<PesananTugas12> createState() => _PesananTugas12State();
}

class _PesananTugas12State extends State<PesananTugas12> {
  String userId = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final currentFirebaseUser = FirebaseAuth.instance.currentUser;
    final uid = currentFirebaseUser?.uid ?? (PreferenceHandler.getUserEmail() ?? 'guest');
    setState(() {
      userId = uid;
    });
  }

  static const List<Tab> myTabs = <Tab>[
    Tab(text: "Aktif"),
    Tab(text: "Riwayat"),
  ];

  @override
  Widget build(BuildContext context) {
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
