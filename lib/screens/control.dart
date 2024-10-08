import 'dart:io';

import 'package:cotizacion/custom_app_bar.dart';
import 'package:cotizacion/generarPDFControl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../ip.dart'; // Importar el archivo de la IP

class ControlScreen extends StatefulWidget {
  const ControlScreen({Key? key}) : super(key: key); // Acepta el parámetro key

  @override
  ControlScreenState createState() => ControlScreenState();
}

class ControlScreenState extends State<ControlScreen>
    with TickerProviderStateMixin {
  List<dynamic> clientes = [];
  List<dynamic> detalles = [];
  List<dynamic> filteredDetalles =
      []; // Lista filtrada para mostrar en el ListView
  final TextEditingController _searchController = TextEditingController();
  int currentPage = 0;
  final int itemsPerPage = 10;

  Map<int, bool> esCortaMap =
      {}; // Mapea los índices de la lista a su estado de fecha.

  String? selectedEstado = 'Todos';
  String? selectedMetodoPago = 'Todos';
  String? selectedFactura = 'Todos';

  Map<String, bool> _expandedState =
      {}; // Mapa para rastrear el estado expandido de cada folio
  Map<String, AnimationController> _controllers =
      {}; // Mapa para AnimationControllers
  Map<String, String?> _estadoPorFolio = {};

  String? estadoActual;

  bool _isDarkMode = false; // Estado del modo oscuro

  // Variable para almacenar la fecha seleccionada
  DateTime? selectedDate;

  late FocusNode _focusNode;
  @override
  void initState() {
    super.initState();
    fetchDatos();
    _searchController.addListener(_filterDetails);
    _focusNode = FocusNode(skipTraversal: true, canRequestFocus: false);
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  void _filterDetails() {
    final query = _searchController.text.toLowerCase();
    print('Buscando: "$query"');

    setState(() {
      filteredDetalles = detalles.where((detalle) {
        final cliente = detalle['cliente']?.toLowerCase() ?? '';
        final estadoList = detalle['estado_actual'] as List<dynamic>?;
        final estado = estadoList != null && estadoList.isNotEmpty
            ? estadoList.first['estado']
            : '';
        final tipoPago = detalle['tipo_pago'] ?? '';
        final factura = detalle['factura'] ?? 'No';

        // Convertir 'fecha_creacion' a DateTime
        final detalleDate = DateTime.parse(detalle['fecha_creacion'] ?? '');
        final detalleDateOnly =
            DateTime(detalleDate.year, detalleDate.month, detalleDate.day);

        // Imprimir para depuración
        print('Detalle fecha: ${detalle['fecha_creacion']}');
        print('Detalle Date: $detalleDate');
        print('Selected Date: $selectedDate');

        // Coincidencias
        final matchesQuery = cliente.contains(query);
        final matchesEstado =
            selectedEstado == 'Todos' || estado == selectedEstado;
        final matchesMetodoPago =
            selectedMetodoPago == 'Todos' || tipoPago == selectedMetodoPago;
        final matchesFactura =
            selectedFactura == 'Todos' || factura == selectedFactura;

        // Comparación de fechas
        final matchesDate = selectedDate == null ||
            (detalleDate.year == selectedDate!.year &&
                detalleDate.month == selectedDate!.month &&
                detalleDate.day == selectedDate!.day);

        // Imprimir coincidencias para depuración
        print('Coincide con búsqueda: $matchesQuery');
        print('Coincide con estado: $matchesEstado');
        print('Coincide con tipo de pago: $matchesMetodoPago');
        print('Coincide con factura: $matchesFactura');
        print('Coincide con fecha: $matchesDate');

        // Retornar true si todas las condiciones de filtrado son verdaderas
        return matchesQuery &&
            matchesEstado &&
            matchesMetodoPago &&
            matchesFactura &&
            matchesDate;
      }).toList();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Aquí puedes llamar al método cuando las dependencias cambian
    fetchDatos();
  }

  Future<void> fetchDatos() async {
    try {
      final detallesResponse = await http.get(
        Uri.parse('http://$baseUrl:3000/api/v1/detalles/'),
      );
      final clientesResponse = await http.get(
        Uri.parse('http://$baseUrl:3000/api/v1/clientes/'),
      );

      if (detallesResponse.statusCode == 200) {
        setState(() {
          detalles = json.decode(detallesResponse.body);
          clientes = json.decode(clientesResponse.body);

          // Asignar detalles filtrados
          filteredDetalles = detalles;

          // Ordenar los detalles por fecha_creacion en orden descendente
          detalles.sort((a, b) {
            DateTime fechaA = DateTime.parse(a['fecha_creacion']);
            DateTime fechaB = DateTime.parse(b['fecha_creacion']);
            return fechaB.compareTo(fechaA); // Más reciente primero
          });
        });
      } else {
        throw Exception('Error al obtener los datos');
      }
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

  bool _esCorta = true;

  String formatDateCorta(DateTime fecha) {
    DateFormat formatoCorto = DateFormat('dd/MM/yyyy', 'es_ES');
    return formatoCorto.format(fecha);
  }

  String formatDateLarga(DateTime fecha) {
    DateFormat formatoLargo = DateFormat(
        'EEEE, dd MMMM yyyy, hh:mm a', 'es_ES'); // Formato largo con hora
    return formatoLargo.format(fecha);
  }

  String formatDateWithTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Fecha desconocida';
    }
    try {
      final date = DateTime.parse(dateString);
      final DateFormat formatter =
          DateFormat('d \'de\' MMM \'de\' yyyy, h:mm a', 'es_ES');
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

  final List<String> estadosFiltro = [
    'Todos', // Elemento extra para "reiniciar" el filtro
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

  final List<String> tiposPago = [
    'Todos',
    'Efectivo',
    'Transferencia',
    'No asignado'
  ];

  final List<String> facturas = [
    'Todos',
    'Si',
    'No'
  ]; // Valores posibles para factura

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

  Future<bool> actualizarEstado(String folio, String estado) async {
    try {
      final response = await http.post(
        Uri.parse('http://$baseUrl:3000/api/v1/estados/agregar'),
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
          fetchDatos();
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
    // Formateador de números
    // Convierte la fecha de String a DateTime
    final numberFormat = NumberFormat("#,##0.00", "en_US");

    int totalPages = (filteredDetalles.length / itemsPerPage).ceil();
    List currentItems = filteredDetalles
        .skip(currentPage * itemsPerPage)
        .take(itemsPerPage)
        .toList();

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus(); // Quita el foco al tocar fuera
      },
      child: Scaffold(
        backgroundColor: Color(0xFFf7f8fa),
        appBar: CustomAppBar(
          isDarkMode: _isDarkMode,
          toggleDarkMode: _toggleDarkMode,
          title: 'Control de Ventas', // Título específico para esta pantalla
        ),
        body: clientes.isEmpty || detalles.isEmpty
            ? Center(
                child: clientes.isEmpty && detalles.isEmpty
                    ? Text(
                        'No hay datos para mostrar',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      )
                    : CircularProgressIndicator(),
              )
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            style: TextStyle(fontSize: 14),
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Buscar cliente',
                              labelStyle: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide:
                                    BorderSide(color: Color(0xFF001F3F)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide(
                                    color: Colors.grey.shade300, width: 1.5),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 20),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.0), // Espacio entre los campos
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          hint: Text('Estado'),
                          value: selectedEstado,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Estado',
                            labelStyle: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide(color: Color(0xFF001F3F)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300, width: 1.5),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 15, horizontal: 20),
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF001F3F),
                          ),
                          dropdownColor: Colors.white,
                          items: estadosFiltro.map((estado) {
                            return DropdownMenuItem<String>(
                              value: estado,
                              child: Text(
                                estado,
                                style: TextStyle(
                                    color: Colors.black87, fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedEstado = value;
                              _filterDetails(); // Filtra al cambiar
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 16.0),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          hint: Text('Método de Pago'),
                          value: selectedMetodoPago,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Método de Pago',
                            labelStyle: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide(color: Color(0xFF001F3F)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300, width: 1.5),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 15, horizontal: 20),
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF001F3F),
                          ),
                          dropdownColor: Colors.white,
                          items: tiposPago.map((tipo) {
                            return DropdownMenuItem<String>(
                              value: tipo,
                              child: Text(
                                tipo,
                                style: TextStyle(
                                    color: Colors.black87, fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedMetodoPago = value;
                              _filterDetails(); // Filtra al cambiar
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 16.0),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          hint: Text('Factura'),
                          value: selectedFactura,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Factura',
                            labelStyle: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide(color: Color(0xFF001F3F)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300, width: 1.5),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 15, horizontal: 20),
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF001F3F),
                          ),
                          dropdownColor: Colors.white,
                          items: facturas.map((factura) {
                            return DropdownMenuItem<String>(
                              value: factura,
                              child: Text(
                                factura,
                                style: TextStyle(
                                    color: Colors.black87, fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedFactura = value!;
                              _filterDetails(); // Filtra al cambiar
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 16.0),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 50, // Altura fija para el botón
                          child: TextButton(
                            onPressed: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );

                              if (pickedDate != null &&
                                  pickedDate != selectedDate) {
                                setState(() {
                                  selectedDate = pickedDate;
                                  _filterDetails(); // Filtra al seleccionar la fecha
                                });
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 10),
                              backgroundColor:
                                  Colors.white, // Color de fondo blanco
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    30.0), // Bordes redondeados
                                side: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1.5), // Marco gris
                              ),
                            ),
                            child: Text(
                              selectedDate == null
                                  ? 'Selecciona Fecha'
                                  : formatDateCorta(selectedDate!),
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.0),
                      Container(
                        width: 60, // Establecer un ancho fijo
                        height: 50, // Altura fija para el botón
                        child: Tooltip(
                          message: 'Restablecer fecha', // Mensaje del tooltip
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                selectedDate =
                                    null; // Restablecer la fecha seleccionada
                                _filterDetails(); // Filtra de nuevo para mostrar todos los detalles
                              });
                            },
                            child: Stack(
                              alignment: Alignment
                                  .center, // Centrar los íconos en el Stack
                              children: [
                                Icon(
                                  Icons.calendar_today, // Ícono de calendario
                                  color: Colors.grey[
                                      800], // Color gris oscuro para el ícono de fondo
                                  size:
                                      28, // Tamaño aumentado para mayor visibilidad
                                ),
                                Positioned(
                                  left:
                                      5, // Ajustar la posición hacia la izquierda
                                  top: 8,
                                  child: Icon(
                                    Icons.refresh, // Ícono de recarga
                                    color: Colors.grey[
                                        800], // Color gris oscuro para el ícono de recarga
                                    size:
                                        18, // Tamaño aumentado para mayor visibilidad
                                  ),
                                ),
                              ],
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Colors.white, // Color de fondo blanco
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    30.0), // Bordes redondeados
                                side: BorderSide(
                                    color: Colors.grey.shade300), // Marco gris
                              ),
                              padding: EdgeInsets.symmetric(
                                  vertical: 0), // Espaciado vertical
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 16.0),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: currentItems.length,
                      itemBuilder: (context, index) {
                        final detalle = currentItems[index];
                        final folio = detalle['folio'] ?? 'desconocido';
                        final isExpanded = _expandedState[folio] ?? false;

                        // Crear o actualizar el AnimationController para el folio
                        if (!_controllers.containsKey(folio)) {
                          _controllers[folio] = AnimationController(
                            vsync: this,
                            duration: Duration(milliseconds: 300),
                          );
                        }

                        // Calcular la ganancia total
                        double gananciaTotal = 0.0;
                        for (var articulo in detalle['articulos']) {
                          gananciaTotal += (articulo['ganancia'] ?? 0.0) *
                              (articulo['cantidad'] ?? 1.0);
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

                        // Función para buscar el cliente basado en el idcliente
                        Map<String, dynamic>? buscarClientePorId(
                            String idcliente) {
                          for (var cliente in clientes) {
                            if (cliente['idcliente'] == idcliente) {
                              return cliente; // Retorna el cliente si encuentra coincidencia
                            }
                          }
                          return null; // Retorna null si no encuentra el cliente
                        }

                        // Obtener el idcliente del detalle
                        final String idCliente =
                            detalle['idcliente'] ?? 'desconocido';
                        final cliente = buscarClientePorId(idCliente);

                        // Si no existe una entrada en el Map para este índice, se inicializa como true (formato corto).
                        if (!esCortaMap.containsKey(index)) {
                          esCortaMap[index] = true;
                        }

                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 16.0),
                          elevation: 4,
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Cliente y Venta
                                        Expanded(
                                          child: Text(
                                            '${detalle['cliente'] ?? 'Cliente desconocido'} - ${detalle['nombre_venta'] ?? 'Venta sin nombre'}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 0, horizontal: 8),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                                    _estadoPorFolio[folio] ??
                                                        estado!)
                                                .withOpacity(0.09),
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            border: Border.all(
                                              color: _getStatusColor(
                                                  _estadoPorFolio[folio] ??
                                                      estado!),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: _getStatusColor(
                                                      _estadoPorFolio[folio] ??
                                                          estado!),
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Container(
                                                constraints: BoxConstraints(
                                                    maxHeight: 30),
                                                child: DropdownButton<String>(
                                                  focusNode: _focusNode,
                                                  value:
                                                      _estadoPorFolio[folio] ??
                                                          estado,
                                                  onChanged:
                                                      (String? newValue) async {
                                                    if (newValue != null) {
                                                      bool actualizado =
                                                          await actualizarEstado(
                                                              folio, newValue);
                                                      if (actualizado) {
                                                        setState(() {
                                                          _estadoPorFolio[
                                                              folio] = newValue;
                                                          fetchDatos();
                                                        });
                                                      } else {
                                                        setState(() {
                                                          _estadoPorFolio[
                                                              folio] = estado;
                                                        });
                                                      }
                                                      _focusNode
                                                          .unfocus(); // Quita el foco al seleccionar un nuevo valor
                                                    }
                                                  },
                                                  items: estados.map<
                                                          DropdownMenuItem<
                                                              String>>(
                                                      (String value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(
                                                        value,
                                                        style: TextStyle(
                                                            fontSize: 12),
                                                      ),
                                                    );
                                                  }).toList(),
                                                  onTap: () {
                                                    FocusScope.of(context)
                                                        .requestFocus(
                                                            FocusNode());
                                                  },
                                                  underline: SizedBox(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    // Contenedor para el estado y el DropdownButton
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Divider(), // Añadir un separador
                                    // Cifras con más espaciado y columnas
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Columna con los precios
                                        Expanded(
                                          child: Wrap(
                                            spacing: 16,
                                            runSpacing: 4,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text('Precio Compra:',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  Text(
                                                      '\$${totalCompra.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                          fontSize: 14)),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text('Ganancia Total:',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  Text(
                                                      '\$${gananciaTotal.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                          fontSize: 14)),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text('Subtotal:',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  Text(
                                                      '\$${detalle['subtotal'] ?? '0.00'}',
                                                      style: TextStyle(
                                                          fontSize: 14)),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text('IVA:',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  Text(
                                                      '\$${detalle['iva'] ?? '0.00'}',
                                                      style: TextStyle(
                                                          fontSize: 14)),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text('Total:',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  Text(
                                                    '\$${detalle['total'] ?? '0.00'}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Total a la derecha
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              children: [
                                                // Fecha de Creación
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      // Cambia el estado solo para este elemento específico.
                                                      esCortaMap[index] =
                                                          !esCortaMap[index]!;
                                                    });

                                                    // Regresar al formato corto después de unos segundos.
                                                    Future.delayed(
                                                        Duration(seconds: 2),
                                                        () {
                                                      setState(() {
                                                        esCortaMap[index] =
                                                            true;
                                                      });
                                                    });
                                                  },
                                                  child: AnimatedSwitcher(
                                                    duration: Duration(
                                                        milliseconds: 300),
                                                    child: Text(
                                                      esCortaMap[
                                                              index]! // Obtiene el estado de este elemento.
                                                          ? formatDateCorta(
                                                              DateTime.parse(
                                                                  detalle[
                                                                      'fecha_creacion']))
                                                          : formatDateLarga(
                                                              DateTime.parse(
                                                                  detalle[
                                                                      'fecha_creacion'])),
                                                      key: ValueKey<bool>(
                                                          esCortaMap[index]!),
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  'Folio: $folio',
                                                  style: TextStyle(
                                                    color: Color(0xFF008F8F),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
                                        if (value) _expandedState[key] = false;
                                      });
                                      _expandedState[folio] = true;
                                      FocusScope.of(context)
                                          .requestFocus(FocusNode());
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Teléfono: ${cliente != null ? cliente['telefono'] ?? 'No disponible' : 'Cliente no encontrado'}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  'Email: ${cliente != null ? cliente['email'] ?? 'No disponible' : 'Email no encontrado'}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 16),
                                            ...detalle['articulos']
                                                .map<Widget>((articuloDetalle) {
                                              return Card(
                                                color: Colors.grey[100],
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
                                                        flex: 1,
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start, // Alinea a la izquierda
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              'Cantidad:',
                                                              style: TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      left: 25),
                                                              child: Text(
                                                                '${articuloDetalle['cantidad'] ?? '0'}',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        14),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 4,
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start, // Alinea a la izquierda
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              'Producto:',
                                                              style: TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                              textAlign: TextAlign
                                                                  .left, // Alinea a la izquierda
                                                            ),
                                                            Text(
                                                              '${articuloDetalle['descripcion'] ?? 'Desconocido'}',
                                                              style: TextStyle(
                                                                  fontSize: 14),
                                                              textAlign: TextAlign
                                                                  .left, // Alinea a la izquierda
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              'Precio Compra:',
                                                              style: TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                            Text(
                                                              '\$${articuloDetalle['precio_compra']?.toStringAsFixed(2) ?? '0.00'}',
                                                              style: TextStyle(
                                                                  fontSize: 14),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              'Porcentaje:',
                                                              style: TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                            Text(
                                                              '${articuloDetalle['porcentaje'] ?? '0.00'}%',
                                                              style: TextStyle(
                                                                  fontSize: 14),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              'Ganancia p/p:',
                                                              style: TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                            Text(
                                                              '\$${articuloDetalle['ganancia']?.toStringAsFixed(2) ?? '0.00'}',
                                                              style: TextStyle(
                                                                  fontSize: 14),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              'Ganancia Total:',
                                                              style: TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                            Text(
                                                              '\$${((double.tryParse(articuloDetalle['cantidad']?.toString() ?? '0') ?? 0) * (double.tryParse(articuloDetalle['ganancia']?.toString() ?? '0') ?? 0)).toStringAsFixed(2)}',
                                                              style: TextStyle(
                                                                  fontSize: 14),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              'Venta:',
                                                              style: TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                            Text(
                                                              '\$${articuloDetalle['precio_venta']?.toStringAsFixed(2) ?? '0.00'}',
                                                              style: TextStyle(
                                                                  fontSize: 14),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              'Total:',
                                                              style: TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                            Text(
                                                              '\$${(articuloDetalle['precio_venta'] ?? 0) * (articuloDetalle['cantidad'] ?? 0)}',
                                                              style: TextStyle(
                                                                  fontSize: 14),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            SizedBox(height: 10),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      SizedBox(width: 10),
                                                      Text(
                                                        '\$${detalle['subtotal'] ?? '0.00'}',
                                                        style: TextStyle(
                                                          color: Colors.black87,
                                                          fontSize: 14,
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
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      SizedBox(width: 10),
                                                      Text(
                                                        detalle['tipo_pago'] ??
                                                            'No disponible',
                                                        style: TextStyle(
                                                          color: Colors.black87,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      SizedBox(width: 10),
                                                      Text(
                                                        '\$${detalle['iva'] ?? '0.00'}',
                                                        style: TextStyle(
                                                          color: Colors.black87,
                                                          fontSize: 14,
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
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      SizedBox(width: 10),
                                                      Text(
                                                        detalle['factura'],
                                                        style: TextStyle(
                                                          color: Colors.black87,
                                                          fontSize: 14,
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
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      SizedBox(width: 10),
                                                      Text(
                                                        '\$${detalle['total'] ?? '0.00'}',
                                                        style: TextStyle(
                                                          color: Colors.black87,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    // Elementos nuevos a la derecha
                                                    children: [
                                                      TextButton(
                                                        onPressed: () async {
                                                          // Asegúrate de que el cliente existe
                                                          if (cliente != null) {
                                                            // Crea un nuevo mapa que incluya los detalles del cliente
                                                            Map<String, dynamic>
                                                                pdfData = {
                                                              ...detalle,
                                                              'telefono': cliente[
                                                                      'telefono'] ??
                                                                  'No disponible',
                                                              'email': cliente[
                                                                      'email'] ??
                                                                  'No disponible',
                                                            };
                                                            await generarPDF(
                                                                pdfData); // Pasa el nuevo mapa a la función
                                                          } else {
                                                            // Maneja el caso de cliente no encontrado
                                                            print(
                                                                'Cliente no encontrado');
                                                          }
                                                        },
                                                        style: TextButton
                                                            .styleFrom(
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                        child: Icon(
                                                          Icons.picture_as_pdf,
                                                          color: Color(
                                                              0xFFB8001F), // Cambia el color del icono si lo deseas
                                                          size:
                                                              24, // Tamaño del icono
                                                        ),
                                                      ),
                                                      // Botón para editar la venta
                                                      TextButton(
                                                        onPressed: () {
                                                          mostrarDialogoEdicion(
                                                              context, detalle);
                                                        },
                                                        child: Icon(
                                                          Icons.edit,
                                                          color: Colors
                                                              .blue, // Cambia el color si lo deseas
                                                          size: 24,
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          // Llamas a la función para mostrar el diálogo, pasando el contexto y los detalles
                                                          mostrarDetallesEstado(
                                                              context,
                                                              detalle[
                                                                  'estados']);
                                                          setState(() {
                                                            fetchDatos();
                                                          });
                                                        },
                                                        child: Text(
                                                          'Ver detalles del estado',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14,
                                                              color: Color(
                                                                  0xFF008F8F)),
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
                      },
                    ),
                  ),
                  _buildPagination(totalPages),
                ],
              ),
      ),
    );
  }

  void mostrarDialogoEdicion(BuildContext context, Map<String, dynamic> detalleOriginal) {
  // Crear una copia profunda del 'detalle' original.
  Map<String, dynamic> detalle = deepCopy(detalleOriginal);

  // Crear los controladores fuera del builder para evitar recrearlos constantemente
  TextEditingController nombreVentaController = TextEditingController(text: detalle['nombre_venta']);
  TextEditingController subtotalController = TextEditingController();
  TextEditingController ivaController = TextEditingController();
  TextEditingController totalController = TextEditingController();

  // Inicializar controladores para cada artículo
  List<TextEditingController> tipoProductoControllers = [];
  List<TextEditingController> cantidadControllers = [];
  List<TextEditingController> descripcionControllers = [];
  List<TextEditingController> precioCompraControllers = [];
  List<TextEditingController> porcentajeGananciaControllers = [];

  // Cargar los controladores con los datos iniciales de los artículos
  for (var articulo in detalle['articulos']) {
    tipoProductoControllers.add(TextEditingController(text: articulo['tipo']));
    cantidadControllers.add(TextEditingController(text: articulo['cantidad'].toString()));
    descripcionControllers.add(TextEditingController(text: articulo['descripcion']));
    precioCompraControllers.add(TextEditingController(text: articulo['precio_compra'].toString()));
    porcentajeGananciaControllers.add(TextEditingController(text: articulo['porcentaje'].toString()));
  }

  // Cálculo de valores iniciales
  calcularTotales(detalle, subtotalController, ivaController, totalController);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      String? facturaSeleccionada = detalle['factura'];
      String? tipoPagoSeleccionado = detalle['tipo_pago'];

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              "Editar Artículos",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF001F3F),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modifica los artículos y los valores se actualizarán automáticamente.',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  Divider(height: 20, color: Colors.grey[300]),

                  // Campo para nombre_venta
                  _buildTextFieldValidator(
                    controller: nombreVentaController,
                    label: 'Nombre Venta',
                  ),

                  SizedBox(height: 10),

                  // Campo para factura y tipo_pago en una fila
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildDropdownField(
                          label: 'Factura',
                          value: facturaSeleccionada,
                          items: ['Sí', 'No'],
                          onChanged: (String? newValue) {
                            setState(() {
                              facturaSeleccionada = newValue!;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildDropdownField(
                          label: 'Tipo de Pago',
                          value: tipoPagoSeleccionado,
                          items: ['Efectivo', 'Transferencia', 'No asignado'],
                          onChanged: (String? newValue) {
                            setState(() {
                              tipoPagoSeleccionado = newValue!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 15),

                  // Mostrar los artículos con sus controladores asignados
                  ...detalle['articulos'].asMap().entries.map<Widget>((entry) {
                    int index = entry.key;
                    var articulo = entry.value;

                    // Variables para almacenar los resultados calculados
                    double precioVentaUnitario = 0.0;
                    double precioVentaTotal = 0.0;
                    double gananciaPp = 0.0;
                    double gananciaTotal = 0.0;

                    // Función que recalcula los valores cuando se cambia algún campo
                    void recalcularValores() {
                      int cantidad = int.tryParse(cantidadControllers[index].text) ?? 0;
                      double precioCompra = double.tryParse(precioCompraControllers[index].text) ?? 0.0;
                      double porcentajeGanancia = double.tryParse(porcentajeGananciaControllers[index].text) ?? 0.0;

                      // Cálculo del precio de venta unitario
                      precioVentaUnitario = precioCompra + (precioCompra * (porcentajeGanancia / 100));
                      // Cálculo del precio de venta total
                      precioVentaTotal = precioVentaUnitario * cantidad;
                      // Cálculo de la ganancia por producto
                      gananciaPp = precioVentaUnitario - precioCompra;
                      // Cálculo de la ganancia total (ganancia por producto * cantidad)
                      gananciaTotal = gananciaPp * cantidad;

                      // Actualiza los valores dentro de articulo para reflejar los cambios
                      articulo['precio_venta'] = precioVentaUnitario;
                      articulo['ganancia'] = gananciaTotal;

                      setState(() {});
                    }

                    // Realizar el cálculo inicial con los valores predeterminados
                    recalcularValores();

                    return Card(
                      color: Colors.grey[100],
                      elevation: 8,
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Producto: ${articulo['descripcion']}',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextFieldValidator(
                                    controller: tipoProductoControllers[index],
                                    label: 'Tipo Producto',
                                    inputType: TextInputType.text,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: _buildTextFieldValidator(
                                    controller: cantidadControllers[index],
                                    label: 'Cantidad',
                                    inputType: TextInputType.number,
                                    onChanged: (value) {
                                      recalcularValores();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextFieldValidator(
                                    controller: descripcionControllers[index],
                                    label: 'Descripción',
                                    inputType: TextInputType.text,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextFieldValidator(
                                    controller: precioCompraControllers[index],
                                    label: 'Precio Compra',
                                    inputType: TextInputType.number,
                                    onChanged: (value) {
                                      recalcularValores();
                                    },
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: _buildTextFieldValidator(
                                    controller: porcentajeGananciaControllers[index],
                                    label: '% Ganancia',
                                    inputType: TextInputType.number,
                                    onChanged: (value) {
                                      recalcularValores();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Divider(),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Precio Venta (Unitario): ${precioVentaUnitario.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Precio Venta (Total): ${precioVentaTotal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Ganancia por Producto: ${gananciaPp.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Ganancia Total: ${gananciaTotal.toStringAsFixed(2)}',
                                     style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                  Divider(height: 20, color: Colors.grey[300]),
                  _buildResumenTotal('Subtotal', subtotalController.text),
                  _buildResumenTotal('IVA', ivaController.text),
                  _buildResumenTotal('Total', totalController.text),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text("Cancelar", style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text("Guardar", style: TextStyle(color: Colors.green)),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Actualiza los datos originales con los valores del detalle temporal
                  detalleOriginal.addAll(detalle);
                },
              ),
            ],
          );
        },
      );
    },
  );
}

// Función para realizar una copia profunda de un Map en Dart
Map<String, dynamic> deepCopy(Map<String, dynamic> original) {
  return original.map((key, value) {
    if (value is Map<String, dynamic>) {
      return MapEntry(key, deepCopy(value));
    } else if (value is List) {
      return MapEntry(key, List.from(value.map((item) => item is Map<String, dynamic> ? deepCopy(item) : item)));
    } else {
      return MapEntry(key, value);
    }
  });
}



  Widget _buildTextFieldValidator({
    required TextEditingController controller,
    required String label,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(fontSize: 14),
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: Color(0xFF001F3F)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: Color(0xFF001F3F)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
      icon: Icon(
        Icons.arrow_drop_down,
        color: Color(0xFF001F3F),
      ),
      dropdownColor: Colors.white,
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: TextStyle(color: Colors.black87, fontSize: 14),
          ),
        );
      }).toList(),
    );
  }

// Widget para mostrar el resumen total
  Widget _buildResumenTotal(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            '\$$value',
            style: TextStyle(fontSize: 16, color: Colors.blueGrey[600]),
          ),
        ],
      ),
    );
  }

// Función para calcular el subtotal, IVA y total dinámicamente
  void calcularTotales(
      Map<String, dynamic> detalle,
      TextEditingController subtotalController,
      TextEditingController ivaController,
      TextEditingController totalController) {
    double subtotal = detalle['articulos'].fold(
        0.0,
        (sum, articulo) =>
            sum + (articulo['cantidad'] * articulo['precio_venta']));
    double iva = subtotal * 0.16; // Asumiendo un IVA del 16%
    double total = subtotal + iva;

    subtotalController.text = subtotal.toStringAsFixed(2);
    ivaController.text = iva.toStringAsFixed(2);
    totalController.text = total.toStringAsFixed(2);
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Página ${currentPage + 1} de $totalPages',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Row(
            children: [
              _buildFirstPreviousButtons(),
              _buildThreePageButtons(totalPages),
              _buildNextLastButtons(totalPages),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFirstPreviousButtons() {
    return Row(
      children: [
        TextButton(
          onPressed: currentPage > 0
              ? () {
                  setState(() {
                    currentPage = 0; // Ir a la primera página
                  });
                }
              : null,
          child: Icon(
            Icons.keyboard_double_arrow_left,
            color: currentPage > 0
                ? Color(0xFF008F8F)
                : Colors.grey, // Color condicional
          ),
        ),
        TextButton(
          onPressed: currentPage > 0
              ? () {
                  setState(() {
                    currentPage--; // Ir a la página anterior
                  });
                }
              : null,
          child: Icon(
            Icons.keyboard_arrow_left,
            color: currentPage > 0
                ? Color(0xFF008F8F)
                : Colors.grey, // Color condicional
          ),
        ),
      ],
    );
  }

  Widget _buildThreePageButtons(int totalPages) {
    List<Widget> buttons = [];
    int startPage = (currentPage > 1) ? currentPage - 1 : 0;
    int endPage =
        (currentPage < totalPages - 2) ? currentPage + 1 : totalPages - 1;

    if (endPage - startPage < 2) {
      if (currentPage == totalPages - 1) {
        startPage = totalPages - 3 > 0 ? totalPages - 3 : 0;
      } else if (currentPage == totalPages - 2) {
        startPage = totalPages - 2;
      }
    }

    endPage = startPage + 2 < totalPages ? startPage + 2 : totalPages - 1;

    for (int i = startPage; i <= endPage; i++) {
      buttons.add(_buildPageButton(i, (i + 1).toString()));
    }

    return Row(children: buttons);
  }

  Widget _buildNextLastButtons(int totalPages) {
    return Row(
      children: [
        TextButton(
          onPressed: currentPage < totalPages - 1
              ? () {
                  setState(() {
                    currentPage++; // Ir a la página siguiente
                  });
                }
              : null,
          child: Icon(
            Icons.keyboard_arrow_right,
            color: currentPage < totalPages - 1
                ? Color(0xFF008F8F)
                : Colors.grey, // Color condicional
          ),
        ),
        TextButton(
          onPressed: currentPage < totalPages - 1
              ? () {
                  setState(() {
                    currentPage = totalPages - 1; // Ir a la última página
                  });
                }
              : null,
          child: Icon(
            Icons.keyboard_double_arrow_right,
            color: currentPage < totalPages - 1
                ? Color(0xFF008F8F)
                : Colors.grey, // Color condicional
          ),
        ),
      ],
    );
  }

  Widget _buildPageButton(int pageIndex, String label) {
    bool isActive = currentPage == pageIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: isActive ? Colors.white : Colors.black,
          backgroundColor: isActive ? Color(0xFF001F3F) : Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          setState(() {
            currentPage = pageIndex;
          });
        },
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void mostrarDetallesEstado(
      BuildContext context, List<dynamic> estadosActuales) {
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
                0.33, // 80% del ancho de la pantalla
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
    _searchController.dispose();
    super.dispose();
    _focusNode.dispose();
  }
}
