import 'dart:convert';
import 'dart:math'; // Para generar el número de sala aleatorio
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart'; // Librería de Firebase Firestore
import 'dart:async'; // Para usar Timer

class PantallaSala extends StatefulWidget {
  final String codigoDeAutorizacion;
  const PantallaSala({super.key, required this.codigoDeAutorizacion});

  @override
  State<PantallaSala> createState() => _PantallaSalaState();
}

class _PantallaSalaState extends State<PantallaSala> {
  // 1. Variables de Control del Flujo Inicial (Canje y Firebase)
  bool _procesando = true;
  String? _errorMensaje;
  String? _idSala;
  String? _accessToken;

  // 2. Variables del Buscador de Canciones (Capa Flotante)
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _resultadosBusqueda = []; // LA LISTA ÚNICA DE RESULTADOS
  bool _buscandoCanciones =
      false; // Controla la ruedita de carga de la búsqueda
  bool _mostrarResultados =
      false; // Controla si se ve o se esconde la capa flotante

  // 3. Variables del Reproductor Central
  double _progresoCancion = 0.3; // Barra de progreso simulada
  List<dynamic> _colaReproduccion =
      []; // Las canciones que la gente ya añadió a la sala

  // Variables de la Canción Actual en el Reproductor
  String _tituloActual = "Ninguna canción sonando";
  String _artistaActual = "Abre Spotify en tu reproductor";
  String _urlCaratulaActual = "https://picsum.photos/250"; // Imagen por defecto
  bool _estaReproduciendo = false;

  @override
  void initState() {
    super.initState();
    // Iniciamos todo el flujo automático secuencial
    ejecutarFlujoInicial();
  }

