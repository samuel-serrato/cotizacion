import 'package:cotizacion/screens/calculos.dart';
import 'package:cotizacion/screens/cotizacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class FormularioScreen extends StatefulWidget {
  @override
  _FormularioScreenState createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  final clienteController = TextEditingController();
  final telefonoController = TextEditingController();
  final descripcionController = TextEditingController();
  final precioController = TextEditingController();
  final personalizadoController = TextEditingController();
  final cantidadPersonalizadaController = TextEditingController();

  String _selectedPersonType = 'C.P.';
  String _selectedQuantity = '1';

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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 30, 30, 100), // Ajusta el padding inferior para dejar espacio al botón
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstructions(provider),
                  _buildSectionTitle('CLIENTE'),
                  SizedBox(height: 10),
                  _buildClienteInfo(),
                  SizedBox(height: 30),
                  _buildSectionTitle('PRODUCTO'),
                  SizedBox(height: 10),
                  _buildProductoInfo(),
                  SizedBox(height: 30),
                  _buildSummary(provider),
                  SizedBox(height: 20),
                  _buildProductTable(provider),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildGuardarButton(),
          ),
        ],
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
                    _selectedPersonType = value!;
                  });
                },
                customController: personalizadoController,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: _buildTextField(clienteController, 'Cliente'),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: _buildTextField(
                  telefonoController, 'Teléfono', TextInputType.phone),
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
          flex: 4,
          child: _buildTextField(descripcionController, 'Descripción'),
        ),
        SizedBox(width: 10),
        Expanded(
          flex: 3,
          child:
              _buildTextField(precioController, 'Precio', TextInputType.number),
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

  Widget _buildDropdownWithCustom({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required TextEditingController customController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
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

  Widget _buildTextField(TextEditingController controller, String label,
      [TextInputType keyboardType = TextInputType.text]) {
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
      inputFormatters: label == 'Cantidad' || label == 'Precio'
          ? [FilteringTextInputFormatter.digitsOnly]
          : [],
    );
  }

  void _agregarProducto() {
    final provider = Provider.of<CotizacionProvider>(context, listen: false);
    final descripcion = descripcionController.text;
    final precio =
        double.tryParse(precioController.text.replaceAll(',', '')) ?? 0;
    final cantidad = _selectedQuantity == 'PERSONALIZADO'
        ? int.tryParse(cantidadPersonalizadaController.text) ?? 1
        : int.tryParse(_selectedQuantity) ?? 1;

    if (descripcion.isNotEmpty && precio > 0 && cantidad > 0) {
      final item = CotizacionItem(
        descripcion: descripcion,
        precioUnitario: precio,
        cantidad: cantidad,
      );

      provider.addItem(item);

      descripcionController.clear();
      precioController.clear();
      cantidadPersonalizadaController.clear();
    }
  }

  Widget _buildProductTable(CotizacionProvider provider) {
    return Container(
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
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1), // Espacio para botones de editar y eliminar
        },
        children: [
          TableRow(
            children: [
              _buildTableHeader('Cantidad'),
              _buildTableHeader('Descripción'),
              _buildTableHeader('Precio Unitario'),
              _buildTableHeader('Total'),
              SizedBox(), // Espacio para botones
            ],
          ),
          ...provider.items.map((item) {
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
                  child: Text('\$${item.precioUnitario.toStringAsFixed(2)}'),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('\$${item.total.toStringAsFixed(2)}'),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: () {
                        _editarProducto(context, item);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        provider.removeItem(item);
                      },
                    ),
                  ],
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
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

  void _guardarCliente(BuildContext context) {
    final provider = Provider.of<CotizacionProvider>(context, listen: false);
    final cliente = clienteController.text;
    final telefono = telefonoController.text;
    final tipoPersona = _selectedPersonType == 'PERSONALIZADO'
        ? personalizadoController.text
        : _selectedPersonType;

    provider.setCliente(cliente);
    provider.setTelefono(telefono);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CotizacionScreen()),
    );
  }

  Widget _buildInstructions(CotizacionProvider provider) {
    final total = provider.items.fold(0.0, (sum, item) => sum + item.total);

    return Column(
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
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSummary(CotizacionProvider provider) {
    final total = provider.items.fold(0.0, (sum, item) => sum + item.total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text(
          'RESUMEN:',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
              fontSize: 20),
        ),
        SizedBox(height: 10),
        Text(
          'Total a Pagar: \$${total.toStringAsFixed(2)}',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
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

                if (descripcionEdit.isNotEmpty &&
                    precioEdit > 0 &&
                    cantidadEdit > 0) {
                  final newItem = CotizacionItem(
                    descripcion: descripcionEdit,
                    precioUnitario: precioEdit,
                    cantidad: cantidadEdit,
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

  Widget _buildGuardarButton() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      //color: Colors.amber,
      child: Align(
        alignment: Alignment.center,
        child: ElevatedButton(
          onPressed: () {
            _guardarCliente(context);
          },
          child: Text(
            'Guardar',
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
      ),
    );
  }
}
