import 'dart:io';

import 'package:cotizacion/custom_app_bar.dart';
import 'package:cotizacion/generarPDFControl.dart';
import 'package:cotizacion/screens/calculos.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
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

  bool _isLoadingInicio = true; // Variable para controlar el estado de carga

  bool _isLoading = false; // Variable para controlar el estado de carga

  bool _isEditing = false; // Variable para controlar el estado de edición

  bool isDeleting = false;

  bool _isDarkMode = false; // Estado del modo oscuro

  // Variable para almacenar la fecha seleccionada
  DateTime? selectedDate;

  late FocusNode _focusNode;
  @override
  void initState() {
    super.initState();
    _loadData(); // Carga los datos al iniciar la pantalla
    _searchController.addListener(_filterDetails);
    _focusNode = FocusNode(skipTraversal: true, canRequestFocus: false);
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  Future<void> _loadData() async {
    await fetchDatos(); // Llama a tu método de carga de datos
  }

  void _filterDetails() {
    final query = _searchController.text.toLowerCase();
    print('Buscando: "$query"');

    setState(() {
      filteredDetalles = detalles.where((detalle) {
        final cliente = detalle['cliente']?.toLowerCase() ?? '';
        final nombreVenta = detalle['nombre_venta']?.toLowerCase() ?? '';
        final folio = detalle['folio']?.toLowerCase() ?? '';
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
        //Buscar en cliente, nombre de venta y folio
        final matchesQuery = cliente.contains(query) ||
            nombreVenta.contains(query) ||
            folio.contains(query);
        // Buscar en el estado actual
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

/*   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Aquí puedes llamar al método cuando las dependencias cambian
    fetchDatos();
  } */

  Future<void> fetchDatos() async {
    try {
      setState(() {
        _isLoadingInicio = true; // Cambia el estado a loading al inicio
      });

      final detallesResponse = await http.get(
        Uri.parse('https://$baseUrl/api/v1/detalles/'),
      );
      final clientesResponse = await http.get(
        Uri.parse('https://$baseUrl/api/v1/clientes/'),
      );

      if (detallesResponse.statusCode == 200 &&
          clientesResponse.statusCode == 200) {
        // Verifica si el widget está montado antes de llamar a setState
        if (mounted) {
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
        }
      } else {
        // Manejo de error si no se obtienen los datos correctamente
        if (mounted) {
          setState(() {
            detalles = [];
            clientes = [];
          });
        }
        throw Exception('Error al obtener los datos');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      // Verifica si el widget sigue montado antes de cambiar el estado
      if (mounted) {
        setState(() {
          _isLoadingInicio =
              false; // Asegúrate de cambiar el estado a false al final
        });
      }
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
        Uri.parse('https://$baseUrl/api/v1/estados/agregar'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'iddetalleventa': folio,
          'estado': estado,
        }),
      );

      if (response.statusCode == 201) {
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
    final provider = Provider.of<CotizacionProvider>(context);
    // Formateador de números
    // Convierte la fecha de String a DateTime
    final numberFormat = NumberFormat("#,##0.00", "en_US");

    // Definir variables de color para el modo claro y oscuro
    Color colorTextFieldClaro = Color(0xFFFFFFFF); // Blanco para el modo claro
    Color colorTextFieldOscuro =
        Color(0xFF22354d); // Color oscuro para el modo oscuro

// Definir otras variables de color que puedas necesitar
    Color colorFondoClaro = Color(0xFFf7f8fa);
    Color colorFondoOscuro = Color(0xFF021526);
//(0xFF424769)
    Color colorTextoOscuro = Colors.black;
    Color colorTextoClaro = Colors.white;

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
        backgroundColor:
            provider.isDarkMode ? colorFondoOscuro : colorFondoClaro,
        appBar: CustomAppBar(
          isDarkMode: provider.isDarkMode,
          toggleDarkMode: _toggleDarkMode,
          title: 'Control de Ventas', // Título específico para esta pantalla
        ),
        body: _isLoadingInicio
            ? Center(
                child:
                    CircularProgressIndicator(), // Muestra el indicador de carga
              )
            : clientes.isEmpty || detalles.isEmpty
                ? Center(
                    child: Text(
                      'No hay datos para mostrar', // Mensaje cuando no hay datos
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.black54), // Estilo del texto
                    ),
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 8),
                              child: TextField(
                                style: TextStyle(fontSize: 14),
                                controller: _searchController,
                                decoration: InputDecoration(
                                  labelText: 'Buscar',
                                  labelStyle: TextStyle(
                                    color: provider.isDarkMode
                                        ? colorTextoClaro
                                        : Colors.grey[
                                            800], // Cambia el color del texto según el modo oscuro
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
                                        color: Colors.grey.shade300,
                                        width: 1.5),
                                  ),
                                  filled: true,
                                  fillColor: provider.isDarkMode
                                      ? colorTextFieldOscuro
                                      : Colors.white, // Color claro o oscuro
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 15, horizontal: 20),
                                  prefixIcon: Icon(
                                    size: 20,
                                    Icons.search, // Icono de lupa
                                    color: provider.isDarkMode
                                        ? colorTextoClaro
                                        : Colors.grey[800],
                                  ),
                                  prefixIconConstraints: BoxConstraints(
                                    minWidth: 50,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              hint: Text('Estado'),
                              value: selectedEstado,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Estado',
                                labelStyle: TextStyle(
                                  color: provider.isDarkMode
                                      ? colorTextoClaro
                                      : Colors.grey[800],
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
                                fillColor: provider.isDarkMode
                                    ? colorTextFieldOscuro
                                    : colorTextFieldClaro, // Cambia el color del texto según el modo oscuro
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 20),
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: provider.isDarkMode
                                    ? colorTextoClaro
                                    : Color(0xFF001F3F),
                              ),
                              dropdownColor: provider.isDarkMode
                                  ? colorTextFieldOscuro
                                  : colorTextFieldClaro, // Ajuste del color del dropdown
                              items: estadosFiltro.map((estado) {
                                return DropdownMenuItem<String>(
                                  value: estado,
                                  child: Text(
                                    estado,
                                    style: TextStyle(
                                        color: provider.isDarkMode
                                            ? colorTextoClaro
                                            : Colors.grey[800],
                                        fontSize: 12),
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
                          SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              hint: Text('Método de Pago'),
                              value: selectedMetodoPago != null &&
                                      tiposPago.contains(selectedMetodoPago)
                                  ? selectedMetodoPago
                                  : null,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Método de Pago',
                                labelStyle: TextStyle(
                                  color: provider.isDarkMode
                                      ? colorTextoClaro
                                      : Colors.grey[800],
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
                                fillColor: provider.isDarkMode
                                    ? colorTextFieldOscuro
                                    : colorTextFieldClaro,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 20),
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: provider.isDarkMode
                                    ? colorTextoClaro
                                    : Color(0xFF001F3F),
                              ),
                              dropdownColor: provider.isDarkMode
                                  ? colorTextFieldOscuro
                                  : colorTextFieldClaro, // Ajuste del color del dropdown
                              items: tiposPago.map((tipo) {
                                return DropdownMenuItem<String>(
                                  value: tipo,
                                  child: Text(
                                    tipo,
                                    style: TextStyle(
                                        color: provider.isDarkMode
                                            ? colorTextoClaro
                                            : Colors.grey[800],
                                        fontSize: 12),
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
                          SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              hint: Text('Factura'),
                              value: selectedFactura != null &&
                                      tiposPago.contains(selectedFactura)
                                  ? selectedFactura
                                  : null,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Factura',
                                labelStyle: TextStyle(
                                  color: provider.isDarkMode
                                      ? colorTextoClaro
                                      : Colors.grey[800],
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
                                fillColor: provider.isDarkMode
                                    ? colorTextFieldOscuro
                                    : colorTextFieldClaro,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 20),
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: provider.isDarkMode
                                    ? colorTextoClaro
                                    : Color(0xFF001F3F),
                              ),
                              dropdownColor: provider.isDarkMode
                                  ? colorTextFieldOscuro
                                  : colorTextFieldClaro,
                              items: facturas.map((factura) {
                                return DropdownMenuItem<String>(
                                  value: factura,
                                  child: Text(
                                    factura,
                                    style: TextStyle(
                                        color: provider.isDarkMode
                                            ? colorTextoClaro
                                            : Colors.grey[800],
                                        fontSize: 12),
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
                          SizedBox(width: 8),
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
                                    builder:
                                        (BuildContext context, Widget? child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: provider.isDarkMode
                                              ? ColorScheme.dark(
                                                  primary: Color(
                                                      0xFF008F8F), // Color principal del DatePicker en modo oscuro
                                                  onPrimary: Colors
                                                      .white, // Color del texto en el DatePicker en modo oscuro
                                                  surface:
                                                      colorTextFieldOscuro, // Fondo del DatePicker en modo oscuro
                                                  onSurface:
                                                      colorTextoClaro, // Color de los textos como los días en modo oscuro
                                                )
                                              : Theme.of(context)
                                                  .colorScheme, // Mantén el esquema de colores predeterminado en modo claro
                                          dialogBackgroundColor: provider
                                                  .isDarkMode
                                              ? Colors.grey[
                                                  850] // Fondo del diálogo en modo oscuro
                                              : Theme.of(context)
                                                  .dialogBackgroundColor, // Fondo predeterminado en modo claro
                                        ),
                                        child: child!,
                                      );
                                    },
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
                                  backgroundColor: provider.isDarkMode
                                      ? colorTextFieldOscuro
                                      : colorTextFieldClaro, // Color de fondo blanco
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
                                    color: provider.isDarkMode
                                        ? colorTextoClaro
                                        : Colors.grey[800],
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            width: 60, // Establecer un ancho fijo
                            height: 50, // Altura fija para el botón
                            child: Tooltip(
                              message:
                                  'Restablecer fecha', // Mensaje del tooltip
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
                                      Icons
                                          .calendar_today, // Ícono de calendario
                                      color: provider.isDarkMode
                                          ? colorTextoClaro
                                          : Colors.grey[
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
                                        color: provider.isDarkMode
                                            ? colorTextoClaro
                                            : Colors.grey[
                                                800], // Color gris oscuro para el ícono de recarga
                                        size:
                                            18, // Tamaño aumentado para mayor visibilidad
                                      ),
                                    ),
                                  ],
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: provider.isDarkMode
                                      ? colorTextFieldOscuro
                                      : colorTextFieldClaro, // Color de fondo blanco
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        30.0), // Bordes redondeados
                                    side: BorderSide(
                                        color:
                                            Colors.grey.shade300), // Marco gris
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 0), // Espaciado vertical
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            width: 60,
                            height: 50,
                            child: Tooltip(
                              message: 'Recargar',
                              child: TextButton(
                                onPressed:
                                    _isLoading // Solo permite presionar si no está cargando
                                        ? null // Deshabilitado si se está cargando
                                        : () {
                                            setState(() {
                                              _isLoading =
                                                  true; // Inicia la carga
                                            });

                                            fetchDatos().then((_) {
                                              setState(() {
                                                _filterDetails(); // Filtra de nuevo para mostrar todos los detalles
                                                _isLoading =
                                                    false; // Termina la carga
                                              });
                                            });
                                          },
                                child: Icon(
                                  Icons.refresh,
                                  color: provider.isDarkMode
                                      ? colorTextoClaro
                                      : Colors.grey[800],
                                  size: 24,
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: provider.isDarkMode
                                      ? colorTextFieldOscuro
                                      : colorTextFieldClaro,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                    side:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 0),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                        ],
                      ),
                      Expanded(
                        child: _isLoading
                            ? Center(
                                child:
                                    CircularProgressIndicator()) // Indicador de carga en el centro
                            : ListView.builder(
                                itemCount: currentItems.length,
                                itemBuilder: (context, index) {
                                  final detalle = currentItems[index];
                                  final folio =
                                      detalle['folio'] ?? 'desconocido';
                                  final isExpanded =
                                      _expandedState[folio] ?? false;

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
                                    gananciaTotal +=
                                        (articulo['ganancia'] ?? 0.0) *
                                            (articulo['cantidad'] ?? 1.0);
                                  }

                                  final controller = _controllers[folio]!;
                                  final animation =
                                      Tween<double>(begin: 0.0, end: 1.0)
                                          .animate(CurvedAnimation(
                                    parent: controller,
                                    curve: Curves.easeInOut,
                                  ));

                                  // Iniciar o detener la animación según el estado expandido
                                  if (isExpanded) {
                                    if (controller.status ==
                                        AnimationStatus.dismissed) {
                                      controller.forward();
                                    }
                                  } else {
                                    if (controller.status ==
                                        AnimationStatus.completed) {
                                      controller.reverse();
                                    }
                                  }

                                  // Calcular el total del precio de compra
                                  double totalCompra = 0.0;
                                  for (var articuloDetalle
                                      in detalle['articulos']) {
                                    totalCompra +=
                                        (articuloDetalle['precio_compra'] ??
                                                0.0) *
                                            (articuloDetalle['cantidad'] ??
                                                1.0);
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
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    color: provider.isDarkMode
                                        ? colorTextFieldOscuro
                                        : colorTextFieldClaro,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 16.0),
                                    elevation: 4,
                                    child: Column(
                                      children: [
                                        ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          title: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  // Cliente y Venta
                                                  Expanded(
                                                    child: Text(
                                                      '${detalle['cliente'] ?? 'Cliente desconocido'} - ${detalle['nombre_venta'] ?? 'Venta sin nombre'}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: provider
                                                                .isDarkMode
                                                            ? colorTextoClaro
                                                            : colorTextoOscuro,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 0,
                                                            horizontal: 8),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(
                                                              _estadoPorFolio[
                                                                      folio] ??
                                                                  estado!)
                                                          .withOpacity(0.09),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              24),
                                                      border: Border.all(
                                                        color: _getStatusColor(
                                                            _estadoPorFolio[
                                                                    folio] ??
                                                                estado!),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 10,
                                                          height: 10,
                                                          decoration:
                                                              BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: _getStatusColor(
                                                                _estadoPorFolio[
                                                                        folio] ??
                                                                    estado!),
                                                          ),
                                                        ),
                                                        SizedBox(width: 4),
                                                        Container(
                                                          constraints:
                                                              BoxConstraints(
                                                                  maxHeight:
                                                                      30),
                                                          child: DropdownButton<
                                                              String>(
                                                            focusNode:
                                                                _focusNode,
                                                            value:
                                                                _estadoPorFolio[
                                                                        folio] ??
                                                                    estado,
                                                            onChanged: (String?
                                                                newValue) async {
                                                              if (newValue !=
                                                                  null) {
                                                                bool
                                                                    actualizado =
                                                                    await actualizarEstado(
                                                                        folio,
                                                                        newValue);
                                                                if (actualizado) {
                                                                  setState(() {
                                                                    _estadoPorFolio[
                                                                            folio] =
                                                                        newValue;
                                                                    fetchDatos();
                                                                  });
                                                                } else {
                                                                  setState(() {
                                                                    _estadoPorFolio[
                                                                            folio] =
                                                                        estado;
                                                                  });
                                                                }
                                                                _focusNode
                                                                    .unfocus(); // Quita el foco al seleccionar un nuevo valor
                                                              }
                                                            },
                                                            items: estados.map<
                                                                DropdownMenuItem<
                                                                    String>>((String
                                                                value) {
                                                              return DropdownMenuItem<
                                                                  String>(
                                                                value: value,
                                                                child: Text(
                                                                  value,
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          12),
                                                                ),
                                                              );
                                                            }).toList(),
                                                            onTap: () {
                                                              FocusScope.of(
                                                                      context)
                                                                  .requestFocus(
                                                                      FocusNode());
                                                            },
                                                            underline:
                                                                SizedBox(),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Divider(), // Añadir un separador
                                              // Cifras con más espaciado y columnas
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  // Columna con los precios
                                                  Expanded(
                                                    child: Wrap(
                                                      spacing: 16,
                                                      runSpacing: 4,
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                                'Precio Compra:',
                                                                style: TextStyle(
                                                                    color: provider
                                                                            .isDarkMode
                                                                        ? colorTextoClaro
                                                                        : colorTextoOscuro,
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                            Text(
                                                                '\$${formatAmount(totalCompra)}',
                                                                style: TextStyle(
                                                                    color: provider
                                                                            .isDarkMode
                                                                        ? colorTextoClaro
                                                                        : colorTextoOscuro,
                                                                    fontSize:
                                                                        14)),
                                                          ],
                                                        ),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                                'Ganancia Total:',
                                                                style: TextStyle(
                                                                    color: provider
                                                                            .isDarkMode
                                                                        ? colorTextoClaro
                                                                        : colorTextoOscuro,
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                            Text(
                                                                '\$${formatAmount(gananciaTotal)}',
                                                                style: TextStyle(
                                                                    color: provider
                                                                            .isDarkMode
                                                                        ? colorTextoClaro
                                                                        : colorTextoOscuro,
                                                                    fontSize:
                                                                        14)),
                                                          ],
                                                        ),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text('Subtotal:',
                                                                style: TextStyle(
                                                                    color: provider
                                                                            .isDarkMode
                                                                        ? colorTextoClaro
                                                                        : colorTextoOscuro,
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                            Text(
                                                                '\$${formatAmount(detalle['subtotal'] ?? '0.00')}',
                                                                style: TextStyle(
                                                                    color: provider
                                                                            .isDarkMode
                                                                        ? colorTextoClaro
                                                                        : colorTextoOscuro,
                                                                    fontSize:
                                                                        14)),
                                                          ],
                                                        ),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text('IVA:',
                                                                style: TextStyle(
                                                                    color: provider
                                                                            .isDarkMode
                                                                        ? colorTextoClaro
                                                                        : colorTextoOscuro,
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                            Text(
                                                                '\$${formatAmount(detalle['iva'] ?? '0.00')}',
                                                                style: TextStyle(
                                                                    color: provider
                                                                            .isDarkMode
                                                                        ? colorTextoClaro
                                                                        : colorTextoOscuro,
                                                                    fontSize:
                                                                        14)),
                                                          ],
                                                        ),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text('Total:',
                                                                style: TextStyle(
                                                                    color: provider
                                                                            .isDarkMode
                                                                        ? colorTextoClaro
                                                                        : colorTextoOscuro,
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                            Text(
                                                              '\$${formatAmount(detalle['total'] ?? '0.00')}',
                                                              style: TextStyle(
                                                                color: provider
                                                                        .isDarkMode
                                                                    ? colorTextoClaro
                                                                    : colorTextoOscuro,
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
                                                                esCortaMap[
                                                                        index] =
                                                                    !esCortaMap[
                                                                        index]!;
                                                              });

                                                              // Regresar al formato corto después de unos segundos.
                                                              Future.delayed(
                                                                  Duration(
                                                                      seconds:
                                                                          2),
                                                                  () {
                                                                setState(() {
                                                                  esCortaMap[
                                                                          index] =
                                                                      true;
                                                                });
                                                              });
                                                            },
                                                            child:
                                                                AnimatedSwitcher(
                                                              duration: Duration(
                                                                  milliseconds:
                                                                      300),
                                                              child: Text(
                                                                esCortaMap[
                                                                        index]! // Obtiene el estado de este elemento.
                                                                    ? formatDateCorta(DateTime.parse(
                                                                        detalle[
                                                                            'fecha_creacion']))
                                                                    : formatDateLarga(
                                                                        DateTime.parse(
                                                                            detalle['fecha_creacion'])),
                                                                key: ValueKey<
                                                                        bool>(
                                                                    esCortaMap[
                                                                        index]!),
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: provider
                                                                          .isDarkMode
                                                                      ? colorTextoClaro
                                                                      : colorTextoOscuro,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: 12),
                                                          Text(
                                                            'Folio: $folio',
                                                            style: TextStyle(
                                                              color: provider
                                                                      .isDarkMode
                                                                  ? Color(
                                                                      0xFF00CCDD)
                                                                  : Color(
                                                                      0xFF008F8F),
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
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
                                            color: provider.isDarkMode
                                                ? Colors.white
                                                : Colors.grey[700],
                                          ),
                                          onTap: () {
                                            setState(() {
                                              if (isExpanded) {
                                                _expandedState.remove(folio);
                                              } else {
                                                _expandedState
                                                    .forEach((key, value) {
                                                  if (value)
                                                    _expandedState[key] = false;
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
                                            color: provider.isDarkMode
                                                ? colorTextFieldOscuro
                                                : colorTextFieldClaro,
                                            child: isExpanded
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
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
                                                          .map<Widget>(
                                                              (articuloDetalle) {
                                                        return Card(
                                                          color: provider
                                                                  .isDarkMode
                                                              ? Color.fromARGB(
                                                                  255,
                                                                  62,
                                                                  83,
                                                                  110)
                                                              : Colors
                                                                  .grey[100],
                                                          margin:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 4.0,
                                                                  horizontal:
                                                                      8.0),
                                                          elevation: 2,
                                                          child: ListTile(
                                                            contentPadding:
                                                                EdgeInsets.symmetric(
                                                                    vertical: 2,
                                                                    horizontal:
                                                                        16.0),
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
                                                                            color: provider.isDarkMode
                                                                                ? colorTextoClaro
                                                                                : colorTextoOscuro,
                                                                            fontSize:
                                                                                14,
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                      ),
                                                                      Padding(
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                25),
                                                                        child:
                                                                            Text(
                                                                          '${articuloDetalle['cantidad'] ?? '0'}',
                                                                          style:
                                                                              TextStyle(
                                                                            fontSize:
                                                                                14,
                                                                            color: provider.isDarkMode
                                                                                ? colorTextoClaro
                                                                                : colorTextoOscuro,
                                                                          ),
                                                                          textAlign:
                                                                              TextAlign.center,
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
                                                                            color: provider.isDarkMode
                                                                                ? colorTextoClaro
                                                                                : colorTextoOscuro,
                                                                            fontSize:
                                                                                14,
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                        textAlign:
                                                                            TextAlign.left, // Alinea a la izquierda
                                                                      ),
                                                                      Text(
                                                                        '${articuloDetalle['descripcion'] ?? 'Desconocido'}',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color: provider.isDarkMode
                                                                              ? colorTextoClaro
                                                                              : colorTextoOscuro,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.left, // Alinea a la izquierda
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
                                                                            color: provider.isDarkMode
                                                                                ? colorTextoClaro
                                                                                : colorTextoOscuro,
                                                                            fontSize:
                                                                                14,
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                      ),
                                                                      Text(
                                                                        '\$${formatAmount(articuloDetalle['precio_compra'] ?? '0.00')}',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color: provider.isDarkMode
                                                                              ? colorTextoClaro
                                                                              : colorTextoOscuro,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.center,
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
                                                                            color: provider.isDarkMode
                                                                                ? colorTextoClaro
                                                                                : colorTextoOscuro,
                                                                            fontSize:
                                                                                14,
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                      ),
                                                                      Text(
                                                                        '${articuloDetalle['porcentaje'] ?? '0.00'}%',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color: provider.isDarkMode
                                                                              ? colorTextoClaro
                                                                              : colorTextoOscuro,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.center,
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
                                                                            color: provider.isDarkMode
                                                                                ? colorTextoClaro
                                                                                : colorTextoOscuro,
                                                                            fontSize:
                                                                                14,
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                      ),
                                                                      Text(
                                                                        // Validamos que cantidad no sea 0 para evitar divisiones por 0
                                                                        '\$${formatAmount((articuloDetalle['ganancia'] != null && articuloDetalle['cantidad'] != null && articuloDetalle['cantidad'] != 0) ? (articuloDetalle['ganancia'] / articuloDetalle['cantidad']) : '0.00')}',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color: provider.isDarkMode
                                                                              ? colorTextoClaro
                                                                              : colorTextoOscuro,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.center,
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
                                                                            color: provider.isDarkMode
                                                                                ? colorTextoClaro
                                                                                : colorTextoOscuro,
                                                                            fontSize:
                                                                                14,
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                      ),
                                                                      Text(
                                                                        '\$${formatAmount(((double.tryParse(articuloDetalle['ganancia']?.toString() ?? '0') ?? 0)))}',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color: provider.isDarkMode
                                                                              ? colorTextoClaro
                                                                              : colorTextoOscuro,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.center,
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
                                                                            color: provider.isDarkMode
                                                                                ? colorTextoClaro
                                                                                : colorTextoOscuro,
                                                                            fontSize:
                                                                                14,
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                      ),
                                                                      Text(
                                                                        '\$${formatAmount(articuloDetalle['precio_venta'] ?? '0.00')}',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color: provider.isDarkMode
                                                                              ? colorTextoClaro
                                                                              : colorTextoOscuro,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.center,
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
                                                                            color: provider.isDarkMode
                                                                                ? colorTextoClaro
                                                                                : colorTextoOscuro,
                                                                            fontSize:
                                                                                14,
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                      ),
                                                                      Text(
                                                                        '\$${formatAmount((articuloDetalle['precio_venta'] ?? 0) * (articuloDetalle['cantidad'] ?? 0))}',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color: provider.isDarkMode
                                                                              ? colorTextoClaro
                                                                              : colorTextoOscuro,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.center,
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
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 8.0,
                                                                horizontal:
                                                                    16.0),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween, // Espacio entre elementos
                                                          children: [
                                                            Row(
                                                              // Elementos de la izquierda
                                                              children: [
                                                                Text(
                                                                  'Subtotal:',
                                                                  style:
                                                                      TextStyle(
                                                                    color: provider
                                                                            .isDarkMode
                                                                        ? colorTextoClaro
                                                                        : colorTextoOscuro,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    width: 10),
                                                                Text(
                                                                  '\$${formatAmount(detalle['subtotal'] ?? '0.00')}',
                                                                  style:
                                                                      TextStyle(
                                                                    color: provider
                                                                            .isDarkMode
                                                                        ? colorTextoClaro
                                                                        : colorTextoOscuro,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              // Elementos nuevos a la derecha
                                                              children: [
                                                                Text(
                                                                  'Método de pago:',
                                                                  style:
                                                                      TextStyle(
                                                                    color: provider
                                                                            .isDarkMode
                                                                        ? colorTextoClaro
                                                                        : colorTextoOscuro,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    width: 10),
                                                                Text(
                                                                  detalle['tipo_pago'] ??
                                                                      'No disponible',
                                                                  style:
                                                                      TextStyle(
                                                                    color: provider
                                                                            .isDarkMode
                                                                        ? colorTextoClaro
                                                                        : colorTextoOscuro,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 8.0,
                                                                horizontal:
                                                                    16.0),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween, // Espacio entre elementos
                                                          children: [
                                                            Row(
                                                              // Elementos de la izquierda
                                                              children: [
                                                                Text(
                                                                  'IVA:',
                                                                  style:
                                                                      TextStyle(
                                                                    color: provider
                                                                            .isDarkMode
                                                                        ? colorTextoClaro
                                                                        : colorTextoOscuro,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    width: 10),
                                                                Text(
                                                                  '\$${formatAmount(detalle['iva'] ?? '0.00')}',
                                                                  style:
                                                                      TextStyle(
                                                                    color: provider
                                                                            .isDarkMode
                                                                        ? colorTextoClaro
                                                                        : colorTextoOscuro,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              // Elementos nuevos a la derecha
                                                              children: [
                                                                Text(
                                                                  'Factura:',
                                                                  style:
                                                                      TextStyle(
                                                                    color: provider
                                                                            .isDarkMode
                                                                        ? colorTextoClaro
                                                                        : colorTextoOscuro,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    width: 10),
                                                                Text(
                                                                  detalle[
                                                                      'factura'],
                                                                  style:
                                                                      TextStyle(
                                                                    color: provider
                                                                            .isDarkMode
                                                                        ? colorTextoClaro
                                                                        : colorTextoOscuro,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                top: 8,
                                                                bottom: 8,
                                                                left: 16,
                                                                right: 0),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween, // Espacio entre elementos
                                                          children: [
                                                            Row(
                                                              // Elementos de la izquierda
                                                              children: [
                                                                Text(
                                                                  'Total:',
                                                                  style:
                                                                      TextStyle(
                                                                    color: provider
                                                                            .isDarkMode
                                                                        ? colorTextoClaro
                                                                        : colorTextoOscuro,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    width: 10),
                                                                Text(
                                                                  '\$${formatAmount(detalle['total'] ?? '0.00')}',
                                                                  style:
                                                                      TextStyle(
                                                                    color: provider
                                                                            .isDarkMode
                                                                        ? colorTextoClaro
                                                                        : colorTextoOscuro,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              // Elementos nuevos a la derecha
                                                              children: [
                                                                TextButton(
                                                                  onPressed:
                                                                      () {
                                                                    mostrarConfirmacionEliminar(
                                                                        provider,
                                                                        colorFondoClaro,
                                                                        colorTextoOscuro,
                                                                        colorTextoClaro,
                                                                        context,
                                                                        detalle[
                                                                            'folio'],
                                                                        detalles,
                                                                        setState);
                                                                    // Aquí puedes agregar la lógica para eliminar
                                                                    print(
                                                                        'Eliminar item');
                                                                  },
                                                                  style: TextButton
                                                                      .styleFrom(
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8),
                                                                    ),
                                                                  ),
                                                                  child: Icon(
                                                                    Icons
                                                                        .delete,
                                                                    color: provider.isDarkMode
                                                                        ? Colors
                                                                            .white
                                                                        : Color(
                                                                            0xFFB8001F),
                                                                    size:
                                                                        24, // Tamaño del icono
                                                                  ),
                                                                ),
                                                                TextButton(
                                                                  onPressed:
                                                                      () async {
                                                                    // Asegúrate de que el cliente existe
                                                                    if (cliente !=
                                                                        null) {
                                                                      // Crea un nuevo mapa que incluya los detalles del cliente
                                                                      Map<String,
                                                                              dynamic>
                                                                          pdfData =
                                                                          {
                                                                        ...detalle,
                                                                        'telefono':
                                                                            cliente['telefono'] ??
                                                                                'No disponible',
                                                                        'email':
                                                                            cliente['email'] ??
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
                                                                          BorderRadius.circular(
                                                                              8),
                                                                    ),
                                                                  ),
                                                                  child: Icon(
                                                                    Icons
                                                                        .picture_as_pdf,
                                                                    color: provider.isDarkMode
                                                                        ? Colors
                                                                            .white
                                                                        : Color(
                                                                            0xFFB8001F),
                                                                    // Cambia el color del icono si lo deseas
                                                                    size:
                                                                        24, // Tamaño del icono
                                                                  ),
                                                                ),
                                                                // Botón para editar la venta
                                                                TextButton(
                                                                  onPressed:
                                                                      () {
                                                                    mostrarDialogoEdicion(
                                                                        context,
                                                                        provider,
                                                                        detalle,
                                                                        colorTextFieldClaro,
                                                                        colorTextFieldOscuro,
                                                                        colorFondoClaro,
                                                                        colorFondoOscuro,
                                                                        colorTextoOscuro,
                                                                        colorTextoClaro);
                                                                  },
                                                                  child: Icon(
                                                                    Icons.edit,
                                                                    color: provider.isDarkMode
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .blue, // Cambia el color si lo deseas
                                                                    size: 24,
                                                                  ),
                                                                ),
                                                                TextButton(
                                                                  onPressed:
                                                                      () {
                                                                    // Llamas a la función para mostrar el diálogo, pasando el contexto, los detalles y el folio
                                                                    mostrarDetallesEstado(
                                                                        context,
                                                                        provider,
                                                                        detalle[
                                                                            'estados'],
                                                                        detalle[
                                                                            'folio'],
                                                                        colorTextFieldClaro,
                                                                        colorTextFieldOscuro,
                                                                        colorFondoClaro,
                                                                        colorFondoOscuro,
                                                                        colorTextoOscuro,
                                                                        colorTextoClaro);
                                                                    setState(
                                                                        () {
                                                                      //fetchDatos();
                                                                    });
                                                                  },
                                                                  child: Text(
                                                                    'Ver detalles del estado',
                                                                    style:
                                                                        TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          14,
                                                                      color: provider
                                                                              .isDarkMode
                                                                          ? Color(
                                                                              0xFF00CCDD)
                                                                          : Color(
                                                                              0xFF008F8F),
                                                                    ),
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

  Future<void> eliminarVenta(String folio, List<dynamic> detalles,
      Function setState, BuildContext context) async {
    final url = Uri.parse('https://codtix.vercel.app/api/v1/detalles/$folio');

    try {
      setState(() {
        isDeleting = true; // Inicia el estado de cargando
      });

      final response = await http.delete(url);

      if (response.statusCode == 200) {
        print('Venta eliminada exitosamente');
        setState(() {
          detalles.removeWhere((detalle) => detalle['folio'] == folio);
        });

        // Mostrar SnackBar después de eliminar correctamente
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Venta eliminada correctamente'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );

        // Recargar los datos después de eliminar
        fetchDatos();
      } else {
        // Extraer el código y mensaje del servidor
        final int codigo = response.statusCode;
        final Map<String, dynamic> errorResponse = jsonDecode(response.body);
        final String mensaje = errorResponse['Error']['Message'];

        // Mostrar SnackBar con código y mensaje
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código: $codigo\nMensaje: $mensaje'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error al eliminar la venta: $e');
      // Mostrar SnackBar en caso de excepción
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isDeleting = false; // Termina el estado de cargando
      });
    }
  }

  void mostrarConfirmacionEliminar(
      provider,
      colorFondoClaro,
      colorTextoOscuro,
      colorTextoClaro,
      BuildContext context,
      String folio,
      List<dynamic> detalles,
      Function setState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: provider.isDarkMode
                  ? Color.fromARGB(255, 18, 41, 66)
                  : colorFondoClaro,
              title: Text('Confirmar eliminación'),
              content: isDeleting
                  ? SizedBox(
                      height:
                          50, // Fija la altura del CircularProgressIndicator
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Text('¿Estás seguro de que deseas eliminar esta venta?'),
              actions: isDeleting
                  ? [] // No mostrar botones mientras está cargando
                  : <Widget>[
                      TextButton(
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: provider.isDarkMode
                                ? colorTextoClaro
                                : Colors.red,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(); // Cerrar el diálogo
                        },
                      ),
                      TextButton(
                        child: Text('Eliminar',
                            style: TextStyle(
                              color: provider.isDarkMode
                                  ? colorTextoClaro
                                  : Color(0xFF008F8F),
                            )),
                        onPressed: () async {
                          // Ejecutar la función para eliminar la venta y actualizar la lista local
                          await eliminarVenta(
                              folio, detalles, setState, context);
                          Navigator.of(context)
                              .pop(); // Cerrar el diálogo después de eliminar
                        },
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  void mostrarDialogoEdicion(
      BuildContext context,
      provider,
      Map<String, dynamic> detalleOriginal,
      colorTextFieldClaro,
      colorTextFieldOscuro,
      colorFondoClaro,
      colorFondoOscuro,
      colorTextoOscuro,
      colorTextoClaro) {
    // Crear una copia profunda del 'detalle' original.
    Map<String, dynamic> detalle = deepCopy(detalleOriginal);

    // Crear los controladores fuera del builder para evitar recrearlos constantemente
    TextEditingController nombreVentaController =
        TextEditingController(text: detalle['nombre_venta']);
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
      tipoProductoControllers
          .add(TextEditingController(text: articulo['tipo']));
      cantidadControllers
          .add(TextEditingController(text: articulo['cantidad'].toString()));
      descripcionControllers
          .add(TextEditingController(text: articulo['descripcion']));
      precioCompraControllers.add(
          TextEditingController(text: articulo['precio_compra'].toString()));
      porcentajeGananciaControllers
          .add(TextEditingController(text: articulo['porcentaje'].toString()));
    }

    // Cálculo de valores iniciales
    calcularTotales(
        detalle, subtotalController, ivaController, totalController);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? facturaSeleccionada = detalle['factura'];
        String? tipoPagoSeleccionado = detalle['tipo_pago'];
        String cliente = detalle['cliente'];
        String folio = detalle['folio'];

        return StatefulBuilder(
          builder: (context, setState) {
            return Stack(children: [
              AlertDialog(
                backgroundColor: provider.isDarkMode
                    ? Color.fromARGB(255, 18, 41, 66)
                    : colorFondoClaro,
                title: Text(
                  "Editar Artículos",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: provider.isDarkMode
                        ? colorTextoClaro
                        : colorTextoOscuro,
                  ),
                ),
                content: Container(
                  width: MediaQuery.of(context).size.width *
                      0.5, // 80% del ancho de la pantalla
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Modifica los artículos y los valores se actualizarán automáticamente.',
                              style: TextStyle(
                                  color: provider.isDarkMode
                                      ? colorTextoClaro
                                      : Colors.grey[700],
                                  fontSize: 14),
                            ),
                          ],
                        ),
                        Divider(height: 20, color: Colors.grey[300]),
                        Row(
                          children: [
                            // Campo deshabilitado para el nombre del cliente
                            Expanded(
                              child: _buildTextFieldDisabled(
                                colorTextFieldClaro,
                                colorTextFieldOscuro,
                                colorFondoClaro,
                                colorFondoOscuro,
                                colorTextoOscuro,
                                colorTextoClaro,
                                label: 'Cliente',
                                value: cliente,
                              ),
                            ),
                            SizedBox(width: 10), // Espacio entre los campos

                            // Campo deshabilitado para el folio
                            Expanded(
                              child: _buildTextFieldDisabled(
                                colorTextFieldClaro,
                                colorTextFieldOscuro,
                                colorFondoClaro,
                                colorFondoOscuro,
                                colorTextoOscuro,
                                colorTextoClaro,
                                label: 'Folio',
                                value: folio,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        // Campo para nombre_venta
                        _buildTextFieldValidator(
                          colorTextFieldClaro,
                          colorTextFieldOscuro,
                          colorFondoClaro,
                          colorFondoOscuro,
                          colorTextoOscuro,
                          colorTextoClaro,
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
                                colorTextFieldClaro,
                                colorTextFieldOscuro,
                                colorFondoClaro,
                                colorFondoOscuro,
                                colorTextoOscuro,
                                colorTextoClaro,
                                label: 'Factura',
                                value: facturaSeleccionada,
                                items: ['Si', 'No'],
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
                                colorTextFieldClaro,
                                colorTextFieldOscuro,
                                colorFondoClaro,
                                colorFondoOscuro,
                                colorTextoOscuro,
                                colorTextoClaro,
                                label: 'Tipo de Pago',
                                value: tipoPagoSeleccionado,
                                items: [
                                  'Efectivo',
                                  'Transferencia',
                                  'No asignado'
                                ],
                                onChanged: (String? newValue) {
                                  setState(() {
                                    tipoPagoSeleccionado = newValue!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 10),
                        Divider(height: 20, color: Colors.grey[300]),

                        // Mostrar los artículos con sus controladores asignados
                        ...detalle['articulos']
                            .asMap()
                            .entries
                            .map<Widget>((entry) {
                          int index = entry.key;
                          var articulo = entry.value;

                          // Variables para almacenar los resultados calculados
                          double precioVentaUnitario = 0.0;
                          double precioVentaTotal = 0.0;
                          double gananciaPp = 0.0;
                          double gananciaTotal = 0.0;

                          // Función que recalcula los valores cuando se cambia algún campo
                          void recalcularValores() {
                            int cantidad =
                                int.tryParse(cantidadControllers[index].text) ??
                                    0;
                            double precioCompra = double.tryParse(
                                    precioCompraControllers[index].text) ??
                                0.0;
                            double porcentajeGanancia = double.tryParse(
                                    porcentajeGananciaControllers[index]
                                        .text) ??
                                0.0;

                            // Cálculo del precio de venta unitario
                            precioVentaUnitario = precioCompra +
                                (precioCompra * (porcentajeGanancia / 100));
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
                            color: provider.isDarkMode
                                ? Color.fromARGB(255, 19, 37, 61)
                                : colorFondoClaro,
                            elevation: 2,
                            margin: EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                                side:
                                    BorderSide(width: 0.5, color: Colors.grey),
                                borderRadius: BorderRadius.circular(10)),
                            child: Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Producto: ${articulo['descripcion']}',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTipoProductoDropdown(
                                          colorTextFieldClaro,
                                          colorTextFieldOscuro,
                                          colorFondoClaro,
                                          colorFondoOscuro,
                                          colorTextoOscuro,
                                          colorTextoClaro,
                                          label: 'Tipo Producto',
                                          value: tipoProductoControllers[index]
                                                  .text
                                                  .isEmpty
                                              ? null
                                              : tipoProductoControllers[index]
                                                  .text, // Verificar si el controlador está vacío
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              tipoProductoControllers[index]
                                                  .text = newValue!;
                                            });
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: _buildTextFieldValidator(
                                          colorTextFieldClaro,
                                          colorTextFieldOscuro,
                                          colorFondoClaro,
                                          colorFondoOscuro,
                                          colorTextoOscuro,
                                          colorTextoClaro,
                                          controller:
                                              cantidadControllers[index],
                                          label: 'Cantidad',
                                          inputType: TextInputType.number,
                                          onChanged: (value) {
                                            // Actualizar el detalle con el nuevo valor de cantidad
                                            detalle['articulos'][index]
                                                    ['cantidad'] =
                                                int.tryParse(value!) ?? 0;

                                            // Recalcular los valores individuales y totales
                                            recalcularValores();
                                            calcularTotales(
                                                detalle,
                                                subtotalController,
                                                ivaController,
                                                totalController);
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
                                          colorTextFieldClaro,
                                          colorTextFieldOscuro,
                                          colorFondoClaro,
                                          colorFondoOscuro,
                                          colorTextoOscuro,
                                          colorTextoClaro,
                                          controller:
                                              descripcionControllers[index],
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
                                          colorTextFieldClaro,
                                          colorTextFieldOscuro,
                                          colorFondoClaro,
                                          colorFondoOscuro,
                                          colorTextoOscuro,
                                          colorTextoClaro,
                                          controller:
                                              precioCompraControllers[index],
                                          label: 'Precio Compra',
                                          inputType: TextInputType.number,
                                          onChanged: (value) {
                                            recalcularValores();
                                            // Cálculo de valores iniciales
                                            calcularTotales(
                                                detalle,
                                                subtotalController,
                                                ivaController,
                                                totalController);
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: _buildTextFieldValidator(
                                          colorTextFieldClaro,
                                          colorTextFieldOscuro,
                                          colorFondoClaro,
                                          colorFondoOscuro,
                                          colorTextoOscuro,
                                          colorTextoClaro,
                                          controller:
                                              porcentajeGananciaControllers[
                                                  index],
                                          label: '% Ganancia',
                                          inputType: TextInputType.number,
                                          onChanged: (value) {
                                            recalcularValores();
                                            // Cálculo de valores iniciales
                                            calcularTotales(
                                                detalle,
                                                subtotalController,
                                                ivaController,
                                                totalController);
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
                                          'Precio Venta (Unitario): ${formatAmount(precioVentaUnitario)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Precio Venta (Total): ${formatAmount(precioVentaTotal)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                            'Ganancia por Producto: ${formatAmount(gananciaPp)}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Expanded(
                                        child: Text(
                                            'Ganancia Total: ${formatAmount(gananciaTotal)}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        // Botón para agregar un nuevo artículo vacío
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              // Agregar un nuevo artículo vacío a la lista de detalle
                              detalle['articulos'].add({
                                'tipo': null, // Tipo inicializado como null
                                'cantidad': 0,
                                'descripcion': '',
                                'precio_compra': 0.0,
                                'porcentaje': 0.0,
                                'precio_venta': 0.0,
                                'ganancia': 0.0,
                              });

                              // Inicializar los controladores para el nuevo artículo
                              tipoProductoControllers
                                  .add(TextEditingController());
                              cantidadControllers.add(TextEditingController());
                              descripcionControllers
                                  .add(TextEditingController());
                              precioCompraControllers
                                  .add(TextEditingController());
                              porcentajeGananciaControllers
                                  .add(TextEditingController());
                            });
                          },
                          child: Text('Agregar Artículo'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: provider.isDarkMode
                                ? Colors.white
                                : Colors.white,
                            backgroundColor: provider.isDarkMode
                                ? Color(0xFF008f8f)
                                : Color(
                                    0xFF008f8f), // Color del texto según el modo
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  20), // Bordes redondeados
                            ),
                          ),
                        ),

                        Divider(height: 20, color: Colors.grey[300]),
                        _buildResumenTotal(
                          'Subtotal',
                          subtotalController.text,
                          colorTextFieldClaro,
                          colorTextFieldOscuro,
                          colorFondoClaro,
                          colorFondoOscuro,
                          colorTextoOscuro,
                          colorTextoClaro,
                        ),
                        _buildResumenTotal(
                          'IVA',
                          ivaController.text,
                          colorTextFieldClaro,
                          colorTextFieldOscuro,
                          colorFondoClaro,
                          colorFondoOscuro,
                          colorTextoOscuro,
                          colorTextoClaro,
                        ),
                        _buildResumenTotal(
                          'Total',
                          totalController.text,
                          colorTextFieldClaro,
                          colorTextFieldOscuro,
                          colorFondoClaro,
                          colorFondoOscuro,
                          colorTextoOscuro,
                          colorTextoClaro,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child:
                        Text("Cancelar", style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  // En la función de guardar
                  ElevatedButton(
                    child:
                        Text("Guardar", style: TextStyle(color: Colors.white)),
                    onPressed: _isEditing
                        ? null // Deshabilita el botón mientras se está cargando
                        : () async {
                            // Verificar si se han editado los datos
                            bool isEdited = false;

                            // Comprobar si hay cambios en los campos
                            if (nombreVentaController.text !=
                                    detalle['nombre_venta'] ||
                                facturaSeleccionada != detalle['factura'] ||
                                tipoPagoSeleccionado != detalle['tipo_pago']) {
                              isEdited = true;
                            }

                            for (int i = 0;
                                i < detalleOriginal['articulos'].length;
                                i++) {
                              int cantidadOriginal =
                                  detalleOriginal['articulos'][i]['cantidad'];
                              int cantidadNueva =
                                  int.tryParse(cantidadControllers[i].text) ??
                                      0;

                              // Imprimir los valores para depuración
                              print('Cantidad original: $cantidadOriginal');
                              print('Cantidad nueva: $cantidadNueva');

                              if (cantidadNueva != cantidadOriginal) {
                                isEdited = true;
                                break; // Salir del bucle si ya se encontró un cambio
                              }
                            }

                            for (int i = 0;
                                i < detalle['articulos'].length;
                                i++) {
                              if (tipoProductoControllers[i].text !=
                                      detalle['articulos'][i]['tipo'] ||
                                  cantidadControllers[i].text !=
                                      detalle['articulos'][i]['cantidad']
                                          .toString() ||
                                  descripcionControllers[i].text !=
                                      detalle['articulos'][i]['descripcion'] ||
                                  precioCompraControllers[i].text !=
                                      detalle['articulos'][i]['precio_compra']
                                          .toString() ||
                                  porcentajeGananciaControllers[i].text !=
                                      detalle['articulos'][i]['porcentaje']
                                          .toString()) {
                                isEdited = true;
                                break; // Salir del bucle si ya se encontró un cambio
                              }
                            }

                            // Si no se han hecho cambios, mostrar un alert dialog
                            // Si no se han hecho cambios, mostrar un alert dialog
                            if (!isEdited) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text("No se Detectaron Cambios"),
                                    content: Text(
                                        "Parece que no has realizado ninguna modificación en los datos. Por favor, edita los campos necesarios antes de guardar."),
                                    actions: [
                                      TextButton(
                                        child: Text("Entendido"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                              return; // Salir de la función si no hay cambios
                            }

                            setState(() {
                              _isEditing = true; // Inicia el estado de carga
                            });

                            // Actualizar `detalle` con los valores actuales de los controladores
                            detalle['nombre_venta'] =
                                nombreVentaController.text;
                            detalle['factura'] = facturaSeleccionada;
                            detalle['tipo_pago'] = tipoPagoSeleccionado;

                            // Lista para almacenar IDs de nuevos artículos
                            List<String> nuevosArticuloIds = [];

                            // Actualizar cada artículo con los controladores correspondientes
                            for (int i = 0;
                                i < detalle['articulos'].length;
                                i++) {
                              detalle['articulos'][i]['tipo'] =
                                  tipoProductoControllers[i].text;
                              detalle['articulos'][i]['cantidad'] =
                                  int.tryParse(cantidadControllers[i].text) ??
                                      0;
                              detalle['articulos'][i]['descripcion'] =
                                  descripcionControllers[i].text;
                              detalle['articulos'][i]['precio_compra'] =
                                  double.tryParse(
                                          precioCompraControllers[i].text) ??
                                      0.0;
                              detalle['articulos'][i]
                                  ['porcentaje'] = double.tryParse(
                                      porcentajeGananciaControllers[i].text) ??
                                  0.0;

                              // Verificar si el artículo tiene idarticulo; si no, será un nuevo artículo
                              if (detalle['articulos'][i]['idarticulo'] ==
                                  null) {
                                // Guardar el artículo y obtener su ID
                                List<String> nuevoArticuloIds =
                                    await _guardararticulo(
                                        context, [detalle['articulos'][i]]);
                                if (nuevoArticuloIds.isNotEmpty) {
                                  detalle['articulos'][i]['idarticulo'] =
                                      nuevoArticuloIds
                                          .first; // Asignar el primer ID
                                  nuevosArticuloIds.add(nuevoArticuloIds.first);
                                }
                              }
                            }

                            // Calcular subtotal, iva, total si es necesario
                            double subtotal = 0;
                            for (var articulo in detalle['articulos']) {
                              subtotal += articulo['precio_venta'] *
                                  articulo['cantidad'];
                            }
                            double iva = subtotal * 0.16;
                            double total = subtotal + iva;

                            detalle['subtotal'] = subtotal;
                            detalle['iva'] = iva;
                            detalle['total'] = total;

                            // Llamar a la función actualizarVenta
                            await actualizarVenta(context, folio, detalle);

                            // Actualizar el detalle original
                            detalleOriginal.addAll(detalle);

                            // Cerrar el diálogo
                            Navigator.of(context).pop();

                            setState(() {
                              _isEditing = false; // Termina el estado de carga
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF008f8f),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
              // Fondo oscuro
              // Fondo semitransparente en toda la pantalla cuando se está cargando
              if (_isEditing)
                Positioned.fill(
                  child: Container(
                    color:
                        Colors.black.withOpacity(0.3), // Oscurece todo el fondo
                  ),
                ),
              // CircularProgressIndicator centrado sobre el fondo oscuro
              if (_isEditing)
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20)),
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ]);
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
        return MapEntry(
            key,
            List.from(value.map((item) =>
                item is Map<String, dynamic> ? deepCopy(item) : item)));
      } else {
        return MapEntry(key, value);
      }
    });
  }

  Future<List<String>> _guardararticulo(
      BuildContext context, List<dynamic> articulos) async {
    List<String> articuloIds = [];
    // Verifica si los artículos tienen un tipo válido
    for (var item in articulos) {
      if (item['tipo'] == null || item['tipo'].isEmpty) {
        print(
            'Error: El tipo del artículo "${item['descripcion']}" está vacío.');
        return [];
      }
    }

    // Construye el cuerpo del POST
    final body = articulos.map((item) {
      return {
        'descripcion': item['descripcion'],
        'tipo': item['tipo'],
        'precio_compra': item['precio_compra'].toString(),
      };
    }).toList();

    // Asegúrate de que el cuerpo es un objeto JSON válido
    print('Cuerpo del POST para artículos: ${json.encode(body)}');

    // Hacer el POST request
    final response = await http.post(
      Uri.parse('https://$baseUrl/api/v1/articulos/agregar'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      articuloIds = List<String>.from(responseData['id']);
      print('Artículos guardados con éxito: $articuloIds');
      return articuloIds; // Devuelve los IDs de los artículos guardados
    } else {
      print('Error al guardar los artículos: ${response.body}');
      return [];
    }
  }

  Future<void> actualizarVenta(
      BuildContext context, String folio, Map<String, dynamic> detalle) async {
    setState(() {
      _isEditing = true; // Inicia el estado de edición
    });

    final url = Uri.parse('https://$baseUrl/api/v1/ventas/editar/$folio');
    List<Map<String, dynamic>> articulosParaEnviar =
        detalle["articulos"].map<Map<String, dynamic>>((articulo) {
      if (articulo.containsKey("idarticulo") &&
          articulo["idarticulo"] != null) {
        return {
          "idarticulo": articulo["idarticulo"],
          "tipo": articulo["tipo"] ?? "Producto",
          "cantidad": articulo["cantidad"] ?? 1,
          "ganancia": articulo["ganancia"] ?? 0.0,
          "porcentaje": articulo["porcentaje"] ?? 0.0,
          "descripcion":
              articulo["descripcion"] ?? "Descripción no especificada",
          "precio_venta": articulo["precio_venta"] ?? 0.0,
          "precio_compra": articulo["precio_compra"] ?? 0.0,
        };
      } else {
        return {
          "tipo": articulo["tipo"] ?? "Producto",
          "cantidad": articulo["cantidad"] ?? 1,
          "ganancia": articulo["ganancia"] ?? 0.0,
          "porcentaje": articulo["porcentaje"] ?? 0.0,
          "descripcion":
              articulo["descripcion"] ?? "Descripción no especificada",
          "precio_venta": articulo["precio_venta"] ?? 0.0,
          "precio_compra": articulo["precio_compra"] ?? 0.0,
        };
      }
    }).toList();

    Map<String, dynamic> body = {
      "nombre_venta": detalle["nombre_venta"] ?? "Venta sin nombre",
      "factura": detalle["factura"] ?? "No",
      "tipo_pago": detalle["tipo_pago"] ?? "Efectivo",
      "articulos": articulosParaEnviar,
      "subtotal": detalle["subtotal"] ?? 0.0,
      "iva": detalle["iva"] ?? 0.0,
      "total": detalle["total"] ?? 0.0,
    };

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Venta actualizada exitosamente."),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Error al actualizar la venta: ${response.reasonPhrase}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error de conexión: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isEditing = false; // Termina el estado de edición
      });
    }
  }

  Widget _buildTipoProductoDropdown(
    Color colorTextFieldClaro,
    Color colorTextFieldOscuro,
    Color colorFondoClaro,
    Color colorFondoOscuro,
    Color colorTextoOscuro,
    Color colorTextoClaro, {
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final providerDialog = Provider.of<CotizacionProvider>(context);
    return SizedBox(
      height: 40.0,
      child: DropdownButtonFormField<String>(
        value: value,
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.w500,
        ),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color:
                providerDialog.isDarkMode ? colorTextoClaro : colorTextoOscuro,
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
          fillColor: providerDialog.isDarkMode
              ? colorTextFieldOscuro
              : colorTextFieldClaro,
          contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        ),
        icon: Icon(
          Icons.arrow_drop_down,
          color:
              providerDialog.isDarkMode ? colorTextoClaro : Color(0xFF001F3F),
        ),
        dropdownColor: providerDialog.isDarkMode
            ? colorTextFieldOscuro
            : colorFondoClaro, // Cambia el color de fondo según el modo
        items: [
          'Producto',
          'Software',
          'Servicio',
        ].map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: TextStyle(
                  color: providerDialog.isDarkMode
                      ? colorTextoClaro
                      : colorTextoOscuro,
                  fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextFieldDisabled(
    Color colorTextFieldClaro,
    Color colorTextFieldOscuro,
    Color colorFondoClaro,
    Color colorFondoOscuro,
    Color colorTextoOscuro,
    Color colorTextoClaro, {
    required String label,
    required String value,
  }) {
    final providerTFD = Provider.of<CotizacionProvider>(context);
    return SizedBox(
      height: 40.0,
      child: TextFormField(
        enabled: false,
        style: TextStyle(
          fontSize: 12,
          color: providerTFD.isDarkMode ? colorTextoClaro : Colors.grey[700],
        ),
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: providerTFD.isDarkMode ? colorTextoClaro : colorTextoOscuro,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(
                color: Color(0xFF001F3F)), // Color del borde en estado enfocado
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(
                color: Color(0xFF001F3F),
                width: 1.5), // Color del borde habilitado
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(
                color: Colors.grey.shade300, width: 1.5), // Borde deshabilitado
          ),
          filled: true,
          fillColor:
              providerTFD.isDarkMode ? Colors.grey.shade800 : Colors.grey[200],
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        ),
      ),
    );
  }

  Widget _buildTextFieldValidator(
    Color colorTextFieldClaro,
    Color colorTextFieldOscuro,
    Color colorFondoClaro,
    Color colorFondoOscuro,
    Color colorTextoOscuro,
    Color colorTextoClaro, {
    required TextEditingController controller,
    required String label,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? onChanged,
  }) {
    final providerTFV = Provider.of<CotizacionProvider>(context);
    return SizedBox(
      height: 40.0,
      child: TextFormField(
        controller: controller,
        style: TextStyle(fontSize: 12),
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: providerTFV.isDarkMode ? colorTextoClaro : colorTextoOscuro,
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
          fillColor: providerTFV.isDarkMode
              ? colorTextFieldOscuro
              : colorTextFieldClaro,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownField(
    Color colorTextFieldClaro,
    Color colorTextFieldOscuro,
    Color colorFondoClaro,
    Color colorFondoOscuro,
    Color colorTextoOscuro,
    Color colorTextoClaro, {
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final providerDDF = Provider.of<CotizacionProvider>(context);
    return SizedBox(
      height: 40.0,
      child: DropdownButtonFormField<String>(
        hint: Text(
          value ?? '',
          style: TextStyle(
            color: providerDDF.isDarkMode ? colorTextoClaro : colorTextoOscuro,
            fontSize: 14,
          ),
        ),
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: providerDDF.isDarkMode ? colorTextoClaro : colorTextoOscuro,
            fontWeight: FontWeight.w500,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(color: Color(0xFF001F3F)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          fillColor: providerDDF.isDarkMode
              ? colorTextFieldOscuro
              : colorTextFieldClaro,
          filled: true,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
        dropdownColor: providerDDF.isDarkMode
            ? colorTextFieldOscuro
            : colorTextFieldClaro, // Cambia el color del menú desplegable según el modo
        icon: Icon(
          Icons.arrow_drop_down,
          color: providerDDF.isDarkMode ? colorTextoClaro : Color(0xFF001F3F),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: TextStyle(
                color: providerDDF.isDarkMode
                    ? colorTextoClaro
                    : colorTextoOscuro, // Ajusta el color del texto según el modo
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

// Widget para mostrar el resumen total
  Widget _buildResumenTotal(
    String label,
    String value,
    Color colorTextFieldClaro,
    Color colorTextFieldOscuro,
    Color colorFondoClaro,
    Color colorFondoOscuro,
    Color colorTextoOscuro,
    Color colorTextoClaro,
  ) {
    final providerBRT = Provider.of<CotizacionProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Text(
            '\$${formatAmount(double.tryParse(value) ?? 0.0)}',
            style: TextStyle(
              fontSize: 14,
              color: providerBRT.isDarkMode
                  ? colorTextoClaro
                  : Colors.blueGrey[700],
            ),
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
      BuildContext context,
      provider,
      List<dynamic> estadosActuales,
      String folio,
      colorTextFieldClaro,
      colorTextFieldOscuro,
      colorFondoClaro,
      colorFondoOscuro,
      colorTextoOscuro,
      colorTextoClaro) {
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
        return StatefulBuilder(
          builder: (context, setState) {
            bool isLoading = false; // Inicializamos isLoading aquí

            return AlertDialog(
              title: Text('Detalles del Estado'),
              backgroundColor: provider.isDarkMode
                  ? Color.fromARGB(255, 18, 41, 66)
                  : colorFondoClaro,
              content: Container(
                width: MediaQuery.of(context).size.width * 0.33,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: estados.length,
                  itemBuilder: (BuildContext context, int index) {
                    final estado = estados[index];
                    final color = _getStatusColor(estado);

                    final estadoEncontrado = estadosActuales.firstWhere(
                      (e) => e['estado'] == estado,
                      orElse: () => null,
                    );

                    final fechaEstado = estadoEncontrado != null
                        ? estadoEncontrado['fechaEstado']
                        : 'No disponible';

                    final fechaColor = fechaEstado == 'No disponible'
                        ? Colors.grey
                        : Color(0xFF00A1B0);
                    final fechaFontWeight = fechaEstado == 'No disponible'
                        ? FontWeight.normal
                        : FontWeight.w500;

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
                          Expanded(
                            flex: 2,
                            child: Text(
                              estado,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 40),
                          Expanded(
                            flex: 5,
                            child: Text(
                              fechaEstado == 'No disponible'
                                  ? fechaEstado
                                  : formatDateWithTime(fechaEstado),
                              style: TextStyle(
                                fontSize: 14,
                                color: fechaColor,
                                fontWeight: fechaFontWeight,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          if (fechaEstado != 'No disponible')
                            isLoading
                                ? CircularProgressIndicator()
                                : IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      // Iniciar la carga
                                      setState(() {
                                        isLoading = true;
                                      });

                                      // Llamada para eliminar el estado
                                      await eliminarEstado(
                                        context,
                                        estado,
                                        folio,
                                        setState,
                                        estadosActuales,
                                      );

                                      // Detener la carga
                                      setState(() {
                                        isLoading = false;
                                      });
                                    },
                                  ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: <Widget>[
               TextButton(
  child: Text(
    'Cerrar',
    style: TextStyle(
      color: provider.isDarkMode ? Colors.white : null, // Elimina el color verde
    ),
  ),
  onPressed: () {
    Navigator.of(context).pop(); // Cierra el diálogo
  },
),

              ],
            );
          },
        );
      },
    );
  }

  Future<void> eliminarEstado(BuildContext context, String estado, String folio,
      Function setState, List<dynamic> estadosActuales) async {
    final url =
        Uri.parse('https://codtix.vercel.app/api/v1/estados/eliminar/$folio');

    try {
      final response = await http
          .delete(url, body: jsonEncode({"estado": estado}), headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        print('Estado eliminado exitosamente');

        // Elimina el estado visualmente
        setState(() {
          estadosActuales.removeWhere((e) => e['estado'] == estado);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado eliminado correctamente'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('Error al eliminar el estado: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al eliminar el estado: $e');
    }
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

String formatAmount(dynamic value) {
  if (value is num) {
    return NumberFormat("#,##0.00")
        .format(value); // Asegura que siempre se muestren dos decimales
  }
  return value.toString();
}