  //#################### FUNCIONES ##############################
  // === FUNCIÓN PARA AÑADIR CANCIÓN A LA COLA REAL DE SPOTIFY ===
  Future<void> anadirCancionACola(String trackUri, String titulo) async {
    // Estructuramos la URL con el parámetro 'uri' obligatorio de Spotify
    print("ESTA ES TU URI: $trackUri");
    final Uri urlCola = Uri.parse(
      'https://api.spotify.com/v1/me/player/queue?uri=$trackUri',
    );

    try {
      print("HTTP POST: Añadiendo a la cola real -> $titulo");

      final response = await http.post(
        urlCola,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      // Spotify devuelve 204 No Content cuando la acción es exitosa
      if (response.statusCode == 204 || response.statusCode == 200) {
        print("¡Canción añadida con éxito a Spotify!");

        if (!mounted) return;

        // Cerramos la ventana flotante de búsqueda para volver al reproductor
        setState(() {
          _mostrarResultados = false;
          _searchController.clear();
        });

        // Mostramos el mensaje en pantalla de que se añadió con éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text("¡'$titulo' añadida a la cola con éxito!"),
            duration: const Duration(seconds: 2),
          ),
        );

        // Refrescamos el reproductor de inmediato para ver si cambió algo
        obtenerCancionActual();
        obtenerColaRealSpotify();
      } else {
        print("Error al añadir a la cola: ${response.body}");
        if (!mounted) return;
        // Si sale error, probablemente es porque Spotify no está abierto en segundo plano
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Asegúrate de tener Spotify abierto y sonando."),
          ),
        );
      }
    } catch (e) {
      print("Exception al añadir a la cola: $e");
    }
  }

  // === FUNCIÓN PARA OBTENER LA CANCIÓN QUE SUENA AHORA ===
  Future<void> obtenerCancionActual() async {
    if (_accessToken == null) return;

    final Uri urlActual = Uri.parse(
      'https://api.spotify.com/v1/me/player/currently-playing',
    );

    try {
      final response = await http.get(
        urlActual,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      // Si devuelve 204 significa que no hay nada reproduciéndose o Spotify está inactivo
      if (response.statusCode == 204) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> datosJson = jsonDecode(response.body);

        // Extraemos los datos del mapa de Spotify
        final item = datosJson['item'];
        if (item != null) {
          if (!mounted) return;
          setState(() {
            _tituloActual = item['name'] ?? 'Sin título';
            _artistaActual = item['artists'][0]['name'] ?? 'Artista';
            _urlCaratulaActual =
                item['album']['images'][0]['url'] ??
                'https://picsum.photos/250';
            _estaReproduciendo = datosJson['is_playing'] ?? false;

            // Calculamos el progreso para el slider (progreso_actual / duracion_total)
            int progresoMs = datosJson['progress_ms'] ?? 0;
            int duracionMs = item['duration_ms'] ?? 1;
            _progresoCancion = progresoMs / duracionMs;
          });
        }
      }
    } catch (e) {
      print("Error obteniendo canción actual: $e");
    }
  }

  // === FUNCIÓN INDEPENDIENTE: TRAE ÚNICAMENTE LA COLA DE REPRODUCCIÓN ===
  Future<void> obtenerColaRealSpotify() async {
    if (_accessToken == null) return;

    // Usamos el endpoint oficial de la cola de reproducción
    final Uri urlQueue = Uri.parse(
      'https://api.spotify.com/v1/me/player/queue',
    );

    try {
      final response = await http.get(
        urlQueue,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> datosJson = jsonDecode(response.body);

        // Extraemos la lista 'queue' del JSON
        final List<dynamic> colaSpotify = datosJson['queue'] ?? [];

        if (!mounted) return;

        setState(() {
          // Guardamos la cola real en tu variable sin tocar nada del reproductor
          _colaReproduccion = colaSpotify;
        });
      }
    } catch (e) {
      print("Error obteniendo la cola de Spotify: $e");
    }
  }

  // === FUNCIÓN PARA ENVIAR COMANDOS MULTIMEDIA (PLAY, PAUSE, NEXT) ===
  Future<void> enviarComandoMultimedia(String comando) async {
    // Si el comando es 'next', Spotify pide un POST. Si es 'play' o 'pause', pide un PUT.
    final String metodo = (comando == 'next') ? 'POST' : 'PUT';

    final Uri urlComando = Uri.parse(
      'https://api.spotify.com/v1/me/player/$comando',
    );

    try {
      print("Enviando comando: $comando");

      final response = await (metodo == 'POST'
          ? http.post(
              urlComando,
              headers: {'Authorization': 'Bearer $_accessToken'},
            )
          : http.put(
              urlComando,
              headers: {'Authorization': 'Bearer $_accessToken'},
            ));

      if (response.statusCode == 204 || response.statusCode == 200) {
        // Si la orden se envió bien, esperamos un momento y actualizamos la interfaz
        await Future.delayed(const Duration(milliseconds: 500));
        obtenerCancionActual();
      }
    } catch (e) {
      print("Error enviando comando multimedia: $e");
    }
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
        // Importante: Asegúrate de importar 'import 'dart:async';' arriba en tu archivo si no está.

        // Al final de tu función ejecutarFlujoInicial(), dentro del if (tokens != null), déjala así:

        print("¡SALA CREADA EN FIREBASE CON ÉXITO!: Sala $_idSala");

        // LANZAMOS EL TEMPORIZADOR EN TIEMPO REAL (Cada 3 segundos le pregunta a Spotify)
        Timer.periodic(const Duration(seconds: 3), (timer) {
          if (!mounted) {
            timer
                .cancel(); // Si el usuario sale de la sala, apaga el temporizador
          } else {
            obtenerCancionActual(); // Si sigue adentro, actualiza los datos
            obtenerColaRealSpotify();
          }
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

  // === FUNCIÓN PARA BUSCAR CANCIONES REALES EN SPOTIFY ===
  Future<void> buscarCancion(String textoABuscar) async {
    if (textoABuscar.isEmpty) return;

    setState(() {
      _mostrarResultados = true; // Abrimos la capa flotante de inmediato
      _buscandoCanciones =
          true; // Encendemos la ruedita de carga adentro de la capa
      _resultadosBusqueda =
          []; // Limpiamos los resultados de la búsqueda anterior
    });

    // Tu URL de búsqueda (Recuerda que para pruebas usamos esta temporal)
    final Uri urlBusqueda = Uri.https('api.spotify.com', '/v1/search', {
      'q': textoABuscar,
      'type': 'track',
      'limit': '10',
    });

    try {
      print("HTTP GET: Buscando '$textoABuscar' en Spotify...");

      final response = await http.get(
        urlBusqueda,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> datosJson = jsonDecode(response.body);
        final List<dynamic> cancionesEncontradas = datosJson['tracks']['items'];

        if (!mounted) return;

        setState(() {
          _resultadosBusqueda =
              cancionesEncontradas; // Guardamos las canciones reales encontradas
          _buscandoCanciones = false; // Apagamos la ruedita de carga
        });

        print(
          "¡Búsqueda éxitosa! Se encontraron ${_resultadosBusqueda.length} canciones.",
        );
      } else {
        print("Error en la búsqueda de Spotify: ${response.body}");
        if (!mounted) return;
        setState(() => _buscandoCanciones = false);
      }
    } catch (e) {
      print("Exception en buscador: $e");
      if (!mounted) return;
      setState(() => _buscandoCanciones = false);
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
        automaticallyImplyLeading:
            false, // Quita la flecha de atrás automática para evitar congelamientos por error
        title: Text(
          "Sala: $_idSala",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF015EF3),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () {
              Navigator.pop(context); // Regresa a la pantalla anterior (login)
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ==========================================
          // CAPA 1: EL CONTENIDO PRINCIPAL (Siempre visible al fondo)
          // ==========================================
          Column(
            children: [
              // Espacio reservado para que la barra de búsqueda de arriba no tape el reproductor
              const SizedBox(height: 85),

              // REPRODUCTOR CENTRAL (Al Medio)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25.0,
                  vertical: 10,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          _urlCaratulaActual, // <--- CARÁTULA REAL EN TIEMPO REAL
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        _tituloActual, // <--- TÍTULO REAL
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _artistaActual, // <--- ARTISTA REAL
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Slider(
                        value: _progresoCancion, // <--- PROGRESO EN TIEMPO REAL
                        activeColor: const Color(0xFF1DB954),
                        inactiveColor: Colors.white24,
                        onChanged:
                            (
                              value,
                            ) {}, // Lo dejamos vacío para que solo sea informativo por ahora
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.skip_previous,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () => print("Anterior (Opcional)"),
                          ),
                          IconButton(
                            // Cambia el icono dinámicamente si está reproduciendo o pausado
                            icon: Icon(
                              _estaReproduciendo
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: Colors.white,
                              size: 45,
                            ),
                            onPressed: () {
                              // Si está sonando, mandamos a pausar. Si está pausado, mandamos a reproducir
                              if (_estaReproduciendo) {
                                enviarComandoMultimedia('pause');
                              } else {
                                enviarComandoMultimedia('play');
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_next,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () => enviarComandoMultimedia(
                              'next',
                            ), // <--- SALTAR CANCIÓN
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
              const Text(
                "COLA DE REPRODUCCIÓN DE LA SALA",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),

              // LISTA REAL DE LA COLA (Abajo)
              // LISTA REAL DE LA COLA (Abajo de la pantalla)
              Expanded(
                child: _colaReproduccion.isEmpty
                    ? const Center(
                        child: Text(
                          "La cola está vacía. ¡Añade canciones!",
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _colaReproduccion.length,
                        itemBuilder: (context, index) {
                          final cancionCola = _colaReproduccion[index];

                          // Mapeo seguro directo desde el JSON de Spotify
                          String tituloCola =
                              cancionCola['name'] ?? 'Sin título';
                          String artistaCola =
                              cancionCola['artists'][0]['name'] ??
                              'Artista desconocido';

                          // Extrae la imagen pequeña del álbum si viene en los datos
                          String urlFotoMini = 'https://picsum.photos/50';
                          if (cancionCola['album'] != null &&
                              cancionCola['album']['images'].isNotEmpty) {
                            urlFotoMini =
                                cancionCola['album']['images'][2]['url'];
                          }

                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Image.network(
                                urlFotoMini,
                                width: 35,
                                height: 35,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              tituloCola,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              artistaCola,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // ==========================================
          // CAPA 2: LOS RESULTADOS DE BÚSQUEDA (Flota encima de la Capa 1)
          // ==========================================
          if (_mostrarResultados)
            Positioned(
              top: 75, // Se dibuja justo debajo de la barra de búsqueda
              left: 15,
              right: 15,
              bottom:
                  20, // Llega casi hasta el final de la pantalla tapando el fondo
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF121831,
                  ), // Color sólido oscuro para tapar el reproductor
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    // Cabecera de la ventana flotante con botón de cerrar
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Resultados de la búsqueda",
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _mostrarResultados =
                                    false; // Ocultamos la capa flotante
                                _searchController
                                    .clear(); // Limpiamos el texto escrito
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),

                    // Lista de resultados de Spotify adentro del contenedor flotante
                    Expanded(
                      child: _buscandoCanciones
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF015EF3),
                              ),
                            )
                          : _resultadosBusqueda.isEmpty
                          ? const Center(
                              child: Text(
                                "No se encontraron canciones.",
                                style: TextStyle(color: Colors.white38),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _resultadosBusqueda.length,
                              itemBuilder: (context, index) {
                                final cancion = _resultadosBusqueda[index];
                                String titulo = cancion['name'] ?? 'Sin título';
                                String artista =
                                    cancion['artists'][0]['name'] ?? 'Artista';
                                String urlFoto =
                                    cancion['album']['images'].isNotEmpty
                                    ? cancion['album']['images'][2]['url']
                                    : 'https://picsum.photos/50';

                                return ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: Image.network(
                                      urlFoto,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text(
                                    titulo,
                                    style: const TextStyle(color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    artista,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.greenAccent,
                                    ),
                                    onPressed: () {
                                      anadirCancionACola(
                                        cancion['uri'],
                                        titulo,
                                      );
                                      // El siguiente paso será enlazar esto a la API de agregar a la cola
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

          // ==========================================
          // CAPA 3: LA BARRA DE BÚSQUEDA (Siempre al frente de todo, arriba)
          // ==========================================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
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
                        buscarCancion(_searchController.text);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} // <--- FIN DE LA CLASE STATE (Asegúrate de dejar una sola llave de cierre al final)
