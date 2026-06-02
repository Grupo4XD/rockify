import 'package:flutter/material.dart';

class PantallaUnirmeSala extends StatefulWidget {
  const PantallaUnirmeSala({super.key});

  @override
  State<PantallaUnirmeSala> createState() => _PantallaUnirmeSalaState();
}

class _PantallaUnirmeSalaState extends State<PantallaUnirmeSala> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white), // Asegura que el ícono de retroceso sea visible
        title: const Text("Unirme a una sala",style: TextStyle(color: Colors.white),),
        backgroundColor: Color.fromARGB(255, 1, 94, 243),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Color.fromARGB(255, 4, 15, 45)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Ingresa el codigo de la sala a la que deseas unirte",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 20),
                TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Codigo de la sala",
                    hintStyle: TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.white, width: 3),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: Text("Unirme a la sala"),
                  style: ElevatedButton.styleFrom( //Su pongo ButtonStyle porque no me reconoce el estilo que hice
                    backgroundColor: Color.fromARGB(255, 1, 94, 243),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: (){
                    
                  }
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}