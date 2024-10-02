import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

// Modelo de datos
class ClienteData {
  final String cliente;
  final double totalMes;
  final String mesAno;

  ClienteData({required this.cliente, required this.totalMes, required this.mesAno});

  factory ClienteData.fromJson(Map<String, dynamic> json) {
    return ClienteData(
      cliente: json['clientes'],
      totalMes: double.parse(json['total_mes']),
      mesAno: json['mes-año'],
    );
  }
}

// Widget para mostrar el gráfico
class ClienteChart extends StatefulWidget {
  final List<ClienteData> data;

  const ClienteChart({Key? key, required this.data}) : super(key: key);

  @override
  _ClienteChartState createState() => _ClienteChartState();
}

class _ClienteChartState extends State<ClienteChart> {
  double _minX = 0;
  double _maxX = 11; // Suponiendo 12 meses
  double _zoomFactor = 1.0;

  Map<int, Map<String, double>> _totalsByMonthAndClient = {};
  List<BarChartGroupData> _barGroups = [];

  void _processData() {
    // Procesar datos
    for (var clienteData in widget.data) {
      final monthYear = clienteData.mesAno.split('-');
      final month = int.parse(monthYear[0]) - 1;

      _totalsByMonthAndClient.putIfAbsent(month, () => {});
      _totalsByMonthAndClient[month]![clienteData.cliente] =
          (_totalsByMonthAndClient[month]![clienteData.cliente] ?? 0) + clienteData.totalMes;
    }

    List<String> clientes = _totalsByMonthAndClient.values.expand((clientesData) => clientesData.keys).toSet().toList();

    for (int month = 0; month < 12; month++) {
      List<BarChartRodData> barRods = [];
      for (var cliente in clientes) {
        double total = _totalsByMonthAndClient[month]?[cliente] ?? 0.0;
        barRods.add(BarChartRodData(
          toY: total,
          color: Colors.primaries[clientes.indexOf(cliente) % Colors.primaries.length].withOpacity(0.7),
          width: 16,
          borderRadius: BorderRadius.circular(8),
        ));
      }
      _barGroups.add(BarChartGroupData(x: month, barRods: barRods));
    }
  }

  @override
  void initState() {
    super.initState();
    _processData(); // Procesar datos al iniciar
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar grupos de barras por el rango
    final filteredBarGroups = _barGroups.where((group) => group.x >= _minX && group.x <= _maxX).toList();

    return GestureDetector(
      onScaleUpdate: (details) {
        setState(() {
          // Zoom in/out
          if (details.scale != 1.0) {
            _zoomFactor *= details.scale;
            _zoomFactor = _zoomFactor.clamp(1.0, 5.0); // Limita el zoom
          }
          // Paneo
          _minX += details.focalPoint.dx > 0 ? 1 : -1;
          _maxX += details.focalPoint.dx > 0 ? 1 : -1;
        });
      },
      child: SizedBox(
        height: 400,
        child: BarChart(
          BarChartData(
            barGroups: filteredBarGroups,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        months[value.toInt()],
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
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
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              horizontalInterval: 10000,
              getDrawingHorizontalLine: (value) {
                return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1, dashArray: [5, 5]);
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
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipMargin: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  String clienteName = _totalsByMonthAndClient[group.x]!.keys.elementAt(rodIndex);
                  double totalValue = rod.toY;
                  return BarTooltipItem(
                    '$clienteName\n\$${totalValue.toStringAsFixed(2)}',
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Pantalla principal
class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({Key? key}) : super(key: key);

  @override
  _EstadisticasScreenState createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  late Future<List<ClienteData>> futureData;

  @override
  void initState() {
    super.initState();
    futureData = fetchClienteData();
  }

  Future<List<ClienteData>> fetchClienteData() async {
    final response = await http.get(Uri.parse('http://192.168.1.13:3000/api/v1/estadisticas/totalclientesxmes'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => ClienteData.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas de Clientes')),
      body: FutureBuilder<List<ClienteData>>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Consumo Total por Cliente por Mes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ClienteChart(data: snapshot.data!),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
