import 'package:cotizacion/navigation_rail.dart';
import 'package:cotizacion/screens/calculos.dart';
import 'package:cotizacion/generarPDF.dart';
import 'package:cotizacion/screens/formulario.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CotizacionProvider(),
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true, // Habilita Material 3
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 0, 255, 225),
          ),
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => NavigationScreen(),
          //'/cotizacion': (context) => CotizacionScreen(mostrarIVA: true,),
        },
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('es', 'ES'), // Español
        ],
      ),
    ),
  );
}
