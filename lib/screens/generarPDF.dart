import 'dart:io';
import 'package:cotizacion/screens/calculos.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show Uint8List, rootBundle;

Future<void> generatePdf(CotizacionProvider provider) async {
  // En el método generatePdf dentro de CotizacionScreen
  final codxIconData = await _loadAsset('assets/codxtransparente.png');
  final facebookIconData = await _loadAsset('assets/facebook.png');
  final whatsappIconData = await _loadAsset('assets/whatsapp.png');
  final webIconData = await _loadAsset('assets/web.png');
  final emailIconData = await _loadAsset('assets/email.png');
  final ubiIconData = await _loadAsset('assets/ubi.png');

  final codxIcon = pw.MemoryImage(codxIconData);
  final facebookIcon = pw.MemoryImage(facebookIconData);
  final whatsappIcon = pw.MemoryImage(whatsappIconData);
  final webIcon = pw.MemoryImage(webIconData);
  final emailIcon = pw.MemoryImage(emailIconData);
  final ubiIcon = pw.MemoryImage(ubiIconData);

  final pdf = pw.Document();
  final date = DateFormat('dd/MM/yyyy').format(DateTime.now());
  final validUntil =
      DateFormat('dd/MM/yyyy').format(DateTime.now().add(Duration(days: 3)));

  const double marginAll = 40; // Márgenes para el contenido principal

  const double ivaRate = 0.16; // Tasa de IVA

  double subtotal = provider.items.fold(0, (sum, item) {
    final precioVenta =
        item.precioUnitario * (1 + item.porcentajeGanancia / 100);
    return sum + (precioVenta * item.cantidad);
  });
  double iva = subtotal * ivaRate;
  double total = subtotal + iva;

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
            pw.Container(
              color: PdfColors.black,
              width: double.infinity, // Ocupa todo el ancho
              child: pw.Padding(
                padding: pw.EdgeInsets.symmetric(
                    vertical: 10), // Añadimos un poco de relleno vertical
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.only(right: 30),
                      child: pw.Image(codxIcon,
                          width: 80, height: 60), // Icono de Facebook
                    ),
                  ],
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Container(
                margin: pw.EdgeInsets.only(
                    top: marginAll, bottom: marginAll, left: 30, right: 30),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('COTIZACIÓN',
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 50),
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
                            pw.SizedBox(height: 10),
                            pw.Row(
                              children: [
                                pw.Text('Correo:',
                                    style: pw.TextStyle(fontSize: 12)),
                                pw.SizedBox(width: 5),
                                pw.Text(provider.email,
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
                    pw.SizedBox(height: 30),
                    pw.Text(
                      'Estimado cliente, ponemos a su consideración la cotización de los productos que nos ha solicitado, cualquier duda estamos a sus órdenes.',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 30),
                    pw.Table.fromTextArray(
                      context: context,
                      data: <List<String>>[
                        <String>[
                          'Cantidad',
                          'Descripción',
                          'Precio Unitario', // Mantén el texto "Precio Unitario"
                          'Total',
                        ],
                        ...provider.items.map((item) {
                          // Calcula el precio de venta
                          final precioVenta = item.precioUnitario *
                              (1 + item.porcentajeGanancia / 100);
                          return [
                            item.cantidad.toString(),
                            item.descripcion,
                            formatCurrency(
                                precioVenta), // Muestra el precio de venta en lugar del precio unitario
                            formatCurrency(precioVenta *
                                item.cantidad), // Total calculado con el precio de venta
                          ];
                        }),
                      ],
                      border: pw.TableBorder.all(),
                      headerStyle: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      headerDecoration: pw.BoxDecoration(
                        color: PdfColors.black,
                      ),
                      cellStyle: pw.TextStyle(fontSize: 9),
                      columnWidths: {
                        0: pw.FixedColumnWidth(4),
                        1: pw.FixedColumnWidth(30),
                        2: pw.FixedColumnWidth(5),
                        3: pw.FixedColumnWidth(5),
                      },
                      headerAlignments: {
                        0: pw.Alignment
                            .center, // Centra el texto del encabezado 'Cantidad'
                        1: pw.Alignment
                            .center, // Centra el texto del encabezado 'Descripción'
                        2: pw.Alignment
                            .center, // Centra el texto del encabezado 'Precio Unitario'
                        3: pw.Alignment
                            .center, // Centra el texto del encabezado 'Total'
                      },
                      cellAlignments: {
                        0: pw.Alignment
                            .center, // Centra el texto de la columna 'Cantidad'
                        1: pw.Alignment
                            .centerLeft, // Centra el texto de la columna 'Descripción'
                        2: pw.Alignment
                            .center, // Centra el texto de la columna 'Precio Unitario'
                        3: pw.Alignment
                            .center, // Centra el texto de la columna 'Total'
                      },
                    ),
                    pw.SizedBox(height: 20),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.SizedBox(height: 37),
                            pw.Text(
                              'Cantidad con letra: ',
                              style: pw.TextStyle(fontSize: 10),
                            ),
                            pw.Container(
                              width: 475,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.grey300,
                                border: pw.Border(
                                  bottom: pw.BorderSide(
                                      width: 1, color: PdfColors.black),
                                ),
                              ),
                              child: pw.Text(
                                NumberToWords.convertDouble(total),
                                style: pw.TextStyle(
                                    fontSize: 9, letterSpacing: -0.5),
                              ),
                            )
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildPriceRow(
                                'Subtotal', formatCurrency(subtotal)),
                            _buildPriceRow('IVA', '${formatCurrency(iva)}'),
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Container(
                                  margin:
                                      pw.EdgeInsets.only(left: -60, right: 0),
                                  width: 40,
                                  color: PdfColors.black,
                                  padding: pw.EdgeInsets.all(4),
                                  child: pw.Text(
                                    'Total',
                                    style: pw.TextStyle(
                                        fontSize: 10, color: PdfColors.white),
                                    textAlign: pw.TextAlign.left,
                                  ),
                                ),
                                pw.SizedBox(width: 1),
                                pw.Container(
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.grey300,
                                    border: pw.Border(
                                      bottom: pw.BorderSide(
                                          width: 1, color: PdfColors.black),
                                    ),
                                  ),
                                  margin: pw.EdgeInsets.only(left: -1, top: 1),
                                  padding: pw.EdgeInsets.only(
                                      right: 10, left: 10, top: 6),
                                  child: pw.Text(
                                    formatCurrency(total),
                                    style: pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 50),
                    pw.Spacer(),
                    pw.Container(
                      padding: pw.EdgeInsets.all(0),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(),
                        color: PdfColors
                            .grey300, // Color gris para el contenedor del resto del contenido
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                              // Contenedor para el título "Notas"
                              padding: pw.EdgeInsets.all(5),
                              width: double.infinity,
                              color: PdfColors
                                  .black, // Color negro para el contenedor del título
                              child: pw.Align(
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  'Notas:',
                                  style: pw.TextStyle(
                                    color: PdfColors
                                        .white, // Color blanco para el texto del título
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              )),
                          pw.Container(
                            padding: pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '1. Los precios unitarios son expresados en Moneda Nacional + IVA 16% aplicable.\n'
                              '2. El pedido requerirá al menos un pago inicial del 50%, con el resto a liquidar en el momento de la entrega.\n'
                              '3. Enviar comprobante de depósito, facilitar datos de facturación y lugar de entrega.\n'
                              '4. Posterior a la fecha de vigencia, por favor cotizar nuevamente.\n'
                              '5. Los precios pueden variar sin previo aviso.',
                              style: pw.TextStyle(
                                color: PdfColors
                                    .black, // Color negro para el texto del contenido
                                fontSize: 9,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 30),
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
                padding: pw.EdgeInsets.all(
                    10), // Añadimos un poco de relleno vertical
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Image(facebookIcon,
                        width: 10, height: 10), // Icono de Facebook
                    pw.SizedBox(width: 2),
                    pw.Text(' CODX',
                        style:
                            pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                    pw.SizedBox(width: 15),
                    pw.Image(whatsappIcon,
                        width: 10, height: 10), // Icono de Facebook
                    pw.SizedBox(width: 2),
                    pw.Text('744 533 8531',
                        style:
                            pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                    pw.SizedBox(width: 15),
                    pw.Image(webIcon, width: 10, height: 10),
                    pw.SizedBox(width: 2),
                    pw.Text(' www.codxtech.com',
                        style:
                            pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                    pw.SizedBox(width: 15),
                    pw.Image(emailIcon, width: 10, height: 10),
                    pw.SizedBox(width: 2),
                    pw.Text(' ventas@codxtech.com',
                        style:
                            pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                    pw.SizedBox(width: 15),
                    pw.Image(ubiIcon, width: 10, height: 10),
                    pw.SizedBox(width: 2),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                            'J.R. Cabrillo No. 90, Local B, Fraccionamiento Hornos',
                            style: pw.TextStyle(
                                color: PdfColors.white, fontSize: 8)),
                        pw.Text(
                            ' Insurgentes, C.P. 39355. Acapulco de Juárez, Gro',
                            style: pw.TextStyle(
                                color: PdfColors.white, fontSize: 8)),
                      ],
                    ),
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

Future<Uint8List> _loadAsset(String path) async {
  final data = await rootBundle.load(path);
  return data.buffer.asUint8List();
}

pw.Widget _buildPriceRow(String title, String value) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Container(
        margin: pw.EdgeInsets.only(left: -60, right: 0),
        width: 50, // Ancho definido para el container del título
        color: PdfColors.black,
        padding: pw.EdgeInsets.all(4),
        child: pw.Text(
          title,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.white),
          textAlign: pw.TextAlign.left,
        ),
      ),
      pw.SizedBox(width: 1),
      pw.Container(
        margin: pw.EdgeInsets.only(
          left: 0,
        ),
        padding: pw.EdgeInsets.only(right: 10, left: 10, top: 6),
        child: pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10),
        ),
      ),
    ],
  );
}

class NumberToWords {
  static final List<String> _units = [
    '',
    'un',
    'dos',
    'tres',
    'cuatro',
    'cinco',
    'seis',
    'siete',
    'ocho',
    'nueve',
    'diez',
    'once',
    'doce',
    'trece',
    'catorce',
    'quince',
    'dieciséis',
    'diecisiete',
    'dieciocho',
    'diecinueve',
  ];

  static final List<String> _tens = [
    '',
    'diez',
    'veinte',
    'treinta',
    'cuarenta',
    'cincuenta',
    'sesenta',
    'setenta',
    'ochenta',
    'noventa',
  ];

  static final List<String> _hundreds = [
    '',
    'ciento',
    'doscientos',
    'trescientos',
    'cuatrocientos',
    'quinientos',
    'seiscientos',
    'setecientos',
    'ochocientos',
    'novecientos',
  ];

  static String convert(int number) {
    if (number == 0) {
      return 'cero';
    }
    if (number < 20) {
      return _units[number];
    }
    if (number < 100) {
      return _tens[number ~/ 10] +
          (number % 10 == 0 ? '' : ' y ' + _units[number % 10]);
    }
    if (number < 1000) {
      if (number == 100) {
        return 'cien';
      }
      return _hundreds[number ~/ 100] +
          (number % 100 == 0 ? '' : ' ' + convert(number % 100));
    }
    if (number < 1000000) {
      if (number < 2000) {
        return 'mil' + (number % 1000 == 0 ? '' : ' ' + convert(number % 1000));
      }
      return convert(number ~/ 1000) +
          ' mil' +
          (number % 1000 == 0 ? '' : ' ' + convert(number % 1000));
    }
    return 'Número fuera de rango';
  }

  static String convertDouble(double number) {
    int integerPart = number.truncate();
    int decimalPart = ((number - integerPart) * 100).round();

    String integerPartInWords = convert(integerPart);
    String decimalPartInWords = convert(decimalPart);

    String pesos = integerPart == 1 ? 'PESO' : 'PESOS';
    String centavos = decimalPart == 1 ? 'CENTAVO' : 'CENTAVOS';

    return '${integerPartInWords.toUpperCase()} $pesos CON ${decimalPartInWords.toUpperCase()} $centavos';
  }
}
