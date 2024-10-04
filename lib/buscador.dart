import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Client Search'),
          backgroundColor: Colors.teal,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClientSearchField(),
          ),
        ),
      ),
    );
  }
}

class ClientSearchField extends StatefulWidget {
  @override
  _ClientSearchFieldState createState() => _ClientSearchFieldState();
}

class _ClientSearchFieldState extends State<ClientSearchField> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> filteredList =
      []; // Lista para almacenar los resultados de la API
  bool _showSuggestions = false; // Para controlar cuándo mostrar el menú
  Map<String, dynamic>?
      selectedClient; // Variable para almacenar el cliente seleccionado

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      // Solo realizar la búsqueda si hay más de 2 caracteres
      if (_controller.text.length > 2) {
        fetchClients(_controller.text);
      } else {
        setState(() {
          filteredList.clear(); // Limpiar si hay menos de 3 caracteres
          _showSuggestions =
              false; // No mostrar el menú si el texto es muy corto
          selectedClient = null; // Limpiar la selección actual
        });
      }
    });
  }

  Future<void> fetchClients(String query) async {
    final String url = 'http://192.168.0.109:3000/api/v1/clientes/$query';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> clients = json.decode(response.body);
        setState(() {
          filteredList = clients; // Almacenar los resultados
          _showSuggestions = true; // Mostrar el menú si hay resultados
        });
      } else {
        throw Exception('Failed to load clients');
      }
    } catch (e) {
      print('Error fetching clients: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Escribí el nombre o teléfono',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.teal),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.tealAccent),
            ),
            contentPadding:
                EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
          ),
        ),
        if (_showSuggestions &&
            filteredList.isNotEmpty) // Mostrar el menú solo si hay resultados
          Expanded(
            child: ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    final client = filteredList[index];
                    print("Elemento seleccionado: $client");

                    // Actualizar el valor del TextField y mostrar los detalles del cliente
                    setState(() {
                      _controller.text = client['nombres'] ?? "Sin nombre";
                      _showSuggestions = false; // Cerrar el menú al seleccionar
                      filteredList.clear(); // Limpiar la lista
                      selectedClient =
                          client; // Guardar el cliente seleccionado
                    });

                    // Verificar el valor seleccionado en la consola
                    print(
                        "Cliente seleccionado: ${client['nombres']}, Teléfono: ${client['telefono']}");
                  },
                  child: Card(
                    child: ListTile(
                      title: Text(filteredList[index]['nombres'] ??
                          "Nombre no disponible"),
                      subtitle: Text(
                          'Tel: ${filteredList[index]['telefono'] ?? "No disponible"}'),
                    ),
                  ),
                );
              },
            ),
          ),
        // Mostrar los detalles del cliente seleccionado
        if (selectedClient !=
            null) // Solo mostrar si hay un cliente seleccionado
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                border: Border.all(color: Colors.teal),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Detalles del Cliente:",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                  SizedBox(height: 10),
                  Text(
                      "Nombre: ${selectedClient!['nombres'] ?? "No disponible"}"),
                  Text(
                      "Teléfono: ${selectedClient!['telefono'] ?? "No disponible"}"),
                  Text("Email: ${selectedClient!['email'] ?? "No disponible"}"),
                  Text(
                      "Fecha de Registro: ${selectedClient!['fCreacion'] ?? "No disponible"}"),
                  // Añade aquí más campos según los datos del cliente
                ],
              ),
            ),
          ),
      ],
    );
  }
}
