import 'package:cotizacion2/screens/calculos.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

class CotizacionScreen extends StatelessWidget {
  final descripcionController = TextEditingController();
  final precioController = TextEditingController();
  final cantidadController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CotizacionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cotización',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 27, 69),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: 100,
              height: 100,
              //color: Colors.blue[900],
              child: Align(
                alignment: Alignment.center,
                child: Text('CODX',
                    style: TextStyle(color: Colors.white, fontSize: 30),
                    textAlign: TextAlign.center),
              ),
            ),
          ),
        ],
        leading: BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 200),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                'COTIZACIÓN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Cliente:', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 5),
                          Text('${provider.tipoPersona} ${provider.cliente}',
                              style: TextStyle(fontSize: 16)),
                          SizedBox(height: 50),
                        ],
                      ),
                      Row(
                        children: [
                          Text('Teléfono:', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 5),
                          Text(provider.telefono,
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Fecha:', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 10),
                          Text('${DateTime.now().toLocal()}'.split(' ')[0],
                              style: TextStyle(fontSize: 16)),
                          SizedBox(height: 50),
                        ],
                      ),
                      Row(
                        children: [
                          Text('Válido hasta:', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 10),
                          Text(
                              '${DateTime.now().add(Duration(days: 3)).toLocal()}'
                                  .split(' ')[0],
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Estimado cliente, ponemos a su consideración la cotización de los productos que nos ha solicitado, cualquier duda estamos a sus órdenes.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 20),
              Table(
                border: TableBorder.all(color: Colors.black),
                columnWidths: {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(3),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Cantidad',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Descripción',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Precio Unitario',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Total',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
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
                          child: Text(formatCurrency(item.precioUnitario)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(formatCurrency(item.total)),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cantidad con letra: ${_convertirNumero(provider.total)}',
                    style: TextStyle(fontSize: 14),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Subtotal: ${formatCurrency(provider.subtotal)}',
                          style: TextStyle(fontSize: 14)),
                      Text('IVA 16% : ${formatCurrency(provider.iva)}',
                          style: TextStyle(fontSize: 14)),
                      Text('Total: ${formatCurrency(provider.total)}',
                          style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 40),
              Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                ),
                child: Text(
                  'Notas:\n1. Los precios unitarios son expresados en Moneda Nacional + IVA 16% aplicable.\n2. El pedido requerirá al menos un pago inicial del 50%, con el resto a liquidar en el momento de la entrega.\n3. Enviar comprobante de depósito, facilitar datos de facturación y lugar de entrega.\n4. Posterior a la fecha de vigencia, por favor cotizar nuevamente.\n5. Los precios pueden variar sin previo aviso.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Text(
                  '© 2024 CODX',
                  style: TextStyle(fontSize: 12, color: Colors.black),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await _generatePdf(provider);
                  },
                  child: Text('Download PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatCurrency(double amount) {
    final format = NumberFormat("#,##0.00", "en_US");
    return '\$${format.format(amount)}';
  }

  String _convertirNumero(double numero) {
    if (numero == 0) {
      return 'CERO PESOS';
    }

    final formatter = NumberFormat.currency(locale: 'es_ES', symbol: '');
    String words = formatter.format(numero).toUpperCase();
    return words;
  }

  Future<void> _generatePdf(CotizacionProvider provider) async {
    // En el método _generatePdf dentro de CotizacionScreen
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
    );

    final pdf = pw.Document();
    final date = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final validUntil =
        DateFormat('dd/MM/yyyy').format(DateTime.now().add(Duration(days: 3)));

    const double marginAll = 50; // Márgenes para el contenido principal

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginLeft: 0,
          marginRight: 0,
          marginTop: 0,
          marginBottom: 0,
        ),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Expanded(
                child: pw.Container(
                  margin: pw.EdgeInsets.all(marginAll),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('COTIZACIÓN',
                          style: pw.TextStyle(
                              fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 20),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                children: [
                                  pw.Text('Cliente:',
                                      style: pw.TextStyle(fontSize: 12)),
                                  pw.SizedBox(width: 5),
                                  pw.Text(
                                      '${provider.tipoPersona} ${provider.cliente}',
                                      style: pw.TextStyle(fontSize: 12)),
                                  pw.SizedBox(width: 50),
                                ],
                              ),
                              pw.SizedBox(height: 10),
                              pw.Row(
                                children: [
                                  pw.Text('Teléfono:',
                                      style: pw.TextStyle(fontSize: 12)),
                                  pw.SizedBox(width: 5),
                                  pw.Text(provider.telefono,
                                      style: pw.TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                children: [
                                  pw.Text('Fecha:',
                                      style: pw.TextStyle(fontSize: 12)),
                                  pw.SizedBox(width: 10),
                                  pw.Text(date,
                                      style: pw.TextStyle(fontSize: 12)),
                                  pw.SizedBox(width: 50),
                                ],
                              ),
                              pw.SizedBox(height: 10),
                              pw.Row(
                                children: [
                                  pw.Text('Válido hasta:',
                                      style: pw.TextStyle(fontSize: 12)),
                                  pw.SizedBox(width: 10),
                                  pw.Text(validUntil,
                                      style: pw.TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'Estimado cliente, ponemos a su consideración la cotización de los productos que nos ha solicitado, cualquier duda estamos a sus órdenes.',
                        style: pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Table.fromTextArray(
                        context: context,
                        data: <List<String>>[
                          <String>[
                            'Cantidad',
                            'Descripción',
                            'Precio Unitario',
                            'Total'
                          ],
                          ...provider.items.map((item) => [
                                item.cantidad.toString(),
                                item.descripcion,
                                formatCurrency(item.precioUnitario),
                                formatCurrency(item.total),
                              ]),
                        ],
                        border: pw.TableBorder.all(),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Cantidad con letra: ${_convertirNumero(provider.total)}',
                            style: pw.TextStyle(fontSize: 12),
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                  'Subtotal: ${formatCurrency(provider.subtotal)}',
                                  style: pw.TextStyle(fontSize: 12)),
                              pw.Text(
                                  'IVA 16%: ${formatCurrency(provider.iva)}',
                                  style: pw.TextStyle(fontSize: 12)),
                              pw.Text(
                                  'Total: ${formatCurrency(provider.total)}',
                                  style: pw.TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 40),
                      pw.Container(
                        padding: pw.EdgeInsets.all(8.0),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(),
                        ),
                        child: pw.Text(
                          'Notas:\n1. Los precios unitarios son expresados en Moneda Nacional + IVA 16% aplicable.\n2. El pedido requerirá al menos un pago inicial del 50%, con el resto a liquidar en el momento de la entrega.\n3. Enviar comprobante de depósito, facilitar datos de facturación y lugar de entrega.\n4. Posterior a la fecha de vigencia, por favor cotizar nuevamente.\n5. Los precios pueden variar sin previo aviso.',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Center(
                        child: pw.Text('© 2024 CODX',
                            style: pw.TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Container(
                color: PdfColors.black,
                width: double.infinity, // Ocupa todo el ancho
                child: pw.Padding(
                  padding: pw.EdgeInsets.symmetric(
                      vertical: 10), // Añadimos un poco de relleno vertical
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.Image(logoImage, width: 100, height: 100),
                      pw.Text('Facebook: facebook.com/empresa',
                          style: pw.TextStyle(
                              color: PdfColors.white, fontSize: 8)),
                      pw.SizedBox(width: 20),
                      pw.Text('Web: www.empresa.com',
                          style: pw.TextStyle(
                              color: PdfColors.white, fontSize: 8)),
                      pw.SizedBox(width: 20),
                      pw.Text('Email: contacto@empresa.com',
                          style: pw.TextStyle(
                              color: PdfColors.white, fontSize: 8)),
                      pw.SizedBox(width: 20),
                      pw.Text('Dirección: Calle Falsa 123',
                          style: pw.TextStyle(
                              color: PdfColors.white, fontSize: 8)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
