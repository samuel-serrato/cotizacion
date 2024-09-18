import 'dart:convert';

import 'package:cotizacion/screens/calculos.dart';
import 'package:cotizacion/screens/control.dart';
import 'package:cotizacion/screens/generarPDF.dart';
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

  String? _selectedPersonType;
  String? _selectedQuantity = '1';
  String? _selectedType = 'Producto';

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
    'PERSONALIZADO'
  ];

  final List<String> _quantities = ['1', '2', '3', '4', '5', 'PERSONALIZADO'];

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

  void _handleGeneratePdf(BuildContext context) {
    final provider = Provider.of<CotizacionProvider>(context, listen: false);
    generatePdf(provider); // Llamada correcta
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CotizacionProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Formulario de Cliente',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 27, 69),
      ),
      body: Container(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 30, 30,
                    100), // Ajusta el padding inferior para dejar espacio al botón
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // _buildInstructions(provider),
                    _buildSectionTitle('CLIENTE'),
                    SizedBox(height: 10),
                    _buildClienteInfo(),
                    SizedBox(height: 30),
                    _buildSectionTitle('PRODUCTO'),
                    SizedBox(height: 10),
                    _buildProductoInfo(),
                    SizedBox(height: 30),
                    _buildGananciaYPrecioVenta(), // Nuevo widget para mostrar ganancia y precio de venta
                    _buildSummary(provider),
                    SizedBox(height: 20),
                    _buildProductTable(
                        provider), // Tabla de productos con ganancia total
                    SizedBox(height: 20),
                  ],
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
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blueAccent,
      ),
    );
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
            Expanded(
              flex: 4,
              child: _buildTextField(nombresController, 'Cliente'),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: _buildTextField(
                  telefonoController, 'Teléfono', TextInputType.phone),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: _buildTextField(emailController, 'Correo'),
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProductoInfo() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildDropdownWithCustom(
            label: 'Tipo',
            value: _selectedType,
            items: _types,
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
            customController: cantidadPersonalizadaController,
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
          onPressed: _agregarProducto,
          child: Text(
            'Agregar',
            style: TextStyle(
                color: Color.fromARGB(255, 0, 27, 69),
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 0, 209, 129),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
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
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
        Text(
          'Ganancia: \$${ganancia.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
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
    required TextEditingController customController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          hint: Text('Elige una opcion'),
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(labelText: label),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
        if (value == 'PERSONALIZADO') SizedBox(height: 10),
        if (value == 'PERSONALIZADO')
          SizedBox(
            width: 100, // Tamaño más pequeño para el campo personalizado
            child: _buildTextField(
                customController, 'Personalizado', TextInputType.number),
          ),
      ],
    );
  }

  void _guardarCliente() async {
    // Obtén los valores de los controladores y del Dropdown
    String nombres = nombresController.text;
    String telefono = telefonoController.text;
    String email = emailController.text;

    // Cuerpo del POST
    final body = {
      'nombres': nombres,
      'telefono': telefono,
      'email': email,
    };

    // Hacer el POST request
    final response = await http.post(
      Uri.parse('http://192.168.0.109:3000/api/v1/clientes/agregar'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      print('Cliente guardado con éxito');
    } else {
      print('Error al guardar el cliente: ${response.body}');
    }
  }

  void _guardarProducto() async {
    // Obtén los valores de los controladores y del Dropdown
    String producto = descripcionController.text;
    String precio_compra = precioController.text;

    // Cuerpo del POST
    final body = {
      'producto': producto,
      'precio_compra': precio_compra,
    };

    // Hacer el POST request
    final response = await http.post(
      Uri.parse('http://192.168.0.109:3000/api/v1/productos/agregar'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      print('Cliente guardado con éxito');
    } else {
      print('Error al guardar el cliente: ${response.body}');
    }
  }

  Widget _buildTextField(TextEditingController controller, String label,
      [TextInputType keyboardType = TextInputType.text,
      VoidCallback? onChanged]) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueAccent),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        filled: true,
        fillColor: Colors.grey.shade200,
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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

  // Actualiza este método para recalcular la ganancia total
  void _agregarProducto() {
    final provider = Provider.of<CotizacionProvider>(context, listen: false);
    final descripcion = descripcionController.text;
    final precio =
        double.tryParse(precioController.text.replaceAll(',', '')) ?? 0;
    final cantidad = _selectedQuantity == 'PERSONALIZADO'
        ? int.tryParse(cantidadPersonalizadaController.text) ?? 1
        : int.tryParse(_selectedQuantity!) ?? 1;
    final porcentajeGanancia =
        double.tryParse(porcentajeGananciaController.text) ?? 0;

    if (descripcion.isNotEmpty && precio > 0 && cantidad > 0) {
      final item = CotizacionItem(
        descripcion: descripcion,
        precioUnitario: precio,
        cantidad: cantidad,
        ganancia: (precio * porcentajeGanancia) / 100,
        porcentajeGanancia: porcentajeGanancia, // Guardar el % de ganancia
      );

      provider.addItem(item);

      _calcularGananciaTotal(); // Recalcular ganancia total después de agregar producto

      // Limpiar campos
      descripcionController.clear();
      precioController.clear();
      cantidadPersonalizadaController.clear();
      porcentajeGananciaController.clear(); // Resetear el campo de % Ganancia
    }
  }

  void _calcularGananciaTotal() {
    final provider = Provider.of<CotizacionProvider>(context, listen: false);

    // Recalcula la ganancia total
    gananciaTotal = provider.items.fold(0.0, (sum, item) {
      final precioCompra = item.precioUnitario;
      final precioVenta =
          precioCompra + (precioCompra * item.porcentajeGanancia / 100);
      final gananciaPorProducto = (precioVenta - precioCompra) * item.cantidad;
      return sum + gananciaPorProducto;
    });
  }

  Widget _buildTableHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  void _actualizarDatosClientePDF(BuildContext context) {
    final provider = Provider.of<CotizacionProvider>(context, listen: false);
    final cliente = nombresController.text;
    final telefono = telefonoController.text;
    final email = emailController.text;
    final tipoPersona = _selectedPersonType == 'PERSONALIZADO'
        ? personalizadoController.text
        : _selectedPersonType ?? '';

    provider.setTipoPersona(tipoPersona);
    provider.setCliente(cliente);
    provider.setTelefono(telefono);
    provider.setEmail(email);

    _handleGeneratePdf(context);
  }

  void _actualizarDatosCliente(BuildContext context) {
    final provider = Provider.of<CotizacionProvider>(context, listen: false);
    final cliente = nombresController.text;
    final telefono = telefonoController.text;
    final email = emailController.text;
    final tipoPersona = _selectedPersonType == 'PERSONALIZADO'
        ? personalizadoController.text
        : _selectedPersonType ?? '';

    provider.setTipoPersona(tipoPersona);
    provider.setCliente(cliente);
    provider.setTelefono(telefono);
    provider.setEmail(email);

    _handleGeneratePdf(context);
  }

  Widget _buildInstructions(CotizacionProvider provider) {
    final total = provider.items.fold(0.0, (sum, item) => sum + item.total);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INSTRUCCIONES: ',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                  fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'Por favor, complete toda la información del formulario para poder generar la cotización.',
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
      ],
    );
  }

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
        SizedBox(height: 20),
        Row(
          children: [
            Text(
              'RESUMEN:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                  fontSize: 18),
            ),
            /* Row(
              children: [
                Text('Mostrar IVA'),
                SizedBox(width: 10),
                Switch(
                  value: _mostrarIVA,
                  activeColor: Color.fromARGB(255, 3, 174, 108),
                  onChanged: (value) {
                    setState(() {
                      _mostrarIVA = value;
                    });
                  },
                ),
              ],
            ), */
          ],
        ),
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
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
              5: FlexColumnWidth(1),
              6: FlexColumnWidth(
                  1), // Nueva columna para la ganancia por producto
            },
            children: [
              TableRow(
                children: [
                  _buildTableHeader('Cantidad'),
                  _buildTableHeader('Descripción'),
                  _buildTableHeader('Precio de Compra'),
                  _buildTableHeader('% Ganancia'),
                  _buildTableHeader('Ganancia por Producto'), // Nueva cabecera
                  _buildTableHeader('Precio de Venta'),
                  _buildTableHeader('Total'),
                ],
              ),
              ...provider.items.map((item) {
                double precioCompra = item.precioUnitario;
                double porcentajeGanancia = item.porcentajeGanancia;
                double gananciaPorProducto =
                    (precioCompra * porcentajeGanancia / 100);
                double precioVenta = precioCompra + gananciaPorProducto;
                double totalVenta = precioVenta * item.cantidad;

                return TableRow(
                  children: [
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
                      child: Text('\$${precioCompra.toStringAsFixed(2)}'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('${porcentajeGanancia.toStringAsFixed(2)}%'),
                    ),
                    Padding(
                      // Nueva columna para mostrar la ganancia por producto
                      padding: const EdgeInsets.all(8.0),
                      child:
                          Text('\$${gananciaPorProducto.toStringAsFixed(2)}'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('\$${precioVenta.toStringAsFixed(2)}'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('\$${totalVenta.toStringAsFixed(2)}'),
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
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  void _editarProducto(BuildContext context, CotizacionItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final descripcionEditController =
            TextEditingController(text: item.descripcion);
        final precioEditController =
            TextEditingController(text: item.precioUnitario.toString());
        final cantidadEditController =
            TextEditingController(text: item.cantidad.toString());

        // Añadir un controlador para el porcentaje de ganancia
        final porcentajeGananciaEditController =
            TextEditingController(text: item.porcentajeGanancia.toString());

        return AlertDialog(
          title: Text('Editar Producto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(descripcionEditController, 'Descripción'),
              _buildTextField(
                  precioEditController, 'Precio', TextInputType.number),
              _buildTextField(
                  cantidadEditController, 'Cantidad', TextInputType.number),
              _buildTextField(porcentajeGananciaEditController,
                  'Porcentaje de Ganancia', TextInputType.number), // Agregado
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
                    0; // Agregado

                if (descripcionEdit.isNotEmpty &&
                    precioEdit > 0 &&
                    cantidadEdit > 0 &&
                    porcentajeGananciaEdit >= 0) {
                  // Validación de porcentaje de ganancia
                  final newItem = CotizacionItem(
                    descripcion: descripcionEdit,
                    precioUnitario: precioEdit,
                    cantidad: cantidadEdit,
                    porcentajeGanancia: porcentajeGananciaEdit, // Agregado
                  );

                  final provider =
                      Provider.of<CotizacionProvider>(context, listen: false);
                  provider.updateItem(item, newItem);

                  Navigator.pop(context);
                }
              },
              child: Text(
                'Guardar',
                style: TextStyle(color: Color.fromARGB(255, 0, 98, 255)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _guardarCotizacion(BuildContext context) {
    _guardarCliente();
  }

  Widget _buildButtons() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Align(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _guardarCotizacion(context),
              child: Text(
                'Guardar Cotización',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 0, 209, 129),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                foregroundColor: Color.fromARGB(255, 0, 27, 69),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            SizedBox(width: 10), // Espacio entre los botones
            ElevatedButton(
              onPressed: () {
                _actualizarDatosClientePDF(context);
              },
              child: Text(
                'Generar PDF',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 0, 209, 129),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                foregroundColor: Color.fromARGB(255, 0, 27, 69),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
