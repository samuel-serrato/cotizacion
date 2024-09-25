import 'package:flutter/material.dart';
import 'screens/control.dart';
import 'screens/formulario.dart';

class NavigationRailScreen extends StatefulWidget {
  @override
  _NavigationRailScreenState createState() => _NavigationRailScreenState();
}

class _NavigationRailScreenState extends State<NavigationRailScreen> {
  int _selectedIndex = 0;
  
  // Crear un GlobalKey para cada pantalla
  final GlobalKey<ControlScreenState> _controlKey = GlobalKey<ControlScreenState>();

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;

      // Llamar al método de carga de datos según la pantalla seleccionada
      if (_selectedIndex == 0) {
       
      } else if (_selectedIndex == 1) {
        _controlKey.currentState?.fetchDetallesYArticulos(); // Método en ControlScreen
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationRail(
            backgroundColor: Colors.white,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
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
                FormularioScreen(),
                ControlScreen(key: _controlKey),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
