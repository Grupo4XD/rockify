import 'dart:convert';
import 'dart:math'; // Para generar el número de sala aleatorio
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart'; // Librería de Firebase Firestore

class PantallaSala extends StatefulWidget {
  final String codigoDeAutorizacion;

  const PantallaSala({super.key, required this.codigoDeAutorizacion});

  @override
  State<PantallaSala> createState() => _PantallaSalaState();
}

class _PantallaSalaState extends State<PantallaSala> {
  // Variables de Control de Estado
  bool _procesando = true;
  String? _errorMensaje;

  // Datos de la Sala creados en Firebase
  String? _idSala;
  String? _accessToken;

  // Controladores para la Interfaz Gráfica
  final TextEditingController _searchController = TextEditingController();
  double _progresoCancion = 0.3; // Simulación: barra al 30%

  @override
  void initState() {
    super.initState();
    // Iniciamos todo el flujo automático secuencial
    ejecutarFlujoInicial();
  }

  // Flujo ordenado: Canjea Token -> Genera Sala -> Sube a Firebase
  Future<void> ejecutarFlujoInicial() async {
    try {
      Map<String, dynamic>? tokens = await canjearCodigoPorToken();

      // --- ESTA ES LA CLAVE ---
      // Si el usuario presionó 'atrás' mientras esperaba el token,
      // la pantalla ya no está 'montada' y debemos detener la ejecución.
      if (!mounted) return;

      if (tokens != null) {
        _accessToken = tokens['access_token'];
        String refreshToken = tokens['refresh_token'];
        String salaAleatoria = (1000 + Random().nextInt(9000)).toString();

        await FirebaseFirestore.instance
            .collection('salas')
            .doc(salaAleatoria)
            .set({
              'codigo_sala': salaAleatoria,
              'spotify_access_token': _accessToken,
              'spotify_refresh_token': refreshToken,
              'creado_en': FieldValue.serverTimestamp(),
            });

        // --- SEGUNDO CHECK ---
        if (!mounted) return;

        setState(() {
          _idSala = salaAleatoria;
          _procesando = false;
        });
      }
    } catch (e) {
      if (!mounted)
        return; // Evita el crash al intentar mostrar un error en una pantalla cerrada
      setState(() {
        _errorMensaje = "Error: $e";
        _procesando = false;
      });
    }
  }

  // Petición HTTP POST idéntica a tu Postman
  Future<Map<String, dynamic>?> canjearCodigoPorToken() async {
    final String urlSpotify = 'https://accounts.spotify.com/api/token';
    final String clientId = 'cf4410e8df834a21998c3fe4d6518987';
    final String clientSecret = 'eb34c8686e6044b9b6a2fcc6b37e9bb1';
    final String redirectUri = 'https://macrobyte.site';

    final response = await http.post(
      Uri.parse(urlSpotify),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': widget.codigoDeAutorizacion,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'client_secret': clientSecret,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      setState(() {
        _errorMensaje = "Spotify rechazó las credenciales. Revisa el código.";
        _procesando = false;
      });
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si está cargando o procesando Firebase, muestra pantalla de espera
    if (_procesando) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 20),
              Text(
                "Configurando Sala y Vinculando Base de Datos...",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Si falló algo en el camino, muestra el error centrado
    if (_errorMensaje != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        body: Center(
          child: Text(
            _errorMensaje!,
            style: const TextStyle(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // INTERFAZ DE LA SALA MULTIMEDIA COMPLETA (ÉXITO)
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21), // Fondo oscuro elegante
      appBar: AppBar(
        title: Text(
          "Sala: $_idSala",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: const Color(0xFF015EF3),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. BARRA DE BÚSQUEDA (Arriba)
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Buscar canción en Spotify...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF015EF3),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {
                      print("Buscando en Spotify: ${_searchController.text}");
                      // TODO: Aquí dispararemos el GET de búsqueda usando el _accessToken
                    },
                  ),
                ),
              ],
            ),
          ),

          // 2. REPRODUCTOR CENTRAL (Al Medio)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  // Imagen de la canción (Por ahora una estática de prueba)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      'https://picsum.photos/250', // Imagen aleatoria temporal
                      height: 180,
                      width: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Canción de Prueba",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Artista Desconocido",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),

                  // Barra de progreso interactiva (Slider)
                  Slider(
                    value: _progresoCancion,
                    activeColor: const Color(0xFF1DB954), // Verde Spotify
                    inactiveColor: Colors.white24,
                    onChanged: (value) {
                      setState(() {
                        _progresoCancion = value;
                      });
                    },
                  ),

                  // Controles Multimedia
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.skip_previous,
                          color: Colors.white,
                          size: 36,
                        ),
                        onPressed: () => print("Anterior"),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(
                          Icons.play_circle_filled,
                          color: Colors.white,
                          size: 56,
                        ),
                        onPressed: () => print("Play / Pause"),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(
                          Icons.skip_next,
                          color: Colors.white,
                          size: 36,
                        ),
                        onPressed: () => print("Siguiente"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
          const Text(
            "COLA DE REPRODUCCIÓN",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),

          // 3. LISTA DE REPRODUCCIÓN / COLA (Abajo)
          Expanded(
            child: ListView.builder(
              itemCount: 5, // Simulación: 5 canciones fijas por ahora
              itemBuilder: (context, index) {
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.network(
                      'https://picsum.photos/50',
                      width: 40,
                      height: 40,
                    ),
                  ),
                  title: Text(
                    "Canción en Cola $index",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "Artista Ejemplo $index",
                    style: const TextStyle(color: Colors.white60),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () {
                      print("Eliminar canción índice $index");
                      // Lógica de borrado futuro para el creador
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
