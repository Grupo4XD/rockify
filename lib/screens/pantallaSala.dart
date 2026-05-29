import 'dart:convert';

import 'package:flutter/material.dart';

class Pantallasala extends StatefulWidget {
  final String? codigo;
  const Pantallasala({super.key,this.codigo});

  @override
  State<Pantallasala> createState() => _PantallasalaState();
}

class _PantallasalaState extends State<Pantallasala> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text("Tu codigo aqui es "),
    );
  }
}