import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/views/home/home.dart';
import 'package:fodos/views/pesanan/pesanan.dart';
import 'package:fodos/views/profile/profile.dart';
import 'package:fodos/views/search/search.dart';

class BottomNavTugas12 extends StatefulWidget {
  final int initialIndex;
  const BottomNavTugas12({super.key, this.initialIndex = 0});

  @override
  State<BottomNavTugas12> createState() => _BottomNavTugas12State();
}

class _BottomNavTugas12State extends State<BottomNavTugas12> {
  late int pilihan;

  @override
  void initState() {
    super.initState();
    pilihan = widget.initialIndex;
  }

  void changeBottom(int index) {
    pilihan = index;
    setState(() {});
  }

  final List<Widget> pages = [
    HomeFodos(),
    HalamanPencarianFodos(),
    PesananTugas12(),
    ProfileTugas12(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: pilihan,
        onTap: changeBottom,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.search),
            label: 'Pencarian',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Pengaturan',
          ),
        ],
      ),
      body: pages.elementAt(pilihan),
    );
  }
}
