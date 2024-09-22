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
  Map<String, String?> _estadoPorFolio = {};

  String? estadoActual;

  @override
  void initState() {
    super.initState();
    fetchClientesYDetallesYArticulos();
  }

  Future<void> fetchClientesYDetallesYArticulos() async {
    try {
      final clientesResponse =
          await http.get(Uri.parse('http://192.168.1.26:3000/api/v1/clientes'));
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
        throw Exception('Error al obtener los datos');
      } else {}
    } catch (e) {
      print('Error: $e');
    }
  }

  String? obtenerEstadoActual(Map<String, dynamic> detalle) {
    if (detalle['estado_actual'] != null &&
        detalle['estado_actual'] is List &&
        detalle['estado_actual'].isNotEmpty) {
      return detalle['estado_actual'][0]['estado'];
    }
    return 'Desconocido';
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

  String formatDateWithTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Fecha desconocida';
    }
    try {
      final date = DateTime.parse(dateString);
      final DateFormat formatter =
          DateFormat('d \'de\' MMMM \'de\' yyyy, h:mm a', 'es_ES');
      return formatter.format(date);
    } catch (e) {
      return dateString; // Retorna el valor original si hay un error
    }
  }

  final List<String> estados = [
    'Esperando confirmación',
    'Pago del cliente',
    'Pago a proveedor',
    'En espera de productos',
    'Productos recibidos',
    'Entrega a cliente',
    'Finalizado',
    'Cancelado',
    'Cotización',
  ];

  // Función para obtener el color basado en el estado
  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'Esperando confirmación':
        return const Color.fromARGB(255, 229, 207, 13);
      case 'Pago del cliente':
        return Colors.green;
      case 'Pago a proveedor':
        return Colors.blue;
      case 'En espera de productos':
        return const Color.fromARGB(255, 255, 213, 151);
      case 'Productos recibidos':
        return const Color.fromARGB(255, 181, 54, 244);
      case 'Entrega a cliente':
        return const Color.fromARGB(255, 255, 99, 247);
      case 'Finalizado,':
        return const Color.fromARGB(255, 128, 53, 219);
      case 'Cancelado':
        return Colors.red;
      case 'Cotización':
        return const Color.fromARGB(255, 64, 124, 255);
      default:
        return Colors.green; // Color por defecto
    }
  }

  final FocusNode _focusNode = FocusNode();

  Future<bool> actualizarEstado(String folio, String estado) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.26:3000/api/v1/estados/agregar'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'iddetalleventa': folio,
          'estado': estado,
        }),
      );

      if (response.statusCode == 200) {
        // Mostrar SnackBar de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          fetchClientesYDetallesYArticulos();
        });
        return true; // Indica que la actualización fue exitosa
      } else {
        // Asume que 'response.body' es un JSON
        Map<String, dynamic> errorResponse = jsonDecode(response.body);

// Extrae el código y el mensaje de error
        int errorCode = errorResponse['Error']?['Code'] ?? 0;
        String errorMessage =
            errorResponse['Error']?['Message'] ?? 'Error desconocido';

        // Mostrar SnackBar de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error $errorCode: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
        return false; // Indica que hubo un error
      }
    } catch (e) {
      // Mostrar SnackBar de error en la solicitud
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en la solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false; // Indica que hubo un error
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
          : GestureDetector(
              onTap: () {
                _focusNode.unfocus(); // Quita el foco al tocar fuera
              },
              child: ListView.builder(
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

                      // Calcular el total del precio de compra
                      double totalCompra = 0.0;
                      for (var articuloDetalle in detalle['articulos']) {
                        totalCompra +=
                            (articuloDetalle['precio_compra'] ?? 0.0) *
                                (articuloDetalle['cantidad'] ?? 1.0);
                      }

                      // Obtener el estado actual
                      final estado = obtenerEstadoActual(detalle);

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        elevation: 4,
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${cliente['nombres'] ?? 'Cliente desconocido'} - ${detalle['nombre_venta'] ?? 'Venta sin nombre'}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${formatDate(detalle['fechaCreacion'] as String?)}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(
                                          width:
                                              16), // Espaciado entre el texto del estado y la fecha
                                      // Contenedor para el círculo y el texto del estado
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 2, horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                                  _estadoPorFolio[folio] ??
                                                      estado!)
                                              .withOpacity(0.09),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _getStatusColor(
                                                _estadoPorFolio[folio] ??
                                                    estado!),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _getStatusColor(
                                                    _estadoPorFolio[folio] ??
                                                        estado!),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            DropdownButton<String>(
                                              focusNode: _focusNode,
                                              value: _estadoPorFolio[folio] ??
                                                  estado,
                                              onChanged:
                                                  (String? newValue) async {
                                                if (newValue != null) {
                                                  // Llama a la función para actualizar el estado y espera el resultado
                                                  bool actualizado =
                                                      await actualizarEstado(
                                                          folio, newValue);
                                                  // Solo actualiza el estado en la interfaz si la actualización fue exitosa
                                                  if (actualizado) {
                                                    setState(() {
                                                      _estadoPorFolio[folio] =
                                                          newValue; // Actualiza el estado específico para el folio
                                                      fetchClientesYDetallesYArticulos();
                                                    });
                                                  } else {
                                                    // Opcional: Si deseas revertir el estado al anterior en caso de error
                                                    setState(() {
                                                      _estadoPorFolio[folio] =
                                                          estado; // Reemplaza 'estado' con el valor anterior si tienes acceso a él
                                                    });
                                                  }
                                                  _focusNode
                                                      .unfocus(); // Quita el foco al seleccionar un nuevo valor

                                                  setState(() {
                                                    fetchClientesYDetallesYArticulos();
                                                  });
                                                }
                                              },
                                              items: estados.map<
                                                      DropdownMenuItem<String>>(
                                                  (String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              underline: SizedBox(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Folio a la izquierda
                                    Text(
                                      'Folio: $folio',
                                      style: TextStyle(
                                        color: Color(0xFF00A1B0),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    // Cifras a la derecha
                                    Row(
                                      children: [
                                        Text(
                                          'Precio Compra: ',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '\$${totalCompra.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(
                                            width:
                                                16), // Espacio entre las cifras
                                        Text(
                                          'Subtotal: ',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '\$${detalle['subtotal'] ?? '0.00'}',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Text(
                                          'IVA: ',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '\$${detalle['iva'] ?? '0.00'}',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Text(
                                          'Total: ',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '\$${detalle['total'] ?? '0.00'}',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                  'Teléfono: ${cliente['telefono'] ?? 'No disponible'}'),
                                              Text(
                                                  'Email: ${cliente['email'] ?? 'No disponible'}'),
                                            ],
                                          ),
                                          SizedBox(height: 16),
                                          ...detalle['articulos']
                                              .map<Widget>((articuloDetalle) {
                                            final articulo =
                                                articulos.firstWhere(
                                              (articulo) =>
                                                  articulo['idarticulo'] ==
                                                  articuloDetalle['idarticulo'],
                                              orElse: () => null,
                                            );

                                            return Card(
                                              color: const Color.fromARGB(
                                                  255, 243, 243, 243),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4.0,
                                                      horizontal: 8.0),
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
                                                      style: TextStyle(
                                                          fontSize: 16),
                                                    )),
                                                    Expanded(
                                                        child: Text(
                                                      'Producto: ${articulo != null ? articulo['descripcion'] ?? 'Desconocido' : 'Desconocido'}',
                                                      style: TextStyle(
                                                          fontSize: 16),
                                                    )),
                                                    Expanded(
                                                        child: Text(
                                                      'Compra: \$${articuloDetalle['precio_compra'] ?? '0.00'}',
                                                      style: TextStyle(
                                                          fontSize: 16),
                                                    )),
                                                    Expanded(
                                                        child: Text(
                                                      'Porcentaje: ${articuloDetalle['porcentaje']  ?? '0.00'}%',
                                                      style: TextStyle(
                                                          fontSize: 16),
                                                    )),
                                                    Expanded(
                                                        child: Text(
                                                      'Venta: \$${articuloDetalle['precio_venta'] ?? '0.00'}',
                                                      style: TextStyle(
                                                          fontSize: 16),
                                                    )),
                                                    Expanded(
                                                        child: Text(
                                                      'Ganancia: \$${articuloDetalle['ganancia'] ?? '0.00'}',
                                                      style: TextStyle(
                                                          fontSize: 16),
                                                    )),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          SizedBox(height: 10),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0,
                                                horizontal: 16.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .spaceBetween, // Espacio entre elementos
                                              children: [
                                                Row(
                                                  // Elementos de la izquierda
                                                  children: [
                                                    Text(
                                                      'Subtotal:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(
                                                      '\$${detalle['subtotal'] ?? '0.00'}',
                                                      style: TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  // Elementos nuevos a la derecha
                                                  children: [
                                                    Text(
                                                      'Método de pago:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(
                                                      detalle['tipo_pago'],
                                                      style: TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0,
                                                horizontal: 16.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .spaceBetween, // Espacio entre elementos
                                              children: [
                                                Row(
                                                  // Elementos de la izquierda
                                                  children: [
                                                    Text(
                                                      'IVA:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(
                                                      '\$${detalle['iva'] ?? '0.00'}',
                                                      style: TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  // Elementos nuevos a la derecha
                                                  children: [
                                                    Text(
                                                      'Factura:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(
                                                      detalle['factura'],
                                                      style: TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 8,
                                                bottom: 8,
                                                left: 16,
                                                right: 0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .spaceBetween, // Espacio entre elementos
                                              children: [
                                                Row(
                                                  // Elementos de la izquierda
                                                  children: [
                                                    Text(
                                                      'Total:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(
                                                      '\$${detalle['total'] ?? '0.00'}',
                                                      style: TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  // Elementos nuevos a la derecha
                                                  children: [
                                                    TextButton(
                                                      onPressed: () {
                                                        // Llamas a la función para mostrar el diálogo, pasando el contexto y los detalles
                                                        mostrarDetallesEstado(
                                                            context,
                                                            detalle['estados']);
                                                        setState(() {
                                                          fetchClientesYDetallesYArticulos();
                                                        });
                                                      },
                                                      child: Text(
                                                        'Ver detalles del estado',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                            color: Color(
                                                                0xFF00A1B0)),
                                                      ),
                                                    ),
                                                  ],
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
            ),
    );
  }

  void mostrarDetallesEstado(
      BuildContext context, List<dynamic> estadosActuales) {
    setState(() {
      fetchClientesYDetallesYArticulos();
    });
    // Lista de todos los estados posibles
    final List<String> estados = [
      'Esperando confirmación',
      'Pago del cliente',
      'Pago a proveedor',
      'En espera de productos',
      'Productos recibidos',
      'Entrega a cliente',
      'Finalizado',
      'Cancelado',
      'Cotización',
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detalles del Estado'),
          content: Container(
            width: MediaQuery.of(context).size.width *
                0.3, // 80% del ancho de la pantalla
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: estados.length,
              itemBuilder: (BuildContext context, int index) {
                final estado = estados[index];
                final color = _getStatusColor(estado);

                // Buscar si este estado ya tiene una fecha en el array de 'estadosActuales'
                final estadoEncontrado = estadosActuales.firstWhere(
                  (e) => e['estado'] == estado,
                  orElse: () => null,
                );

                final fechaEstado = estadoEncontrado != null
                    ? estadoEncontrado['fechaestado']
                    : 'No disponible'; // Si no se encontró, indica que no ha llegado

                // Color de la fecha basado en si es 'No disponible' o no
                final fechaColor = fechaEstado == 'No disponible'
                    ? Colors.grey // gris si no ha alcanzado
                    : Color(0xFF00A1B0); // azul si tiene fecha

                final fechaFontWeight = fechaEstado == 'No disponible'
                    ? FontWeight.normal // normal si no ha alcanzado
                    : FontWeight.w500; // negrita si tiene fecha

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        estado,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' - ${formatDateWithTime(fechaEstado)}', // Mostrar la fecha o 'No disponible'
                        style: TextStyle(
                            fontSize: 14,
                            color: fechaColor,
                            fontWeight: fechaFontWeight),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Limpiar los AnimationControllers al cerrar el widget
    _controllers.values.forEach((controller) {
      controller.dispose();
    });
    super.dispose();
    _focusNode.dispose();
  }
}
