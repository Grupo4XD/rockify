import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Text(
          "Bienvenido a la sala ${widget.idSala} con el token ${widget.accessToken}",
          style: TextStyle( fontSize: 18),
        ),
      ),
    );
  }
}
