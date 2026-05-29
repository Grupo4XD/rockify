import 'package:flutter/material.dart';

class Pantallalogin extends StatefulWidget {
  const Pantallalogin({super.key});

  @override
  State<Pantallalogin> createState() => _PantallaloginState();
}

class _PantallaloginState extends State<Pantallalogin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyappbarLogin(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Color.fromARGB(255, 4, 15, 45)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_circle_outlined, // Un ícono de usuario elegante
                  size: 150, // Tamaño grande
                  color: Colors.white.withOpacity(
                    0.8,
                  ), // Blanco con transparencia sutil
                ),
                SizedBox(height: 10,),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.login, color: Colors.white),
                      hintText: "Ingrese su usuario",
                      hintStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.password,
                        color: Colors.white,
                      ),
                      hintText: "Ingrese su contraseña",
                      hintStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                        255,
                        1,
                        94,
                        243,
                      ), // Fondo azul
                      foregroundColor: Colors.white, // Color del texto
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                      ), // Espaciado interno
                      side: BorderSide(
                        color: Colors.black54,
                        width: 1.5,
                      ), // Borde
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          25,
                        ), // Esquinas redondeadas
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    onPressed: () {
                      print("Unirme a una sala presionado");
                    },
                    child: const Text("Iniciar sesion"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar MyappbarLogin() {
    return AppBar(
      centerTitle: true,
      backgroundColor: const Color.fromARGB(255, 1, 94, 243),
      title: const Row(
        mainAxisSize: MainAxisSize.min,
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