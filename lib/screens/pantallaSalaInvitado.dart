import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class Pantallasalainvitado extends StatefulWidget {
  //Final sirve en tiempo de ejecución para decir que esa variable no va a cambiar, es como un "constante" pero que se asigna en tiempo de ejecución
  //Const sirve para decir que esa variable no va a cambiar y se asigna en tiempo de compilación, es decir, que su valor es fijo desde el momento en que escribimos el código
  final String idSala;
  final String accessToken;

  const Pantallasalainvitado({
    super.key,
    required this.idSala,
    required this.accessToken,
  });

  @override
  State<Pantallasalainvitado> createState() => _PantallasalainvitadoState();
}

class _PantallasalainvitadoState extends State<Pantallasalainvitado> {
  // Variables para la canción que suena AHORA en la fiesta
  String _tituloActual = "Cargando...";
  String _artistaActual = "Por favor espera";
  String _urlCaratulaActual = "https://picsum.photos/250";

  // Variables para el Buscador Flotante
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _resultadosBusqueda = [];
  bool _mostrarResultados = false;
  bool _estaBuscandoApi = false;

  // Lista local para pintar la cola real de Spotify
  List<dynamic> _colaReproduccion = [];

  @override
  void initState() {
    super.initState();
    // Ejecutamos las lecturas iniciales al entrar a la pantalla
    obtenerCancionActual();
    obtenerColaRealSpotify();

    // Configuramos el temporizador para que el invitado vea la música actualizarse cada 3 segundos
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
      } else {
        obtenerCancionActual();
        obtenerColaRealSpotify();
      }
    });
  }

  Future<void> obtenerCancionActual() async {
    // URL REAL DE SPOTIFY
    final Uri url = Uri.parse(
      'https://api.spotify.com/v1/me/player/currently-playing',
    );
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );
      if (response.statusCode == 200) {
        final datos = jsonDecode(response.body);
        if (datos['item'] != null && mounted) {
          setState(() {
            _tituloActual = datos['item']['name'];
            _artistaActual = datos['item']['artists'][0]['name'];
            _urlCaratulaActual = datos['item']['album']['images'][0]['url'];
          });
        }
      }
    } catch (e) {
      print("Error invitado GET actual: $e");
    }
  }

  Future<void> obtenerColaRealSpotify() async {
    // URL REAL DE SPOTIFY
    final Uri url = Uri.parse('https://api.spotify.com/v1/me/player/queue');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );
      if (response.statusCode == 200) {
        final datos = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _colaReproduccion = datos['queue'] ?? [];
          });
        }
      }
    } catch (e) {
      print("Error invitado GET queue: $e");
    }
  }

  Future<void> buscarCanciones(String query) async {
    if (query.isEmpty) {
      setState(() {
        _resultadosBusqueda = [];
        _mostrarResultados = false;
      });
      return;
    }
    setState(() {
      _estaBuscandoApi = true;
    });

    // URL REAL DE SPOTIFY PARA BÚSQUEDAS
    final Uri url = Uri.parse(
      'https://api.spotify.com/v1/search?q=$query&type=track&limit=10',
    );
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );
      if (response.statusCode == 200 && mounted) {
        final datos = jsonDecode(response.body);
        setState(() {
          _resultadosBusqueda = datos['tracks']['items'] ?? [];
          _mostrarResultados =
              true; // Activa la capa flotante para que se vea el ListView
        });
      }
    } catch (e) {
      print("Error buscador invitado: $e");
    } finally {
      if (mounted) {
        setState(() {
          _estaBuscandoApi = false;
        });
      }
    }
  }

  Future<void> anadirCancionAColaFirebase(
    Map<String, dynamic> cancionJson,
  ) async {
    String titulo = cancionJson['name'] ?? 'Sin título';
    String artista = cancionJson['artists'][0]['name'] ?? 'Artista';
    String trackUri = cancionJson['uri'] ?? '';
    String urlFoto = cancionJson['album']['images'].isNotEmpty
        ? cancionJson['album']['images'][2]['url']
        : 'https://picsum.photos/50';

    try {
      // Guardamos en la subcolección de la sala para que el creador la procese
      await FirebaseFirestore.instance
          .collection('salas')
          .doc(widget.idSala)
          .collection('cola')
          .add({
            'titulo': titulo,
            'artista': artista,
            'foto': urlFoto,
            'uri': trackUri,
            'timestamp': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      setState(() {
        _mostrarResultados = false;
        _searchController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text("¡'$titulo' enviada al DJ con éxito!"),
        ),
      );
    } catch (e) {
      print("Error invitado guardando en Firebase: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      body: Stack(
        children: [
          // ==========================================================
          // CAPA 1: EL CONTENIDO PRINCIPAL (Fondo, Reproductor e Historial)
          // ==========================================================
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                
                // Encabezado Estético (Sustituye al AppBar feo)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                    const SizedBox(width: 8),
                    Text(
                      "SALA EN VIVO  •  #${widget.idSala}".toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 65),

                // REPRODUCTOR PREMIUM (Muestra lo que suena en la fiesta)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    // Color de tarjeta oscuro pero diferente al fondo
                    color: const Color(0xFF1E1F29), 
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // Carátula de la canción con bordes redondeados perfectos
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          _urlCaratulaActual,
                          width: 220,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[800], 
                                width: 220, 
                                height: 220,
                                child: const Icon(Icons.music_note, size: 50, color: Colors.white24),
                              ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Textos de la canción centrados e identificables
                      Text(
                        _tituloActual,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _artistaActual,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),

                      // Barra verde estética de progreso (Simula que se está reproduciendo)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: const LinearProgressIndicator(
                            value: 0.4, // Valor estático estético
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)), // Verde Spotify
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Texto de rol para que el usuario entienda su interfaz
                      const Text(
                        "Escuchando en tiempo real con el DJ",
                        style: TextStyle(color: Colors.white24, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Sección inferior: Fila de reproducción
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Siguiente en la fila",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // LISTA DE REPRODUCCIÓN COMPARTIDA
                Expanded(
                  child: _colaReproduccion.isEmpty
                      ? const Center(
                          child: Text(
                            "La cola está vacía. ¡Añade un tema arriba!",
                            style: TextStyle(color: Colors.white38),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _colaReproduccion.length,
                          itemBuilder: (context, index) {
                            final cancionCola = _colaReproduccion[index];

                            String tituloCola = cancionCola['name'] ?? 'Sin título';
                            String artistaCola = 'Artista desconocido';
                            if (cancionCola['artists'] != null && cancionCola['artists'].isNotEmpty) {
                              artistaCola = cancionCola['artists'][0]['name'];
                            }

                            String urlFotoMini = 'https://picsum.photos/50';
                            if (cancionCola['album'] != null &&
                                cancionCola['album']['images'] != null &&
                                cancionCola['album']['images'].isNotEmpty) {
                              urlFotoMini = cancionCola['album']['images'][2]['url'];
                            }

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(urlFotoMini, width: 45, height: 45, fit: BoxFit.cover),
                              ),
                              title: Text(
                                tituloCola,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                artistaCola,
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // ==========================================================
          // CAPA 2: LOS RESULTADOS FLOTANTES DE LA BÚSQUEDA
          // ==========================================================
          if (_mostrarResultados)
            Positioned(
              top: 130, 
              left: 24,
              right: 24,
              bottom: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1F29),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [BoxShadow(color: Colors.black87, blurRadius: 20)],
                ),
                child: _estaBuscandoApi
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF015EF3)))
                    : _resultadosBusqueda.isEmpty
                        ? const Center(child: Text("No se encontraron canciones", style: TextStyle(color: Colors.white38)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _resultadosBusqueda.length,
                            itemBuilder: (context, index) {
                              final cancion = _resultadosBusqueda[index];
                              String titulo = cancion['name'] ?? 'Sin título';
                              String artista = cancion['artists'][0]['name'] ?? 'Artista';

                              String urlFoto = 'https://picsum.photos/50';
                              if (cancion['album']['images'].isNotEmpty) {
                                urlFoto = cancion['album']['images'][2]['url'];
                              }

                              return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(urlFoto, width: 40, height: 40, fit: BoxFit.cover),
                                ),
                                title: Text(
                                  titulo,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  artista,
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
                                  onPressed: () {
                                    anadirCancionAColaFirebase(cancion);
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ),

          // ==========================================================
          // CAPA 3: LA BARRA DE BÚSQUEDA FLOTANTE (FIJA ARRIBA)
          // ==========================================================
          Positioned(
            top: 55,
            left: 24,
            right: 24,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1F29),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  buscarCanciones(value);
                },
                decoration: InputDecoration(
                  hintText: "Buscar canción en Spotify...",
                  hintStyle: const TextStyle(color: Colors.white30),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _resultadosBusqueda = [];
                              _mostrarResultados = false;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
