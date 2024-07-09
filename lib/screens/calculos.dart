import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:number_to_words/number_to_words.dart';

class CotizacionProvider extends ChangeNotifier {
  String _cliente = '';
  String _telefono = '';
  String _tipoPersona = '';

  String get cliente => _cliente;
  String get telefono => _telefono;
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
}

class CotizacionItem {
  final String descripcion;
  final double precioUnitario;
  final int cantidad;

  CotizacionItem({
    required this.descripcion,
    required this.precioUnitario,
    required this.cantidad,
  });

  double get total => precioUnitario * cantidad;
}

String formatCurrency(double amount) {
  final format = NumberFormat("#,##0.00", "es_ES");
  return '\$${format.format(amount)}';
}
