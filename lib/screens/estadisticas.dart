import 'dart:convert';
import 'package:cotizacion/custom_app_bar.dart';
import 'package:cotizacion/ip.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

// Modelo de datos
class ClienteData {
  final String cliente;
  final double totalMes;
  final String mesAno;

  ClienteData(
      {required this.cliente, required this.totalMes, required this.mesAno});

  factory ClienteData.fromJson(Map<String, dynamic> json) {
    return ClienteData(
      cliente: json['clientes'],
      totalMes: double.parse(json['total_mes']),
      mesAno: json['mes-año'],
    );
  }
}

double roundUpToNearestMultiple(double value, double multiple) {
  return (value / multiple).ceil() * multiple;
}

class ClienteChart extends StatelessWidget {
  final List<ClienteData> data;
  final int month;
  final int year;

  const ClienteChart(
      {Key? key, required this.data, required this.month, required this.year})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<ClienteData> monthlyData = data.where((d) {
      final monthYear = d.mesAno.split('-');
      return int.parse(monthYear[0]) - 1 == month &&
          int.parse(monthYear[1]) == year; // Filtra por mes y año
    }).toList();

    Map<String, double> totalsByClient = {};
    for (var clienteData in monthlyData) {
      totalsByClient[clienteData.cliente] =
          (totalsByClient[clienteData.cliente] ?? 0) + clienteData.totalMes;
    }

    if (totalsByClient.isEmpty) {
      return Center(child: Text('No hay datos para este mes y año.'));
    }

    List<BarChartGroupData> barGroups = [];
    int index = 0;

    totalsByClient.forEach((cliente, total) {
      barGroups.add(BarChartGroupData(
        x: index++,
        barRods: [
          BarChartRodData(
            toY: total,
            color: Colors.primaries[index % Colors.primaries.length]
                .withOpacity(0.7),
            width: 16,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
        showingTooltipIndicators: [0],
      ));
    });

    double maxY = roundUpToNearestMultiple(
        totalsByClient.values.reduce((a, b) => a > b ? a : b), 5000);
    double minY = 0;

    return SizedBox(
      height: 300, // Cambia la altura aquí
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          color: Colors.white, // Color de fondo de la gráfica
          padding: const EdgeInsets.all(16.0),
          child: BarChart(
            BarChartData(
              minY: minY,
              maxY: maxY,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= totalsByClient.length)
                        return Container();
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          totalsByClient.keys.elementAt(value.toInt()),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 10000,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          '${value.toInt()}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 10000,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                      dashArray: [5, 5]);
                },
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300, width: 1),
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              barGroups: barGroups,
              barTouchData: barTouchData,
            ),
          ),
        ),
      ),
    );
  }
}

BarTouchData get barTouchData => BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        getTooltipItem: (
          BarChartGroupData group,
          int groupIndex,
          BarChartRodData rod,
          int rodIndex,
        ) {
          return BarTooltipItem(
            '${rod.toY.round()}',
            TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );

// Pantalla principal
class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({Key? key}) : super(key: key);

  @override
  _EstadisticasScreenState createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<ClienteData>> futureData;
  late int selectedMonth;
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    futureData = fetchClienteData();
    selectedMonth = 9; // Iniciar en el primer mes
    selectedYear = DateTime.now().year; // Año actual
  }

  Future<List<ClienteData>> fetchClienteData() async {
    final response = await http.get(Uri.parse(
        'http://$baseUrl:3000/api/v1/estadisticas/totalclientesxmes'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => ClienteData.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load data');
    }
  }

  void updateMonth(int month) {
    setState(() {
      selectedMonth = month;
    });
  }

  // Método para seleccionar solo el año
  Future<void> selectYear(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecciona un año'),
          content: SizedBox(
            height: 200,
            width: 200,
            child: ListView.builder(
              itemCount:
                  20, // Puedes ajustar el número de años que desees mostrar
              itemBuilder: (context, index) {
                int year = DateTime.now().year -
                    index; // Años desde el actual hacia atrás
                return ListTile(
                  title: Text(year.toString()),
                  onTap: () {
                    setState(() {
                      selectedYear = year; // Actualiza el año seleccionado
                    });
                    Navigator.of(context).pop(); // Cierra el diálogo
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  bool _isDarkMode = false; // Estado del modo oscuro

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFf7f8fa),
      appBar: CustomAppBar(
        isDarkMode: _isDarkMode,
        toggleDarkMode: _toggleDarkMode,
        title: 'Estadísticas', // Título específico para esta pantalla
      ),
      body: FutureBuilder<List<ClienteData>>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Column(
              children: [
                // Fila de selección de meses y año
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Selector de Meses
                      Row(
                        children: List.generate(12, (index) {
                          const months = [
                            'Ene',
                            'Feb',
                            'Mar',
                            'Abr',
                            'May',
                            'Jun',
                            'Jul',
                            'Ago',
                            'Sep',
                            'Oct',
                            'Nov',
                            'Dic'
                          ];
                          return GestureDetector(
                            onTap: () => updateMonth(index),
                            child: Container(
                              decoration: BoxDecoration(
                                color: selectedMonth == index
                                    ? Color(0xFF001F3F)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: selectedMonth == index
                                    ? [
                                        BoxShadow(
                                            color: Colors.blueAccent
                                                .withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: Offset(0, 3))
                                      ]
                                    : null,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 10.0),
                              margin: const EdgeInsets.only(
                                  right: 8.0), // Espacio entre meses
                              child: Text(
                                months[index],
                                style: TextStyle(
                                  color: selectedMonth == index
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      // Selector de Año
                      Row(
                        children: [
                          Text(
                            'Año: $selectedYear',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () => selectYear(
                                context), // Muestra el selector de año
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Gráfico de Clientes
                Expanded(
                  child: ClienteChart(
                      data: snapshot.data!,
                      month: selectedMonth,
                      year: selectedYear),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
