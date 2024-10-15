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
  final double gananciaTotal;
  final double ivaTotal;
  final String mesAno;

  ClienteData({
    required this.cliente,
    required this.totalMes,
    required this.gananciaTotal,
    required this.ivaTotal,
    required this.mesAno,
  });

  factory ClienteData.fromJson(Map<String, dynamic> json) {
    return ClienteData(
      cliente: json['clientes'],
      totalMes: double.parse(json['total_mes_iva']),
      gananciaTotal: double.parse(json['ganancia_Total']),
      ivaTotal: double.parse(json['iva_total']),
      mesAno: json['mes-año'],
    );
  }
}

class TotalMesData {
  final double gananciaTotal;
  final double ivaTotal;
  final double ventaTotal;
  final String mesAno;

  TotalMesData({
    required this.gananciaTotal,
    required this.ivaTotal,
    required this.ventaTotal,
    required this.mesAno,
  });

  factory TotalMesData.fromJson(Map<String, dynamic> json) {
    return TotalMesData(
      gananciaTotal: double.parse(json['ganancia_total']),
      ivaTotal: double.parse(json['iva_total']),
      ventaTotal: double.parse(json['venta_total']),
      mesAno: json['mes-año'],
    );
  }
}

double roundUpToNearestMultiple(double value, double multiple) {
  return (value / multiple).ceil() * multiple;
}

// Clase CustomChart
class CustomChart extends StatelessWidget {
  final List<ClienteData> data;
  final int month;
  final int year;
  final String title; // Título del gráfico
  final String dataKey; // Clave para seleccionar el dato a mostrar

