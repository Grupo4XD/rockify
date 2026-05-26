import 'package:flutter/material.dart';
import 'package:pruebas2_original/screens/pantallaHome.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: MyAppbar(),
        body: Container(
          width: double.infinity, // Se estira a todo lo ancho
          height: double.infinity, // Se estira a todo lo alto
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 4, 15, 45), 
          ),
          child: Pantallahome(),
        ),
      ),
    );
  }






  // ignore: non_constant_identifier_names
  AppBar MyAppbar() {
    return AppBar(
      //Hacemos el fondo del AppBar transparente para que se vea el gradiente de atrás
      backgroundColor: Color.fromARGB(255, 1, 94, 243),
      /*
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // Indicamos que el gradiente empiece en la esquina superior izquierda
            begin: Alignment.topLeft,
            // Y termine en la esquina inferior derecha (para que quede en diagonal)
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 3, 18, 58),
              Color.fromARGB(255, 1, 94, 243),
            ],
          ),
        ),
      ),
      */
      
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Rockify",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 10),
          Icon(Icons.music_note, size: 25, color: Colors.white),
        ],
      ),
    );
  }
}
