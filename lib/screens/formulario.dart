import 'dart:convert';

import 'package:cotizacion/custom_app_bar.dart';
import 'package:cotizacion/screens/calculos.dart';
import 'package:cotizacion/screens/control.dart';
import 'package:cotizacion/generarPDF.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class FormularioScreen extends StatefulWidget {
  @override
  _FormularioScreenState createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  final nombresController = TextEditingController();
  final telefonoController = TextEditingController();
  final emailController = TextEditingController();
  final descripcionController = TextEditingController();
  final precioController = TextEditingController();
  final personalizadoController = TextEditingController();
  final cantidadPersonalizadaController = TextEditingController();
  final porcentajeGananciaController =
      TextEditingController(); // Nuevo campo para el % de ganancia
  final TextEditingController _descController = TextEditingController();

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(); // Clave del formulario

  String? _selectedPersonType;
  String? _selectedQuantity = '1';
  String? _selectedType = 'Producto';
  String? _selectedMetodoP; // Variable para almacenar la opción seleccionada

//DATOS PARA LAS PETICIONES HTTP
  String clienteId = ''; // Variable para almacenar el ID del cliente
  List<String> articuloIds =
      []; // Variable para almacenar los IDs de los artículos

  bool _cotizacionGuardada = false;
  String? _folio; // Variable para almacenar el folio recibido

  final List<String> _personTypes = [
    'C.P.',
    'LIC.',
    'CIUD.',
    'SRA.',
    'SR.',
    'DR.',
    'ING.',
    'TEC.',
    'MTRO.',
    'PROF.',
    'ABG.',
    'ABGDA.',
    'OTRO'
  ];

  final List<String> _quantities = ['1', '2', '3', '4', '5', 'OTRO'];

  final List<String> _types = [
    'Producto',
    'Software',
    'Servicio',
  ];

  bool _mostrarIVA = true;

  double ganancia = 0.0;
  double precioVenta = 0.0;
  double gananciaTotal = 0.0;

  void _toggleIVA(bool? value) {
    setState(() {
      _mostrarIVA = value ?? false;
    });
  }

  bool _requiereFactura = false; // Inicialmente en "No"

  void _handleGeneratePdf(BuildContext context) {
    final provider = Provider.of<CotizacionProvider>(context, listen: false);
    generatePdf(provider); // Llamada correcta
  }

  bool _isDarkMode = false; // Estado del modo oscuro

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CotizacionProvider>(context);

    return Scaffold(
      backgroundColor: Color(0xFFf7f8fa),
      appBar: CustomAppBar(
        isDarkMode: _isDarkMode,
        toggleDarkMode: _toggleDarkMode,
        title: 'Formulario', // Título específico para esta pantalla
      ),
      body: Container(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 10, 30,
                    100), // Ajusta el padding inferior para dejar espacio al botón
                child: Form(
                  key: _formKey, // Asigna la clave al formulario
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('DESCRIPCIÓN DE COTIZACIÓN'),
                      _buildDesc(),
                      SizedBox(height: 20),
                      _buildSectionTitle('CLIENTE'),
                      SizedBox(height: 10),
                      _buildClienteInfo(),
                      SizedBox(height: 30),
                      _buildSectionTitle('PRODUCTO'),
                      SizedBox(height: 10),
                      _buildarticuloInfo(),
                      SizedBox(height: 30),
                      _buildGananciaYPrecioVenta(), // Nuevo widget para mostrar ganancia y precio de venta
                      _buildSectionTitle('RESUMEN'),
                      _buildSummary(provider),
                      SizedBox(height: 20),
                      _buildProductTable(
                          provider), // Tabla de articulos con ganancia total
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF001F3F),
        ));
  }

  Widget _buildClienteInfo() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildDropdownWithCustom(
                label: 'Tipo de Persona',
                value: _selectedPersonType,
                items: _personTypes,
                onChanged: (value) {
                  setState(() {
                    _selectedPersonType = value;
                  });
                },
                customController: personalizadoController,
              ),
            ),
            SizedBox(width: 10),

            // Campo de texto para el cliente
            Expanded(
              flex: 4,
              child: _buildTextFieldValidator(
                controller: nombresController,
                label: 'Cliente',
                inputType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese el nombre del cliente';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 10),
            // Campo de texto para el teléfono
            Expanded(
              flex: 3,
              child: _buildTextFieldValidator(
                controller: telefonoController,
                label: 'Teléfono',
                inputType: TextInputType.number,
                validator: (value) {
                  // Validación: verificar que el campo no esté vacío
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese un número de teléfono';
                  }

                  // Validación: verificar que el número tenga exactamente 10 dígitos
                  if (value.length != 10) {
                    return 'El número de teléfono debe tener 10 dígitos';
                  }

                  // Validación: verificar que solo contenga dígitos
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'El número de teléfono solo debe contener dígitos';
                  }

                  // Si todas las validaciones pasan
                  return null;
                },
              ),
            ),

            SizedBox(width: 10),
            // Campo de texto para el correo
            Expanded(
              flex: 4,
              child: _buildTextFieldValidator(
                controller: emailController,
                label: 'Correo',
                inputType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese un correo electrónico';
                  }
                  // Validación de formato de correo
                  const pattern = r'^[^@]+@[^@]+\.[^@]+';
                  final regex = RegExp(pattern);
                  if (!regex.hasMatch(value)) {
                    return 'Ingrese un correo válido';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildarticuloInfo() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: _selectedType,
            onChanged: (String? newValue) {
              _selectedType = newValue; // Actualiza el estado
            },
            decoration: InputDecoration(
              labelText: 'Tipo',
              labelStyle:
                  TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0), // Bordes redondeados
                borderSide: BorderSide(
                  color: Color(0xFF001F3F),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white, // Fondo blanco
              contentPadding:
                  EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: Color(0xFF001F3F),
            ), // Icono personalizado
            dropdownColor: Colors.white, // Color del menú desplegable
            items: _types.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14, // Texto más visible en el menú
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _buildDropdownWithCustom(
            label: 'Cantidad',
            value: _selectedQuantity,
            items: _quantities,
            onChanged: (value) {
              setState(() {
                _selectedQuantity = value!;
              });
            },
            customController: cantidadPersonalizadaController,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: _buildTextField(descripcionController, 'Descripción'),
        ),
        SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _buildTextField(
              precioController,
              'Precio de Compra',
              TextInputType.number,
              _calcularGanancia), // Modificado para calcular ganancia
        ),
        SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _buildTextField(
              porcentajeGananciaController,
              '% Ganancia',
              TextInputType.number,
              _calcularGanancia), // Nuevo campo para porcentaje de ganancia
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: _agregararticulo,
          child: Text(
            'Agregar',
            style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF008f8f),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGananciaYPrecioVenta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Precio de Venta: \$${precioVenta.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 14, color: Colors.black),
        ),
        Text(
          'Ganancia: \$${ganancia.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 14, color: Colors.black),
        ),
        SizedBox(height: 30),
      ],
    );
  }

  void _calcularGanancia() {
    final precioCompra = double.tryParse(precioController.text) ?? 0.0;
    final porcentajeGanancia =
        double.tryParse(porcentajeGananciaController.text) ?? 0.0;

    setState(() {
      ganancia = (precioCompra * porcentajeGanancia) / 100;
      precioVenta = precioCompra + ganancia;
    });
  }

  Widget _buildDropdownWithCustom({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required TextEditingController? customController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          hint: Text('Elige',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            labelStyle:
                TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0), // Bordes redondeados
                borderSide: BorderSide(
                  color: Color(0xFF001F3F),
                )),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            filled: true,
            fillColor:
                Colors.white, // Fondo blanco para consistencia con el TextField
            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: Color(0xFF001F3F),
          ), // Icono personalizado
          dropdownColor: Colors.white, // Color del menú desplegable
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14), // Texto más visible en el menú
              ),
            );
          }).toList(),
        ),
        if (value == 'OTRO') SizedBox(height: 10),
        if (value == 'OTRO')
          SizedBox(
            width: 200, // Tamaño más compacto para el campo personalizado
            child: _buildTextField(
                customController!, 'Otro', TextInputType.number),
          ),
      ],
    );
  }

  void _mostrarMensajeError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _guardarCliente() async {
    /*  String nombres = '$_selectedPersonType ${nombresController.text}'; */
    String nombres = nombresController.text;
    String telefono = telefonoController.text;
    String email = emailController.text;

    final body = {
      'nombres': nombres,
      'telefono': telefono,
      'email': email,
    };

    final response = await http.post(
      Uri.parse('http://192.168.1.13:3000/api/v1/clientes/agregar'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      clienteId = responseData['id']; // Almacena el ID
      print('Cliente guardado con éxito: $clienteId');
    } else {
      print('Error al guardar el cliente: ${response.body}');
    }
  }

  Future<void> _guardararticulo(BuildContext context) async {
    final provider = Provider.of<CotizacionProvider>(context, listen: false);
    List<CotizacionItem> articulos = provider.items;

    // Asegúrate de que cada artículo tenga un tipo
    for (var item in articulos) {
      if (item.tipo.isEmpty) {
        print('Error: El tipo del artículo "${item.descripcion}" está vacío.');
        return;
      }
    }

    // Construye el cuerpo del POST directamente como un array
    final body = articulos.map((item) {
      return {
        'descripcion': item.descripcion,
        'tipo': item.tipo,
        'precio_compra': item.precioUnitario.toString(),
      };
    }).toList();

    // Asegúrate de que el cuerpo es un objeto JSON válido
    print('Cuerpo del POST para artículos: ${json.encode(body)}');

    // Hacer el POST request
    final response = await http.post(
      Uri.parse('http://192.168.1.13:3000/api/v1/articulos/agregar'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body), // Enviar como array directamente
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      // Almacena los IDs de los artículos, que se espera que ahora sean un array
      articuloIds = List<String>.from(responseData[
          'id']); // Asegúrate de que esto coincide con la estructura de respuesta
      print('Artículos guardados con éxito: $articuloIds');
    } else {
      print('Error al guardar los artículos: ${response.body}');
    }
  }

  double _calcularSubtotal(List<CotizacionItem> articulos) {
    double subtotal = 0;
    for (var item in articulos) {
      subtotal += item.precioVenta * item.cantidad;
    }
    return subtotal;
  }

  double _calcularIVA(List<CotizacionItem> articulos) {
    const double tasaIVA = 0.16; // 16% de IVA
    return _calcularSubtotal(articulos) * tasaIVA;
  }

  double _calcularTotal(List<CotizacionItem> articulos) {
    return _calcularSubtotal(articulos) + _calcularIVA(articulos);
  }

  Future<void> _guardarVenta(BuildContext context) async {
    final provider = Provider.of<CotizacionProvider>(context, listen: false);
    List<CotizacionItem> articulos = provider.items;

    // Verifica que se hayan guardado artículos y que haya IDs disponibles
    if (articuloIds.isEmpty) {
      print('Error: No se han recibido IDs de artículos.');
      return;
    }

    // Asegúrate de que el número de IDs coincida con el número de artículos
    if (articuloIds.length != articulos.length) {
      print(
          'Error: El número de IDs de artículos no coincide con el número de artículos.');
      return;
    }

    // Array de productos basado en los artículos almacenados
    List<Map<String, dynamic>> productos = [];
    for (int i = 0; i < articulos.length; i++) {
      final item = articulos[i];
      productos.add({
        "idarticulo":
            articuloIds[i], // Usar el ID del artículo obtenido al guardarlo
        "precio_venta": item.precioVenta,
        "ganancia": item.ganancia,
        "porcentaje": item.porcentajeGanancia,
        "cantidad": item.cantidad,
      });
    }

    // Cuerpo del POST
    final body = {
      "iddetalleventa": clienteId, // Aquí va el ID del cliente guardado
      "nombre_venta": _descController.text, // Nombre o descripción de la venta
      "productos": productos, // Lista de productos con sus IDs y detalles
      "factura": _requiereFactura ? "Si" : "No",
      "tipo_pago": (_selectedMetodoP == null || _selectedMetodoP!.isEmpty)
          ? "No asignado"
          : _selectedMetodoP, // Si es null o vacío, enviar "No asignado"
      "subtotal": _calcularSubtotal(articulos), // Subtotal calculado
      "iva": _calcularIVA(articulos), // IVA calculado
      "total": _calcularTotal(articulos), // Total calculado
    };

    // Imprimir el cuerpo del POST antes de enviarlo
    print('Datos de la venta a enviar: ${json.encode(body)}');

    // Hacer el POST request
    final response = await http.post(
      Uri.parse('http://192.168.1.13:3000/api/v1/ventas/agregar'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    print('Código de estado: ${response.statusCode}');

    if (response.statusCode == 201) {
      print('Venta guardada con éxito');

      // Extraer el mensaje de respuesta del servidor
      final responseBody = json.decode(response.body);
      final message = responseBody['message'] ?? 'Venta guardada con éxito';
      _folio = clienteId; // Almacena el folio de la venta
      provider.setFolio(_folio!); // Actualiza el folio en el provider

      // Mostrar Snackbar con el mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
      // Actualizar el estado para habilitar el botón de generar PDF
      setState(() {
        _cotizacionGuardada = true;
      });

      print('Folio recibido: $_folio');
    } else {
      print('Error al guardar la venta: ${response.body}');

      final errorMessage = json.decode(response.body);
      final errorCode = response.statusCode;
      final errorDetail = errorMessage['error'] ?? 'Error al guardar la venta.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error $errorCode: $errorDetail'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTextField(TextEditingController controller, String label,
      [TextInputType keyboardType = TextInputType.text,
      VoidCallback? onChanged]) {
    return TextField(
      controller: controller,
      style:
          TextStyle(color: Colors.black87, fontSize: 14), // Texto más visible
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14),
        floatingLabelBehavior:
            FloatingLabelBehavior.auto, // Efecto flotante suave
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0), // Bordes muy redondeados
            borderSide: BorderSide(
              color: Color(0xFF001F3F),
            )),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white, // Fondo blanco para un look limpio
        contentPadding: EdgeInsets.symmetric(
            vertical: 15, horizontal: 25), // Más espacio interno
        hintText: "Ingresa $label", // Texto de ayuda
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
      keyboardType: keyboardType,
      onChanged: (value) {
        if (onChanged != null) onChanged();
      },
      inputFormatters: label == 'Cantidad' ||
              label == 'Precio de Compra' ||
              label == '% Ganancia'
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
          : [],
    );
  }

  Widget _buildTextFieldValidator({
    required TextEditingController controller,
    required String label,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style:
          TextStyle(color: Colors.black87, fontSize: 14), // Texto más visible
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        floatingLabelBehavior:
            FloatingLabelBehavior.auto, // Efecto flotante suave
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: Color(0xFF001F3F)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          // Agrega este borde
          borderRadius: BorderRadius.circular(30.0),
          borderSide:
              BorderSide(color: Colors.red, width: 1.5), // Borde rojo al error
        ),
        focusedErrorBorder: OutlineInputBorder(
          // Borde al enfocarse en error
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(
              color: Colors.red, width: 1.5), // Borde rojo al error enfocado
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        errorStyle: TextStyle(
          // Estilo del mensaje de error
          color: Colors.red, // Color del mensaje de error
          fontSize: 10, // Tamaño del mensaje de error
        ),
      ),
      validator: validator,
      inputFormatters: label == 'Cantidad' ||
              label == 'Precio de Compra' ||
              label == '% Ganancia' ||
              label == 'Teléfono'
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
          : [],
    );
  }

  // Actualiza este método para recalcular la ganancia total
  void _agregararticulo() {
    final provider = Provider.of<CotizacionProvider>(context, listen: false);
    final descripcion = descripcionController.text;
    final tipo = _selectedType!;
    final precioCompra =
        double.tryParse(precioController.text.replaceAll(',', '')) ?? 0;
    final cantidad = _selectedQuantity == 'OTRO'
        ? int.tryParse(cantidadPersonalizadaController.text) ?? 1
        : int.tryParse(_selectedQuantity!) ?? 1;
    final porcentajeGanancia =
        double.tryParse(porcentajeGananciaController.text) ?? 0;

    // Calcular la ganancia y el precio de venta
    final nuevaGanancia = (precioCompra * porcentajeGanancia) / 100;
    final nuevoPrecioVenta = precioCompra + nuevaGanancia;

    if (descripcion.isNotEmpty && precioCompra > 0 && cantidad > 0) {
      final item = CotizacionItem(
        descripcion: descripcion,
        tipo: tipo,
        precioUnitario: precioCompra,
        cantidad: cantidad,
        ganancia: nuevaGanancia,
        porcentajeGanancia: porcentajeGanancia,
        precioVenta: nuevoPrecioVenta, // Precio de venta calculado
      );

      provider.addItem(item);

      _calcularGananciaTotal(); // Recalcular ganancia total después de agregar artículo

      // Limpiar campos
      descripcionController.clear();
      precioController.clear();
      cantidadPersonalizadaController.clear();
      porcentajeGananciaController.clear();
      _selectedQuantity = '1';

      // Reiniciar las variables de ganancia y precio de venta
      setState(() {
        ganancia = 0.0; // Reiniciar ganancia
        precioVenta = 0.0; // Reiniciar precio de venta
      });
    }
  }

  void _calcularGananciaTotal() {
    final provider = Provider.of<CotizacionProvider>(context, listen: false);

    // Recalcula la ganancia total
    gananciaTotal = provider.items.fold(0.0, (sum, item) {
      final precioCompra = item.precioUnitario;
      final precioVenta =
          precioCompra + (precioCompra * item.porcentajeGanancia / 100);
      final gananciaPorarticulo = (precioVenta - precioCompra) * item.cantidad;
      return sum + gananciaPorarticulo;
    });
  }

  Widget _buildTableHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF001F3F),
            fontSize: 14),
      ),
    );
  }

  void _actualizarDatosClientePDF(BuildContext context) {
    final provider = Provider.of<CotizacionProvider>(context, listen: false);

    // Recolecta los datos del cliente desde los controladores
    final cliente = nombresController.text;
    final telefono = telefonoController.text;
    final email = emailController.text;
    final tipoPersona = _selectedPersonType == 'OTRO'
        ? personalizadoController.text
        : _selectedPersonType ?? '';

    // Asigna los datos al proveedor
    provider.setTipoPersona(tipoPersona);
    provider.setCliente(cliente);
    provider.setTelefono(telefono);
    provider.setEmail(email);

    // Asigna el folio al proveedor si está disponible
    if (_folio != null) {
      provider.setFolio(
          _folio!); // Asegúrate de que `CotizacionProvider` tenga un método para setear el folio
    }

    // Genera el PDF con todos los datos del cliente y la venta
    _handleGeneratePdf(context);
  }

  /* void _actualizarDatosCliente(BuildContext context) {
    final provider = Provider.of<CotizacionProvider>(context, listen: false);
    final cliente = nombresController.text;
    final telefono = telefonoController.text;
    final email = emailController.text;
    final tipoPersona = _selectedPersonType == 'OTRO'
        ? personalizadoController.text
        : _selectedPersonType ?? '';

    provider.setTipoPersona(tipoPersona);
    provider.setCliente(cliente);
    provider.setTelefono(telefono);
    provider.setEmail(email);

    _handleGeneratePdf(context);
  } */

  Widget _buildSummary(CotizacionProvider provider) {
    // Calcular el total a pagar incluyendo el porcentaje de ganancia
    final total = provider.items.fold(0.0, (sum, item) {
      final precioCompra = item.precioUnitario;
      final precioVenta =
          precioCompra + (precioCompra * item.porcentajeGanancia / 100);
      return sum + (precioVenta * item.cantidad);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ganancia Total: \$${gananciaTotal.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildProductTable(CotizacionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade400),
            columnWidths: {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(3),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
              5: FlexColumnWidth(1),
              6: FlexColumnWidth(1),
              7: FlexColumnWidth(1),
              8: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                children: [
                  _buildTableHeader('Tipo'),
                  _buildTableHeader('Cantidad'),
                  _buildTableHeader('Descripción'),
                  _buildTableHeader('Precio de Compra'),
                  _buildTableHeader('% Ganancia'),
                  _buildTableHeader('Ganancia por articulo'), // Nueva cabecera
                  _buildTableHeader('Precio de Venta'),
                  _buildTableHeader('Total'),
                  _buildTableHeader('Acción'),
                ],
              ),
              ...provider.items.map((item) {
                double precioCompra = item.precioUnitario;
                double porcentajeGanancia = item.porcentajeGanancia;
                double gananciaPorarticulo =
                    (precioCompra * porcentajeGanancia / 100);
                double precioVenta = precioCompra + gananciaPorarticulo;
                double totalVenta = precioVenta * item.cantidad;

                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(item.tipo.toString()),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(item.cantidad.toString()),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(item.descripcion),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child:
                          Text('\$${item.precioUnitario.toStringAsFixed(2)}'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          '${item.porcentajeGanancia.toStringAsFixed(2)}%'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          '\$${(item.precioUnitario * item.porcentajeGanancia / 100).toStringAsFixed(2)}'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          '\$${(item.precioUnitario + (item.precioUnitario * item.porcentajeGanancia / 100)).toStringAsFixed(2)}'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '\$${totalVenta.toStringAsFixed(2)}', // Total correcto
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editararticulo(context, item),
                            tooltip: 'Editar',
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Muestra un cuadro de diálogo de confirmación
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Confirmar Eliminación'),
                                    content: Text(
                                        '¿Estás seguro de que deseas eliminar este artículo?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); // Cierra el diálogo
                                        },
                                        child: Text('Cancelar',
                                            style:
                                                TextStyle(color: Colors.grey)),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          final provider =
                                              Provider.of<CotizacionProvider>(
                                                  context,
                                                  listen: false);
                                          provider.removeItem(
                                              item); // Llama a la función de eliminación
                                          Navigator.of(context)
                                              .pop(); // Cierra el diálogo
                                        },
                                        child: Text('Eliminar',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            tooltip: 'Eliminar',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Total a Pagar: \$${provider.items.fold(0.0, (sum, item) {
            final precioCompra = item.precioUnitario;
            final precioVenta =
                precioCompra + (precioCompra * item.porcentajeGanancia / 100);
            return sum + (precioVenta * item.cantidad);
          }).toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDesc() {
    final List<String> _metodos = ['Transferencia', 'Efectivo'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Campo de texto para descripción
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: _buildTextFieldValidator(
                  controller: _descController,
                  label: 'Nombre o Descripcion',
                  inputType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese la descripción de la venta';
                    }
                    return null;
                  },
                ),
              ),
            ),
            Spacer(),

            // Dropdown para el método de pago
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedMetodoP,
                onChanged: (String? newValue) {
                  _selectedMetodoP = newValue; // Actualiza el estado
                },
                decoration: InputDecoration(
                  labelText: 'Método de pago',
                  labelStyle: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                      fontSize: 14),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(30.0), // Bordes redondeados
                    borderSide: BorderSide(
                      color: Color(0xFF001F3F),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white, // Fondo blanco
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF001F3F),
                ), // Icono personalizado
                dropdownColor: Colors.white, // Color del menú desplegable
                items: _metodos.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14, // Texto más visible en el menú
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(width: 20),

            // Texto y Checkbox a la derecha con diseño
            Row(
              children: [
                Text(
                  '¿Requiere Factura?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(width: 10),
                Theme(
                  data: ThemeData(
                    unselectedWidgetColor: Colors.grey.shade400,
                  ),
                  child: Checkbox(
                    value: _requiereFactura,
                    onChanged: (bool? value) {
                      setState(() {
                        _requiereFactura = value ?? false;
                      });
                    },
                    activeColor: Color(0xFF001F3F),
                    checkColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _editararticulo(BuildContext context, CotizacionItem item) {
    String? tipoEdit = item.tipo;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final descripcionEditController =
            TextEditingController(text: item.descripcion);
        final precioEditController =
            TextEditingController(text: item.precioUnitario.toString());
        final cantidadEditController =
            TextEditingController(text: item.cantidad.toString());
        final porcentajeGananciaEditController =
            TextEditingController(text: item.porcentajeGanancia.toString());

        return AlertDialog(
          title: Text('Editar articulo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: tipoEdit,
                onChanged: (String? newValue) {
                  tipoEdit = newValue;
                },
                decoration: InputDecoration(
                  labelText: 'Tipo de Producto',
                  labelStyle: TextStyle(color: Colors.black),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: Color(0xFF001F3F)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
                icon: Icon(Icons.arrow_drop_down, color: Color(0xFF001F3F)),
                dropdownColor: Colors.white,
                items: _types.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item,
                        style: TextStyle(
                            color: Colors.grey.shade800, fontSize: 14)),
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              _buildTextField(descripcionEditController, 'Descripción'),
              SizedBox(height: 10),
              _buildTextField(
                  precioEditController, 'Precio', TextInputType.number),
              SizedBox(height: 10),
              _buildTextField(
                  cantidadEditController, 'Cantidad', TextInputType.number),
              SizedBox(height: 10),
              _buildTextField(porcentajeGananciaEditController,
                  'Porcentaje de Ganancia', TextInputType.number),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child:
                  Text('Cancelar', style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () {
                final descripcionEdit = descripcionEditController.text;
                final precioEdit = double.tryParse(
                        precioEditController.text.replaceAll(',', '')) ??
                    0;
                final cantidadEdit =
                    int.tryParse(cantidadEditController.text) ?? 1;
                final porcentajeGananciaEdit = double.tryParse(
                        porcentajeGananciaEditController.text
                            .replaceAll(',', '')) ??
                    0;

                // Calcula la ganancia aquí
                final gananciaPorArticulo =
                    (precioEdit * porcentajeGananciaEdit) / 100;

                if (descripcionEdit.isNotEmpty &&
                    precioEdit > 0 &&
                    cantidadEdit > 0 &&
                    porcentajeGananciaEdit >= 0 &&
                    tipoEdit != null) {
                  final newItem = CotizacionItem(
                    descripcion: descripcionEdit,
                    tipo: tipoEdit!,
                    precioUnitario: precioEdit,
                    cantidad: cantidadEdit,
                    porcentajeGanancia: porcentajeGananciaEdit,
                    ganancia:
                        gananciaPorArticulo, // Asegúrate de incluir la ganancia
                    precioVenta: precioEdit +
                        gananciaPorArticulo, // Calcula el precio de venta
                  );

                  final provider =
                      Provider.of<CotizacionProvider>(context, listen: false);
                  provider.updateItem(item, newItem);

                  Navigator.pop(context);
                }
              },
              child: Text('Guardar',
                  style: TextStyle(color: Color.fromARGB(255, 0, 98, 255))),
            ),
          ],
        );
      },
    );
  }

  // Método para limpiar los campos
  void _limpiarCampos() {
    // Limpiar los controladores de texto
    nombresController.clear();
    telefonoController.clear();
    emailController.clear();
    descripcionController.clear();
    precioController.clear();
    personalizadoController.clear();
    cantidadPersonalizadaController.clear();
    porcentajeGananciaController.clear();
    _descController.clear();

    // Restablecer las variables seleccionadas
    setState(() {
      _selectedPersonType = null;
      _selectedQuantity = '1'; // Valor por defecto
      _selectedType = 'Producto'; // Valor por defecto
      _selectedMetodoP = null;
    });
  }

  void _guardarCotizacion(BuildContext context) async {
    await _guardarCliente(); // Espera a que se guarde el cliente
    await _guardararticulo(context); // Espera a que se guarden los artículos
    await _guardarVenta(context); // Finalmente, guarda la venta
  }

  Widget _buildButtons() {
    final provider = Provider.of<CotizacionProvider>(context, listen: false);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Align(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _cotizacionGuardada
                  ? null
                  : () {
                      final provider = Provider.of<CotizacionProvider>(context,
                          listen: false);

                      bool hayErrores = false;

                      // 1. Verificar si la lista de artículos está vacía
                      if (provider.items.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'No se puede guardar la cotización porque no se han agregado artículos.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        hayErrores = true; // Marca que hubo un error
                      }

                      // 2. Validar el formulario (sin salir de la función si hay errores)
                      if (!_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Por favor, corrige los errores del formulario antes de continuar.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        hayErrores =
                            true; // Marca que hubo un error en el formulario
                      }

                      // 3. Si no hay errores, proceder a guardar la cotización
                      if (!hayErrores) {
                        _guardarCotizacion(
                            context); // Guardar cotización si todo es válido
                      }
                    },
              icon: Icon(
                Icons.save, // Ícono de guardar
                color: Colors.white,
              ),
              label: Text(
                'Guardar Cotización',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _cotizacionGuardada
                    ? Colors.grey
                    : Color(0xFF008f8f), // Color de fondo
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Bordes redondeados
                ),
                elevation: 5, // Efecto de sombra
              ),
            ),
            SizedBox(width: 15),
            ElevatedButton.icon(
              onPressed: _cotizacionGuardada
                  ? () => _actualizarDatosClientePDF(context)
                  : null, // Habilitar/Deshabilitar según el estado
              icon: Icon(
                Icons.picture_as_pdf, // Cambia este ícono según tus necesidades
                color: Colors.white,
              ),
              label: Text(
                'Generar PDF',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _cotizacionGuardada
                    ? Color(0xFF008f8f)
                    : Colors.grey, // Color de fondo
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Bordes redondeados
                ),
                elevation: 5, // Efecto de sombra
              ),
            ),
            SizedBox(width: 15),
            ElevatedButton.icon(
              onPressed: () {
                _limpiarCampos();
                provider.clearItems(); // Limpia los productos
                setState(() {
                  _cotizacionGuardada =
                      false; // Habilita el botón de Guardar Cotización
                });
              },
              icon: Icon(
                Icons.clear_all, // Ícono de limpiar
                color: Colors.white,
              ),
              label: Text(
                'Limpiar Campos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF008f8f), // Color original
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Bordes redondeados
                ),
                elevation: 5, // Efecto de sombra
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernButton({
    required String text,
    required IconData icon, // Parámetro para el ícono
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: Colors.white,
      ), // Ícono dentro del botón
      label: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color, // Color de fondo
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // Bordes redondeados
        ),
        elevation: 5, // Efecto de sombra
      ),
    );
  }
}
