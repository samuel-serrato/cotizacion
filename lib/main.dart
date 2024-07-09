import 'package:cotizacion/screens/calculos.dart';
import 'package:cotizacion/screens/cotizacion.dart';
//import 'package:cotizacion2/screens/home.dart';
import 'package:cotizacion/screens/formulario.dart';
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
