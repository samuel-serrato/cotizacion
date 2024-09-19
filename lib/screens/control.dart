import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ControlScreen extends StatefulWidget {
  @override
  _ControlScreenState createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen>
    with TickerProviderStateMixin {
  List<dynamic> clientes = [];
  List<dynamic> detalles = [];
  List<dynamic> articulos = [];
  Map<String, bool> _expandedState =
      {}; // Mapa para rastrear el estado expandido de cada folio
  Map<String, AnimationController> _controllers =
      {}; // Mapa para AnimationControllers

  @override
  void initState() {
    super.initState();
    fetchClientesYDetallesYArticulos();
  }

  Future<void> fetchClientesYDetallesYArticulos() async {
    try {
      final clientesResponse = await http
          .get(Uri.parse('http://192.168.1.26:3000/api/v1/clientes'));
      final detallesResponse = await http
          .get(Uri.parse('http://192.168.1.26:3000/api/v1/detalles/'));
      final articulosResponse = await http
          .get(Uri.parse('http://192.168.1.26:3000/api/v1/articulos'));

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

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Fecha desconocida';
    }
    try {
      final date = DateTime.parse(dateString);
      final DateFormat formatter =
          DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES');
      return formatter.format(date);
    } catch (e) {
      return dateString; // Retorna el valor original si hay un error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 27, 69),
        title: Text(
          'Control de Clientes y Ventas',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: clientes.isEmpty || detalles.isEmpty || articulos.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: clientes.length,
              itemBuilder: (context, clienteIndex) {
                final cliente = clientes[clienteIndex];

                // Filtrar los detalles que pertenecen al cliente actual
                final detallesDelCliente = detalles.where((detalle) {
                  return detalle['cliente'] == cliente['nombres'];
                }).toList();

                return Column(
                  children: detallesDelCliente.map((detalle) {
                    final folio = detalle['folio'] ?? 'desconocido';
                    final isExpanded = _expandedState[folio] ?? false;

                    // Crear o actualizar el AnimationController para el folio
                    if (!_controllers.containsKey(folio)) {
                      _controllers[folio] = AnimationController(
                        vsync: this,
                        duration: Duration(milliseconds: 300),
                      );
                    }

                    final controller = _controllers[folio]!;
                    final animation = Tween<double>(begin: 0.0, end: 1.0)
                        .animate(CurvedAnimation(
                      parent: controller,
                      curve: Curves.easeInOut,
                    ));

                    // Iniciar o detener la animación según el estado expandido
                    if (isExpanded) {
                      if (controller.status == AnimationStatus.dismissed) {
                        controller.forward();
                      }
                    } else {
                      if (controller.status == AnimationStatus.completed) {
                        controller.reverse();
                      }
                    }

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      elevation: 4,
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.all(16),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${cliente['nombres'] ?? 'Cliente desconocido'} - ${detalle['nombre_venta'] ?? 'Venta sin nombre'}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${formatDate(detalle['fecha'] as String?)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Folio: $folio',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                /* Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Subtotal:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '\$${detalle['subtotal'] ?? '0.00'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'IVA:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '\$${detalle['iva'] ?? '0.00'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '\$${detalle['total'] ?? '0.00'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ), */
                              ],
                            ),
                            trailing: Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                            ),
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedState.remove(folio);
                                } else {
                                  _expandedState.forEach((key, value) {
                                    if (value) {
                                      _expandedState[key] = false;
                                    }
                                  });
                                  _expandedState[folio] = true;
                                }
                              });
                            },
                          ),
                          SizeTransition(
                            sizeFactor: animation,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              color: Colors.white,
                              child: isExpanded
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Teléfono: ${cliente['telefono'] ?? 'No disponible'}'),
                                        SizedBox(height: 16),
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
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      vertical: 2,
                                                      horizontal: 16.0),
                                              title: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                      child: Text(
                                                    'Cantidad: ${articuloDetalle['cantidad'] ?? '0'}',
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  )),
                                                  Expanded(
                                                      child: Text(
                                                    'Producto: ${articulo != null ? articulo['descripcion'] ?? 'Desconocido' : 'Desconocido'}',
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  )),
                                                  Expanded(
                                                      child: Text(
                                                    'Compra: \$${articuloDetalle['precio_compra'] ?? '0.00'}',
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  )),
                                                  Expanded(
                                                      child: Text(
                                                    'Venta: \$${articuloDetalle['precio_venta'] ?? '0.00'}',
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  )),
                                                  Expanded(
                                                      child: Text(
                                                    'Ganancia: \$${articuloDetalle['ganancia'] ?? '0.00'}',
                                                    style:
                                                        TextStyle(fontSize: 16),
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
                                                '\$${detalle['subtotal'] ?? '0.00'}',
                                                style: TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 16),
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
                                                '\$${detalle['iva'] ?? '0.00'}',
                                                style: TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 16),
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
                                                '\$${detalle['total'] ?? '0.00'}',
                                                style: TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    // Limpiar los AnimationControllers al cerrar el widget
    _controllers.values.forEach((controller) {
      controller.dispose();
    });
    super.dispose();
  }
}
