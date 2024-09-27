import 'package:cotizacion/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    fetchDatos();
    _searchController.addListener(_filterDetails);
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  void _filterDetails() {
    final query = _searchController.text.toLowerCase();
    print('Buscando: "$query"'); // Verifica el texto buscado

    setState(() {
      filteredDetalles = detalles.where((detalle) {
        final cliente = detalle['cliente']?.toLowerCase() ?? '';

        // Manejar estado_actual como lista
        final estadoList = detalle['estado_actual'] as List<dynamic>?;
        final estado = estadoList != null && estadoList.isNotEmpty
            ? estadoList.first['estado'] // Extrae el estado de la lista
            : '';

        final tipoPago = detalle['tipo_pago'] ?? '';
        final factura =
            detalle['factura'] ?? 'No'; // Valor predeterminado si no hay campo

        // Suponiendo que hay un campo 'fecha' en 'detalle' que almacena la fecha
        final detalleDate = DateTime.parse(detalle['fecha_creacion'] ??
            ''); // Asegúrate de que el formato sea compatible

        // Obtener solo la parte de la fecha de detalle
        final detalleDateOnly =
            DateTime(detalleDate.year, detalleDate.month, detalleDate.day);

        // Filtrado
        final matchesQuery = cliente.contains(query);
        final matchesEstado =
            selectedEstado == 'Todos' || estado == selectedEstado;
        final matchesMetodoPago =
            selectedMetodoPago == 'Todos' || tipoPago == selectedMetodoPago;
        final matchesFactura =
            selectedFactura == 'Todos' || factura == selectedFactura;
        final matchesDate = selectedDate == null ||
            detalleDateOnly.isAtSameMomentAs(DateTime(
                selectedDate!.year, selectedDate!.month, selectedDate!.day));

        // Imprimir detalles de la coincidencia
        print('Cliente: "$cliente"');
        print('Estado actual: "$estado"');
        print('Método de pago: "$tipoPago"');
        print('Factura: "$factura"');
        print('Fecha: "${detalle['fecha_creacion']}"');
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
      final detallesResponse = await http
          .get(Uri.parse('http://192.168.1.16:3000/api/v1/detalles/'));
      final clientesResponse = await http
          .get(Uri.parse('http://192.168.1.16:3000/api/v1/clientes/'));

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
    DateFormat formatoLargo =
        DateFormat('EEEE, dd MMMM yyyy, hh:mm a', 'es_ES'); // Formato largo con hora
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

  final FocusNode _focusNode = FocusNode();

  Future<bool> actualizarEstado(String folio, String estado) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.16:3000/api/v1/estados/agregar'),
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

  // Variable para almacenar la fecha seleccionada
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    // Formateador de números
    // Convierte la fecha de String a DateTime
    final numberFormat = NumberFormat("#,##0.00", "en_US");

    return Scaffold(
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
          : GestureDetector(
              onTap: () {
                _focusNode.unfocus(); // Quita el foco al tocar fuera
              },
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
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
                          items: estados.map((estado) {
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
                                  : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
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
                      itemCount: filteredDetalles.length,
                      itemBuilder: (context, index) {
                        final detalle = filteredDetalles[index];
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

                        // Función para buscar el cliente basado en el nombre
                        Map<String, dynamic>? buscarClientePorNombre(
                            String nombre) {
                          for (var cliente in clientes) {
                            if (cliente['nombres'] == nombre) {
                              return cliente; // Retorna el cliente si encuentra coincidencia
                            }
                          }
                          return null; // Retorna null si no encuentra el cliente
                        }

                        // Buscar el cliente correspondiente usando el nombre
                        final String nombreCliente =
                            detalle['cliente'] ?? 'desconocido';
                        final cliente = buscarClientePorNombre(nombreCliente);

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
                                                    maxHeight: 40),
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
                                                      _esCorta = !_esCorta;
                                                    });

                                                    // Regresar al formato corto después de unos segundos
                                                    Future.delayed(
                                                        Duration(seconds: 2),
                                                        () {
                                                      setState(() {
                                                        _esCorta = true;
                                                      });
                                                    });
                                                  },
                                                  child: AnimatedSwitcher(
                                                    duration: Duration(
                                                        milliseconds: 300),
                                                    child: Text(
                                                      _esCorta
                                                          ? formatDateCorta(
                                                              DateTime.parse(
                                                                  detalle[
                                                                      'fecha_creacion']))
                                                          : formatDateLarga(
                                                              DateTime.parse(
                                                                  detalle[
                                                                      'fecha_creacion'])),
                                                      key: ValueKey<bool>(
                                                          _esCorta),
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
                                                    color: Color(0xFF00A1B0),
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
                                                ),
                                                Text(
                                                  'Email: ${cliente != null ? cliente['email'] ?? 'No disponible' : 'Email no encontrado'}',
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 16),
                                            ...detalle['articulos']
                                                .map<Widget>((articuloDetalle) {
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
                                                        detalle['tipo_pago'] ??
                                                            'No disponible',
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
                      },
                    ),
                  ),
                ],
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
