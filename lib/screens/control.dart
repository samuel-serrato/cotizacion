import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ControlScreen extends StatefulWidget {
  @override
  _ControlScreenState createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  List<dynamic> clientes = [];
  List<dynamic> productos = [];

  @override
  void initState() {
    super.initState();
    fetchClientesYProductos();
  }

  Future<void> fetchClientesYProductos() async {
    try {
      final clientesResponse = await http
          .get(Uri.parse('http://192.168.0.109:3000/api/v1/clientes'));
      final productosResponse = await http
          .get(Uri.parse('http://192.168.0.109:3000/api/v1/productos'));

      if (clientesResponse.statusCode == 200 &&
          productosResponse.statusCode == 200) {
        setState(() {
          clientes = json.decode(clientesResponse.body);
          productos = json.decode(productosResponse.body);
        });
      } else {
        throw Exception('Error al obtener los datos');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Control de Clientes y Productos'),
      ),
      body: clientes.isEmpty || productos.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID Cliente')),
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Teléfono')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Fecha de Creación')),
                  DataColumn(label: Text('Producto Comprado')),
                  DataColumn(label: Text('Precio de Compra')),
                  DataColumn(label: Text('Fecha de Compra')),
                ],
                rows: clientes.map((cliente) {
                  // Filtrar los productos que pertenecen al cliente actual
                  final productosDelCliente = productos.where((producto) {
                    // Aquí deberías tener una lógica para relacionar productos con clientes
                    // Por ejemplo, comparando el 'idcliente' con el 'idcliente' en productos
                    // Suponiendo que hay una relación clara (modifica según tu necesidad)
                    return producto['idcliente'] == cliente['idcliente'];
                  }).toList();

                  if (productosDelCliente.isEmpty) {
                    return DataRow(cells: [
                      DataCell(Text(cliente['idcliente'] ?? '')),
                      DataCell(Text(cliente['nombres'] ?? '')),
                      DataCell(Text(cliente['telefono'] ?? '')),
                      DataCell(Text(cliente['email'] ?? '')),
                      DataCell(Text(cliente['fCreacion'] ?? '')),
                      DataCell(Text('Sin productos')),
                      DataCell(Text('-')),
                      DataCell(Text('-')),
                    ]);
                  } else {
                    return DataRow(cells: [
                      DataCell(Text(cliente['idcliente'] ?? '')),
                      DataCell(Text(cliente['nombres'] ?? '')),
                      DataCell(Text(cliente['telefono'] ?? '')),
                      DataCell(Text(cliente['email'] ?? '')),
                      DataCell(Text(cliente['fCreacion'] ?? '')),
                      DataCell(Text(productosDelCliente[0]['producto'] ?? '')),
                      DataCell(Text(
                          productosDelCliente[0]['precio_compra'].toString())),
                      DataCell(Text(productosDelCliente[0]['fCreacion'] ?? '')),
                    ]);
                  }
                }).toList(),
              ),
            ),
    );
  }
}
