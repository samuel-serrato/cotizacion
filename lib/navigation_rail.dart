import 'package:cotizacion/screens/control.dart';
import 'package:flutter/material.dart';

import 'screens/formulario.dart';
import 'screens/generarPDF.dart';

class NavigationRailScreen extends StatefulWidget {
  @override
  _NavigationRailScreenState createState() => _NavigationRailScreenState();
}

class _NavigationRailScreenState extends State<NavigationRailScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationRail(
            backgroundColor: Colors.white,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.selected,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.format_list_bulleted),
                selectedIcon: Icon(Icons.format_list_bulleted_outlined),
                label: Text('Formulario'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Control'),
              ),
            ],
          ),
          VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                FormularioNavigator(),
                ControlScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FormularioNavigator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (RouteSettings settings) {
        WidgetBuilder builder;
        switch (settings.name) {
          case '/':
            builder = (BuildContext _) => FormularioScreen();
            break;
        /*   case '/cotizacion':
            builder = (BuildContext _) => CotizacionScreen(mostrarIVA: true,);
            break; */
          default:
            throw Exception('Invalid route: ${settings.name}');
        }
        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}

class CotizacionNavigator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (RouteSettings settings) {
        WidgetBuilder builder;
        switch (settings.name) {
         /*  case '/':
            builder = (BuildContext _) => CotizacionScreen(mostrarIVA: true,);
            break; */
          case '/control':
            builder = (BuildContext _) => ControlScreen();
            break;
          default:
            throw Exception('Invalid route: ${settings.name}');
        }
        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}