  const CustomChart({
    Key? key,
    required this.data,
    required this.month,
    required this.year,
    required this.title,
    required this.dataKey, // Agregar el nuevo parámetro
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<ClienteData> monthlyData = data.where((d) {
      final monthYear = d.mesAno.split('-');
      return int.parse(monthYear[0]) - 1 == month &&
          int.parse(monthYear[1]) == year; // Filtra por mes y año
    }).toList();

    Map<String, double> totalsByClient = {};
    for (var clienteData in monthlyData) {
      double totalValue;
      switch (dataKey) {
        case 'ganancia_Total':
          totalValue =
              clienteData.gananciaTotal; // Aquí puedes cambiar la lógica
          break;
        case 'iva_total':
          totalValue = clienteData.ivaTotal;
          break;
        case 'total_mes_iva':
          totalValue = clienteData.totalMes; // Suponiendo que es el mismo valor
          break;
        default:
          totalValue = 0; // Valor por defecto si no coincide
          break;
      }

      totalsByClient[clienteData.cliente] =
          (totalsByClient[clienteData.cliente] ?? 0) + totalValue;
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
        showingTooltipIndicators: [1],
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
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Expanded(
                child: BarChart(
                  BarChartData(
                    minY: minY,
                    maxY: maxY,
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        axisNameWidget: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 50),
                            child: Text(
                              'clientes',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        axisNameSize:
                            30, // Ajusta este valor según sea necesario para el espacio
                        sideTitles: SideTitles(
                            showTitles:
                                false), // Oculta los títulos de cada barra
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
                                  fontWeight: FontWeight.bold,
                                ),
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
                          dashArray: [5, 5],
                        );
                      },
                      drawVerticalLine: false,
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        left: BorderSide(color: Colors.grey.shade300, width: 1),
                        bottom:
                            BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                    barGroups: barGroups,
                    barTouchData:
                        barTouchData(totalsByClient), // Pasa el mapa aquí
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BarTouchData barTouchData(Map<String, double> totalsByClient) {
  return BarTouchData(
    enabled: true,
    touchTooltipData: BarTouchTooltipData(
      //tooltipBgColor: Colors.blueGrey,
      getTooltipItem: (
        BarChartGroupData group,
        int groupIndex,
        BarChartRodData rod,
        int rodIndex,
      ) {
        final cliente = totalsByClient.keys
            .elementAt(group.x); // Obtener el nombre del cliente
        final total = rod.toY; // Obtener el valor correspondiente

        return BarTooltipItem(
          '$cliente\n${total.toStringAsFixed(2)}', // Muestra el nombre y el total
          TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
  );
}

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
    final response = await http.get(
      Uri.parse('http://$baseUrl/api/v1/estadisticas/totalclientesxmes'),
    );
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => ClienteData.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<List<TotalMesData>> fetchTotalMesData() async {
    final response = await http.get(
      Uri.parse('http://$baseUrl/api/v1/estadisticas/totalxmes'),
    );
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => TotalMesData.fromJson(data)).toList();
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
            return Center(child: Text('Aún no hay datos para mostrar'));
          } else {
            return Column(
              children: [
                // Fila de selección de meses y año
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
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
                                          offset: Offset(0, 3),
                                        )
                                      ]
                                    : null,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                                horizontal: 10.0,
                              ),
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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

                // Gráficos de Clientes
                // Gráficos de Clientes
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomChart(
                                data: snapshot.data!,
                                month: selectedMonth,
                                year: selectedYear,
                                title: 'Total de Ventas',
                                dataKey: 'total_mes_iva', // Agregar dataKey
                              ),
                            ),
                            Expanded(
                              child: CustomChart(
                                data: snapshot.data!,
                                month: selectedMonth,
                                year: selectedYear,
                                title: 'Ganancia Total',
                                dataKey: 'ganancia_Total', // Agregar dataKey
                              ),
                            ),
                            Expanded(
                              child: CustomChart(
                                data: snapshot.data!,
                                month: selectedMonth,
                                year: selectedYear,
                                title: 'IVA Total',
                                dataKey: 'iva_total', // Agregar dataKey
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8), // Espacio entre filas de gráficos
                      Expanded(
                        child: Row(
                          children: [
                            // Gráfico 4
                            Expanded(
                              child: FutureBuilder<List<TotalMesData>>(
                                future: fetchTotalMesData(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return Center(
                                        child: Text(
                                            'Error al cargar datos de totalxmes'));
                                  } else {
                                    return TotalMesChart(
                                      data: snapshot
                                          .data!, // Pasamos los datos del endpoint
                                      month: selectedMonth,
                                      year: selectedYear,
                                      title: 'Totales por mes',
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class TotalMesChart extends StatefulWidget {
  final List<TotalMesData> data;
  final int month; // Este parámetro puede no ser necesario para este gráfico
  final int year;
  final String title;

  const TotalMesChart({
    Key? key,
    required this.data,
    required this.month,
    required this.year,
    required this.title,
  }) : super(key: key);

  @override
  _TotalMesChartState createState() => _TotalMesChartState();
}

class _TotalMesChartState extends State<TotalMesChart> {
  double maxY = 0;

  @override
  void initState() {
    super.initState();
    _calculateMaxY();
  }

  void _calculateMaxY() {
    // Filtrar los datos para el año específico
    List<TotalMesData> yearlyData = widget.data.where((d) {
      final monthYear = d.mesAno.split('-');
      return int.parse(monthYear[1]) == widget.year;
    }).toList();

    // Crear listas de valores para los 12 meses
    List<double> gananciaValues = List.filled(12, 0.0);
    List<double> ivaValues = List.filled(12, 0.0);
    List<double> ventaValues = List.filled(12, 0.0);

    // Llenar las listas con los datos correspondientes
    for (var d in yearlyData) {
      int monthIndex = int.parse(d.mesAno.split('-')[0]) -
          1; // Obtener el índice del mes (0-11)
      gananciaValues[monthIndex] += d.gananciaTotal;
      ivaValues[monthIndex] += d.ivaTotal;
      ventaValues[monthIndex] += d.ventaTotal;
    }

    double maxGanancia = gananciaValues.reduce((a, b) => a > b ? a : b);
    double maxIva = ivaValues.reduce((a, b) => a > b ? a : b);
    double maxVenta = ventaValues.reduce((a, b) => a > b ? a : b);

    // Obtener el máximo general y ajustar para el eje Y
    maxY = (maxGanancia > maxIva && maxGanancia > maxVenta)
        ? maxGanancia
        : (maxIva > maxGanancia && maxIva > maxVenta)
            ? maxIva
            : maxVenta;

    // Aumentar el máximo para que tenga un margen
    maxY *= 1.2; // Aumentar el 10% del valor máximo
  }

  void _increaseMaxY() {
    setState(() {
      maxY *= 2; // Duplicar el máximo
    });
  }

  void _decreaseMaxY() {
    setState(() {
      maxY /= 2; // Reducir a la mitad el máximo
      if (maxY < 0) maxY = 1; // Asegúrate de que maxY no sea negativo
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar los datos para el año específico
    List<TotalMesData> yearlyData = widget.data.where((d) {
      final monthYear = d.mesAno.split('-');
      return int.parse(monthYear[1]) == widget.year;
    }).toList();

    if (yearlyData.isEmpty) {
      return Center(child: Text('No hay datos para este año.'));
    }

    // Crear listas de valores para los 12 meses
    List<double> gananciaValues = List.filled(12, 0.0);
    List<double> ivaValues = List.filled(12, 0.0);
    List<double> ventaValues = List.filled(12, 0.0);

    // Llenar las listas con los datos correspondientes
    for (var d in yearlyData) {
      int monthIndex = int.parse(d.mesAno.split('-')[0]) -
          1; // Obtener el índice del mes (0-11)
      gananciaValues[monthIndex] += d.gananciaTotal;
      ivaValues[monthIndex] += d.ivaTotal;
      ventaValues[monthIndex] += d.ventaTotal;
    }

    // Meses del año para etiquetas
    List<String> monthLabels = [
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

    return SizedBox(
      height: 300, // Cambia la altura aquí si es necesario
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          color: Colors.white, // Color de fondo de la gráfica
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize:
                              60, // Aumentar el espacio reservado para las etiquetas
                          getTitlesWidget: (value, meta) {
                            // Ajustar la frecuencia de las etiquetas
                            return value % 1000 ==
                                    0 // Mostrar etiquetas en intervalos de 1000
                                ? Text(
                                    value.toString(),
                                    style: const TextStyle(
                                      color: Colors.blueGrey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : const SizedBox.shrink();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 38,
                          getTitlesWidget: (value, meta) {
                            // Mostrar solo las etiquetas de enero, abril, julio y octubre
                            if (value == 0 ||
                                value == 1 ||
                                value == 2 ||
                                value == 3 ||
                                value == 4 ||
                                value == 5 ||
                                value == 6 ||
                                value == 7 ||
                                value == 8 ||
                                value == 9 ||
                                value == 10 ||
                                value == 11) {
                              return Text(
                                monthLabels[value.toInt()],
                                style: const TextStyle(
                                  color: Colors.blueGrey,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            } else {
                              return const SizedBox
                                  .shrink(); // Evita que se muestre un título si no es enero, abril, julio o octubre
                            }
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                          color: Colors.blueGrey,
                          width: 0.5), // Cambiar color y ancho
                    ),
                    minX: 0,
                    maxX: 11, // Para mostrar los 12 meses
                    minY: 0,
                    maxY: maxY, // Usar el máximo ajustado
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(gananciaValues.length, (index) {
                          return FlSpot(index.toDouble(),
                              gananciaValues[index].clamp(0.0, maxY));
                        }),
                        isCurved: true,
                        color: Colors.green,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(show: false),
                      ),
                      LineChartBarData(
                        spots: List.generate(ivaValues.length, (index) {
                          return FlSpot(index.toDouble(),
                              ivaValues[index].clamp(0.0, maxY));
                        }),
                        isCurved: true,
                        color: Colors.red,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(show: false),
                      ),
                      LineChartBarData(
                        spots: List.generate(ventaValues.length, (index) {
                          return FlSpot(index.toDouble(),
                              ventaValues[index].clamp(0.0, maxY));
                        }),
                        isCurved: true,
                        color: Colors.blue,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                    lineTouchData: LineTouchData(
  touchTooltipData: LineTouchTooltipData(
    getTooltipColor: (touchedSpot) => const Color.fromARGB(255, 64, 91, 105),
    tooltipPadding: const EdgeInsets.all(8),
    tooltipRoundedRadius: 8,
    getTooltipItems: (touchedSpots) {
      return touchedSpots.map((touchedSpot) {
        String label;
        switch (touchedSpot.barIndex) {
          case 0:
            label = 'Ganancia';
            break;
          case 1:
            label = 'IVA';
            break;
          case 2:
            label = 'Ventas';
            break;
          default:
            label = '';
        }
        return LineTooltipItem(
          '$label: ${touchedSpot.y}',
          const TextStyle(
            color: Colors.white, // Cambia el color del texto a blanco aquí
            fontWeight: FontWeight.bold,
          ),
        );
      }).toList();
    },
  ),
),

                  ),
                ),
              ),
              // Botones para ajustar el rango

              // Leyenda
              // Leyenda y botones para ajustar el rango
              // Botones para ajustar el rango y Leyenda
              Container(
                //color: Colors.red,
                height: 30, // Ajusta la altura aquí
                child: Row(
                  children: [
                    IconButton(
                      iconSize: 18,
                      icon: Icon(Icons.add),
                      onPressed: _increaseMaxY,
                    ),
                    IconButton(
                      iconSize: 18,
                      icon: Icon(Icons.remove),
                      onPressed: _decreaseMaxY,
                    ),
                    Expanded(
                      // Expande este espacio para centrar las leyendas
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center, // Centrar las leyendas
                        children: [
                          _buildLegend(Colors.green, 'Ganancia'),
                          SizedBox(width: 20), // Espacio entre leyendas
                          _buildLegend(Colors.red, 'IVA'),
                          SizedBox(width: 20), // Espacio entre leyendas
                          _buildLegend(Colors.blue, 'Ventas'),
                          SizedBox(width: 70),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 15,
          height: 15,
          color: color,
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
