import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class Pantallasala extends StatefulWidget {
  //Guardamos el codigo de autorizacion que nos mandamos
  final String? codigo;
  const Pantallasala({super.key, this.codigo});

  @override
  State<Pantallasala> createState() => _PantallasalaState();
}

class _PantallasalaState extends State<Pantallasala> {
  // Variables para controlar el estado de la petición en la pantalla
  bool _cargando = true;
  String? _errorMensaje;
  String? _accessTokenObtenido;

  @override
  void initState() {
    super.initState();
    // En cuanto se crea la pantalla, ejecutamos automáticamente el canje del token
    canjearCodigoPorToken();
  }

  // === LA FUNCIÓN QUE HACE EL TRABAJO DE POSTMAN ===
  Future<void> canjearCodigoPorToken() async {
    final String urlSpotify = 'https://accounts.spotify.com/api/token';

    // Coloca aquí las credenciales exactas de tu docente
    final String clientId = 'cf4410e8df834a21998c3fe4d6518987';
    final String clientSecret = 'eb34c8686e6044b9b6a2fcc6b37e9bb1';
    final String redirectUri = 'https://macrobyte.site';

    try {
      print("HTTP: Iniciando petición POST hacia Spotify...");

      // Hacemos el HTTP POST idéntico a tu Postman
      final response = await http.post(
        Uri.parse(urlSpotify),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': widget.codigo, // Usamos el código que llegó por la ventana
          'redirect_uri': redirectUri,
          'client_id': clientId,
          'client_secret': clientSecret,
        },
      );

      // Evaluamos la respuesta de Spotify (200 significa éxito)
      if (response.statusCode == 200) {
        // Convertimos el texto JSON que nos devolvió Spotify a un Mapa de Dart
        final Map<String, dynamic> datosJson = jsonDecode(response.body);

        setState(() {
          _accessTokenObtenido = datosJson['access_token'];
          _cargando = false;
        });

        print("================ RESPUESTA EXITOSA DE SPOTIFY ================");
        print("¡Token obtenido desde Flutter con éxito!");
        print("Access Token: $_accessTokenObtenido");
        print("Refresh Token: ${datosJson['refresh_token']}");
        print("==============================================================");
      } else {
        // Si dio 400, 401, 403, etc.
        final Map<String, dynamic> errorJson = jsonDecode(response.body);
        setState(() {
          _errorMensaje =
              "Error de Spotify: ${errorJson['error_description'] ?? 'Petición inválida'}";
          _cargando = false;
        });
        print("Error en el canje: ${response.body}");
      }
    } catch (e) {
      // Por si se corta el internet o la URL está mal escrita
      setState(() {
        _errorMensaje =
            "Error de conexión: No se pudo conectar con el servidor.";
        _cargando = false;
      });
      print("Exception capturada: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sala de Música"),
        backgroundColor: const Color(0xFF015EF3),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      // Evaluamos con condicionales qué widget pintar en medio de la pantalla
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _cargando
              ? const CircularProgressIndicator() // Muestra la ruedita si está cargando
              : _errorMensaje != null
              ? Text(
                  _errorMensaje!, // Muestra el error al medio en rojo si falló
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 80,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "¡Token Canjeado con Éxito!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Token: ${_accessTokenObtenido!.substring(0, 20)}...", // Muestra solo el inicio para no saturar
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
