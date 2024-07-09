import 'package:cotizacion2/screens/calculos.dart';
import 'package:cotizacion2/screens/cotizacion.dart';
//import 'package:cotizacion2/screens/home.dart';
import 'package:cotizacion2/screens/formulario.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CotizacionProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => FormularioScreen(),
          '/cotizacion': (context) => CotizacionScreen(),
        },
      ),
    ),
  );
}
