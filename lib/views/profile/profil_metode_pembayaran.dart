import 'package:flutter/material.dart';

class MetodePembayaranProfile extends StatefulWidget {
  const MetodePembayaranProfile({super.key});

  @override
  State<MetodePembayaranProfile> createState() => _MetodePembayaranProfileState();
}

class _MetodePembayaranProfileState extends State<MetodePembayaranProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Metode Pembayaran")));
  }
}
