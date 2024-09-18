import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ControlScreen extends StatefulWidget {
  @override
  _ControlScreenState createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  List<dynamic> clientes = [];
  List<dynamic> detalles = [];
  List<dynamic> articulos = [];

  @override
  void initState() {
    super.initState();
    fetchClientesYDetallesYArticulos();
  }

  Future<void> fetchClientesYDetallesYArticulos() async {
    try {
      final clientesResponse = await http
          .get(Uri.parse('http://192.168.0.109:3000/api/v1/clientes'));
      final detallesResponse = await http
          .get(Uri.parse('http://192.168.0.109:3000/api/v1/detalles/'));
      final articulosResponse = await http
          .get(Uri.parse('http://192.168.0.109:3000/api/v1/articulos'));

      if (clientesResponse.statusCode == 200 &&
          detallesResponse.statusCode == 200 &&
          articulosResponse.statusCode == 200) {
        setState(() {
          clientes = json.decode(clientesResponse.body);
          detalles = json.decode(detallesResponse.body);
          articulos = json.decode(articulosResponse.body);
        });
      } else {
        throw Exception('Error al obtener los datos');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final DateFormat formatter =
          DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES');
      return formatter.format(date);
    } catch (e) {
      return dateString; // Retorna el valor original si hay un error en el formato
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(
            255, 0, 27, 69), // Color personalizado para la AppBar
        title: Text(
          'Control de Clientes y Ventas',
          style: TextStyle(color: Colors.white), // Color del texto de la AppBar
        ),
      ),
      body: clientes.isEmpty || detalles.isEmpty || articulos.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: clientes.length,
              itemBuilder: (context, index) {
                final cliente = clientes[index];

                // Filtrar los detalles que pertenecen al cliente actual
                final detallesDelCliente = detalles.where((detalle) {
                  return detalle['cliente'] == cliente['nombres'];
                }).toList();

                return Card(
                  color: Colors.white, // Color de fondo de la tarjeta
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  elevation: 4,
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.all(16.0),
                    title: Text(
                      cliente['nombres'] ?? '',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87, // Color del texto del título
                      ),
                    ),
                    subtitle: Text(
                      'Teléfono: ${cliente['telefono'] ?? ''}',
                      style: TextStyle(
                          color:
                              Colors.black54), // Color del texto del subtítulo
                    ),
                    trailing: Text(
                      'Fecha: ${formatDate(cliente['fCreacion'] ?? '')}',
                      style: TextStyle(
                          color:
                              Colors.black54), // Color del texto del trailing
                    ),
                    children: [
                      detallesDelCliente.isEmpty
                          ? ListTile(
                              title: Text(
                                'Sin detalles de ventas',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors
                                      .black54, // Color del texto cuando no hay detalles
                                ),
                              ),
                              tileColor: Colors.grey[
                                  200], // Color de fondo cuando no hay detalles
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: detallesDelCliente.map((detalle) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        'Folio: ${detalle['folio']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors
                                              .blue, // Color del texto del Folio
                                        ),
                                      ),
                                    ),
                                    ...detalle['articulos']
                                        .map<Widget>((articuloDetalle) {
                                      final articulo = articulos.firstWhere(
                                        (articulo) =>
                                            articulo['idarticulo'] ==
                                            articuloDetalle['idarticulo'],
                                        orElse: () => null,
                                      );

                                      return Card(
                                        color: const Color.fromARGB(
                                            255, 243, 243, 243),
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 4.0, horizontal: 8.0),
                                        elevation: 2,
                                        child: ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 2, horizontal: 16.0),
                                          /* leading: Icon(Icons.shopping_cart,
                                              color: Colors
                                                  .blue), // Color del ícono */
                                          title: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                  child: Text(
                                                'Cantidad: ${articuloDetalle['cantidad']}',
                                                style: TextStyle(fontSize: 16),
                                              )),
                                              Expanded(
                                                  child: Text(
                                                'Producto: ${articulo != null ? articulo['descripcion'] : 'Desconocido'}',
                                                style: TextStyle(fontSize: 16),
                                              )),
                                              Expanded(
                                                  child: Text(
                                                'Compra: \$${articuloDetalle['precio_compra']}',
                                                style: TextStyle(fontSize: 16),
                                              )),
                                              Expanded(
                                                  child: Text(
                                                'Venta: \$${articuloDetalle['precio_venta']}',
                                                style: TextStyle(fontSize: 16),
                                              )),
                                              Expanded(
                                                  child: Text(
                                                'Ganancia: \$${articuloDetalle['ganancia']}',
                                                style: TextStyle(fontSize: 16),
                                              )),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0, horizontal: 16.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Subtotal:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          Text(
                                            '\$${detalle['subtotal']}',
                                            style: TextStyle(
                                                color: Colors.black87,
                                                fontSize:
                                                    16), // Color del texto del subtotal
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0, horizontal: 16.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'IVA:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          Text(
                                            '\$${detalle['iva']}',
                                            style: TextStyle(
                                                color: Colors.black87,
                                                fontSize:
                                                    16), // Color del texto del IVA
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0, horizontal: 16.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          Text(
                                            '\$${detalle['total']}',
                                            style: TextStyle(
                                                color: Colors.black87,
                                                fontSize:
                                                    16), // Color del texto del total
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
