import 'package:flutter/material.dart';
import 'package:pruebas2_original/screens/pantallaSpotifyWeb.dart';

class Pantallahome extends StatefulWidget {
  const Pantallahome({super.key});

  @override
  State<Pantallahome> createState() => _PantallahomeState();
}

class _PantallahomeState extends State<Pantallahome> {
  @override
  Widget build(BuildContext context) {
    // 1. Definimos un estilo único para AMBOS botones usando ElevatedButton.styleFrom
    // Al hacerlo aquí arriba como una variable, garantizamos que compartan el mismo fontSize, color y diseño.
    final estiloBotones = ElevatedButton.styleFrom(
      backgroundColor: Color.fromARGB(255, 1, 94, 243), // Efecto cristal traslúcido
      foregroundColor: Colors.white,                  // Color del texto
      padding: const EdgeInsets.symmetric(vertical: 20), // Espaciado interno arriba/abajo
      side: BorderSide(color: Colors.black54.withOpacity(1), width: 1.5), // Borde azul a juego
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25), // Esquinas redondeadas estilizadas
      ),
      textStyle: const TextStyle(
        fontSize: 18,               // El mismo tamaño de letra para ambos
        fontWeight: FontWeight.bold, // Letra gruesa y clara
        letterSpacing: 1.1,
      ),
    );

    // 2. Usamos Center para centrar horizontalmente y MainAxisAlignment.center para el centro vertical
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0), // Margen a los lados de la pantalla
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centra el contenido verticalmente
          children: [
            
            // BOTÓN 1: Crear sala
            SizedBox(
              width: double.infinity, 
              child: ElevatedButton(
                style: estiloBotones, // Le aplicamos nuestro estilo único
                onPressed: () async {
                  //El resultado  se gaurda en una variable
                  final String? codigo = await Navigator.push(
                  //El context tienen todos los widgets
                  context,
                  //El materialpageroute es un braper que simplifica la navegacion
                  MaterialPageRoute(
                    builder: (context) => Pantallaspotifyweb()
                  ),
                );
                print("El codigo de autenticacion es $codigo");

                },
                child: Text("Crear sala"),
              ),
            ),
            
            const SizedBox(height: 25), // Espacio de separación entre botones
            
            // BOTÓN 2: Unirme a una sala
            SizedBox(
              width: double.infinity, // También se estira al máximo, logrando el mismo ancho exacto
              child: ElevatedButton(
                style: estiloBotones, // Usa exactamente el mismo estilo
                onPressed: () {
                  print("Unirme a una sala presionado");
                },
                child: const Text("Unirme a una sala"),
              ),
            ),

          ],
        ),
      ),
    );
  }
}