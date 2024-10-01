import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista Paginada',
      theme: ThemeData(
        primaryColor: Colors.blueAccent,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PaginatedList(),
    );
  }
}

class PaginatedList extends StatefulWidget {
  @override
  _PaginatedListState createState() => _PaginatedListState();
}

class _PaginatedListState extends State<PaginatedList> {
  final List<Map<String, dynamic>> items = List.generate(
    64,
    (index) => {
      'Título': 'Elemento ${index + 1}',
      'Sección': '01-Mapa',
      'Número de elementos': (index + 1) * 2,
      'Tipo': 'Cuenta empresa',
    },
  );

  int currentPage = 0;
  final int itemsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    int totalPages = (items.length / itemsPerPage).ceil();
    List<Map<String, dynamic>> currentItems =
        items.skip(currentPage * itemsPerPage).take(itemsPerPage).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista Paginada'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: currentItems.length,
              itemBuilder: (context, index) {
                return _buildListItem(currentItems[index]);
              },
            ),
          ),
          _buildPagination(totalPages),
        ],
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> item) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          item['Título'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sección: ${item['Sección']}', style: const TextStyle(color: Colors.black54)),
            Text('Número de elementos: ${item['Número de elementos']}', style: const TextStyle(color: Colors.black54)),
            Text('Tipo: ${item['Tipo']}', style: const TextStyle(color: Colors.black54)),
          ],
        ),
        trailing: _buildActions(),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () {
            // Edit action
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            // Delete action
          },
        ),
      ],
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Página ${currentPage + 1} de $totalPages',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Row(
            children: [
              _buildFirstPreviousButtons(),
              _buildThreePageButtons(totalPages),
              _buildNextLastButtons(totalPages),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFirstPreviousButtons() {
    return Row(
      children: [
        TextButton(
          onPressed: currentPage > 0
              ? () {
                  setState(() {
                    currentPage = 0; // Ir a la primera página
                  });
                }
              : null,
          child: const Text('Primera'),
        ),
        TextButton(
          onPressed: currentPage > 0
              ? () {
                  setState(() {
                    currentPage--; // Ir a la página anterior
                  });
                }
              : null,
          child: const Text('Anterior'),
        ),
      ],
    );
  }

  Widget _buildThreePageButtons(int totalPages) {
    List<Widget> buttons = [];

    // Determinar el rango de páginas a mostrar
    int startPage = (currentPage > 1) ? currentPage - 1 : 0;
    int endPage = (currentPage < totalPages - 2) ? currentPage + 1 : totalPages - 1;

    // Ajustar startPage si se están mostrando las últimas páginas
    if (endPage - startPage < 2) {
      if (currentPage == totalPages - 1) {
        startPage = totalPages - 3 > 0 ? totalPages - 3 : 0;
      } else if (currentPage == totalPages - 2) {
        startPage = totalPages - 2;
      }
    }

    // Ajustar endPage para no exceder el total de páginas
    endPage = startPage + 2 < totalPages ? startPage + 2 : totalPages - 1;

    // Construir los botones de página
    for (int i = startPage; i <= endPage; i++) {
      buttons.add(_buildPageButton(i, (i + 1).toString()));
    }

    return Row(
      children: buttons,
    );
  }

  Widget _buildNextLastButtons(int totalPages) {
    return Row(
      children: [
        TextButton(
          onPressed: currentPage < totalPages - 1
              ? () {
                  setState(() {
                    currentPage++; // Ir a la página siguiente
                  });
                }
              : null,
          child: const Text('Siguiente'),
        ),
        TextButton(
          onPressed: currentPage < totalPages - 1
              ? () {
                  setState(() {
                    currentPage = totalPages - 1; // Ir a la última página
                  });
                }
              : null,
          child: const Text('Última'),
        ),
      ],
    );
  }

  Widget _buildPageButton(int pageIndex, String label) {
    bool isActive = currentPage == pageIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: isActive ? Colors.white : Colors.black, backgroundColor: isActive ? Colors.blueAccent : Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          setState(() {
            currentPage = pageIndex;
          });
        },
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
