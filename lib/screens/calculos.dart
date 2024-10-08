import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:number_to_words/number_to_words.dart';

class CotizacionProvider extends ChangeNotifier {
  String? _folio;
  String _cliente = '';
  String _telefono = '';
  String _email = '';
  String _tipoPersona = '';

  // Getter para folio
  String? get folio => _folio;

// Setter para folio
  void setFolio(String folio) {
    _folio = folio;
    notifyListeners();
  }

  String get cliente => _cliente;
  String get telefono => _telefono;
  String get email => _email;
  String get tipoPersona => _tipoPersona;
  List<CotizacionItem> items = [];

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  double get iva => subtotal * 0.16;

  double get total => subtotal + iva;

  void setCliente(String cliente) {
    _cliente = cliente;
    notifyListeners();
  }

  void setTelefono(String telefono) {
    _telefono = telefono;
    notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void setTipoPersona(String tipoPersona) {
    _tipoPersona = tipoPersona;
    notifyListeners();
  }

  void addItem(CotizacionItem item) {
    items.add(item);
    notifyListeners();
  }

  void removeItem(CotizacionItem item) {
    items.remove(item);
    notifyListeners();
  }

  void updateItem(CotizacionItem oldItem, CotizacionItem newItem) {
    final index = items.indexOf(oldItem);
    if (index != -1) {
      items[index] = newItem;
      notifyListeners();
    }
  }

  // Método para limpiar la lista de artículos
  void clearItems() {
    items.clear();
    notifyListeners(); // Notifica a los oyentes que se ha actualizado la lista
  }
}

class CotizacionItem {
  final String descripcion;
  final String tipo;
  double precioUnitario;
  final int cantidad;
  double? ganancia; // Añadir este campo si aún no existe
  final double
      porcentajeGanancia; // Nueva propiedad para almacenar el % de ganancia
  final double precioVenta;

  CotizacionItem({
    required this.descripcion,
    required this.tipo,
    required this.precioUnitario,
    required this.cantidad,
    required this.ganancia,
    required this.porcentajeGanancia, // Asegúrate de recibir este valor
    required this.precioVenta,
  });

  double get total => precioUnitario * cantidad;

  // Puedes añadir un método para calcular la ganancia basada en el porcentaje
  double calcularGanancia(double porcentajeGanancia) {
    return (precioUnitario * porcentajeGanancia) / 100;
  }

  double calcularPrecioVenta(double porcentajeGanancia) {
    return precioUnitario + calcularGanancia(porcentajeGanancia);
  }
}

String formatCurrency(double amount) {
  final format = NumberFormat("#,##0.00", "es_ES");
  return '\$${format.format(amount)}';
}
