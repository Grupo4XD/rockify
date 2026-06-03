import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pruebas2_original/screens/pantallaSalaInvitado.dart';
 // <--- Importamos la pantalla que crearemos ahora

class PantallaUnirmeSala extends StatefulWidget {
  const PantallaUnirmeSala({super.key});

  @override
  State<PantallaUnirmeSala> createState() => _PantallaUnirmeSalaState();
}

class _PantallaUnirmeSalaState extends State<PantallaUnirmeSala> {
  // 1. El controlador para leer lo que escriben en la caja de texto
  final TextEditingController _codigoController = TextEditingController();
  bool _estaCargando = false; // Para mostrar una animación mientras busca en Firebase

  // 2. FUNCIÓN PRINCIPAL: VALIDA LA SALA EN FIREBASE
  Future<void> _validarYUnirmeASala() async {
    String codigoSala = _codigoController.text.trim();

    // Validación básica inicial
    if (codigoSala.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, ingresa un código de sala.")),
      );
      return;
    }

    setState(() {
      _estaCargando = true; // Activamos el spinner de carga
    });

    try {
      // 3. Hacemos la consulta directa a Firestore
      DocumentSnapshot docSala = await FirebaseFirestore.instance
          .collection('salas')
          .doc(codigoSala)
          .get();

      // 4. Verificamos si el documento existe de verdad en la nube
      if (docSala.exists) {
        // La sala es real. Extraemos los datos del documento
        final datosSala = docSala.data() as Map<String, dynamic>;
        String tokenCreador = datosSala['spotify_access_token'] ?? '';

        if (!mounted) return;

        // 5. ¡PASO MAESTRO! Redirigimos al invitado a su pantalla dedicada de la sala
        // Le pasamos el ID de la sala y el token del creador que acabamos de descargar
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Pantallasalainvitado(
              idSala: codigoSala,
              accessToken: tokenCreador,
            ),
          ),
        );
      } else {
        // Si el documento no existe en Firebase
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("La sala no existe. Verifica el código."),
          ),
        );
      }
    } catch (e) {
      print("Error al unirse a la sala: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de conexión con la base de datos.")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _estaCargando = false; // Apagamos el spinner de carga siempre al final
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Aquí mantienes exactamente tu diseño visual actual con tu Scaffold y Stack oscuro...
    // Solo debes asegurarte de conectar las variables en sus respectivos lugares:
    
    // Al TextField asígnale el controlador:
    // controller: _codigoController
    
    // Al botón de "Unirse" ponle la función en el onPressed (bloqueándolo si está cargando):
    // onPressed: _estaCargando ? null : _validarYUnirmeASala
    
    // Y si _estaCargando es true, puedes mostrar un CircularProgressIndicator() en lugar del texto del botón.
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF0D0E15),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Unirme a una Sala",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _codigoController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Código de sala (Ej: 5312)",
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF1E1F29),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF015EF3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _estaCargando ? null : _validarYUnirmeASala,
                  child: _estaCargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Ingresar a la Sala", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}