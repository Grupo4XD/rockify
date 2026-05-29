import 'package:flutter/material.dart';
import 'package:pruebas2_original/screens/pantallaSala.dart';
import 'package:webview_flutter/webview_flutter.dart'; // No te olvides de esta importación

class Pantallaspotifyweb extends StatefulWidget {
  const Pantallaspotifyweb({super.key});

  @override
  State<Pantallaspotifyweb> createState() => _PantallaspotifywebState();
}

class _PantallaspotifywebState extends State<Pantallaspotifyweb> {
  // 1. Declaramos la variable del controlador aquí arriba
  late final WebViewController _controller;

  // 2. Agregamos el initState ANTES del build
  @override
  void initState() {
    super.initState(); // Instancia base obligatoria de Flutter

    // Aquí adentro metes toda la configuración del controlador que te pasé hace un momento
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      //Escucha eventos del navegador
      ..setNavigationDelegate(
        NavigationDelegate(
          //El parametro request contiene toda la informacion a a la ue el usaurio intenta ir
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://macrobyte.site')) {
              //Agarramos la respuesta de la URL, convirtiendolo en un map
              Uri uri = Uri.parse(request.url);
              //Partimos en partes la URL y sacamos el valor code
              String? authCode = uri.queryParameters['code'];
              if (authCode != null) {
                //Context es la pantalla home en el que estabamos, y authCode devuelve el valor de authcode a esa pantalla
                // pushReplacement destruye la miniventana y monta la pantalla de la sala encima
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        Pantallasala(),
                  ),
                ); // Devuelve el código
              }
              //Es de la biblioteca de WebView, nos dice que no carge esa pagina en pantalla y que solo queriamos sus datos
              return NavigationDecision.prevent;
            }
            //Para que navege correctamente en spotify
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          'https://accounts.spotify.com/authorize?client_id=cf4410e8df834a21998c3fe4d6518987&response_type=code&redirect_uri=https://macrobyte.site&scope=user-modify-playback-state%20user-read-currently-playing%20user-read-playback-state%20user-read-private%20user-read-email',
        ),
      );
  }

  // 3. Tu método build original, pero ahora en vez de Placeholder devuelve la web
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        //Para cambiar el color del icono de regreso
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Aquí usamos el controlador que configuramos arriba una sola vez
      body: WebViewWidget(controller: _controller),
    );
  }
}
