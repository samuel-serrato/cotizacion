import 'package:cotizacion/navigation_rail.dart';
import 'package:cotizacion/screens/calculos.dart';
import 'package:cotizacion/screens/generarPDF.dart';
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
          '/': (context) => NavigationRailScreen(),
          //'/cotizacion': (context) => CotizacionScreen(mostrarIVA: true,),
        },
      ),
    ),
  );
}
