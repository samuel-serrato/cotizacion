import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:flutter/material.dart';
import 'screens/control.dart';
import 'screens/formulario.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom SideMenu Demo',
      theme: ThemeData(
        brightness: Brightness.light, // Tema claro
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, // Fondo claro
      ),
      home: const NavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({Key? key}) : super(key: key);

  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  PageController pageController = PageController();
  SideMenuController sideMenu = SideMenuController();
  bool isMenuOpen = true; // Controla el estado del menú

  // Crear un GlobalKey para cada pantalla
  final GlobalKey<ControlScreenState> _controlKey =
      GlobalKey<ControlScreenState>();

  @override
  void initState() {
    sideMenu.addListener((index) {
      pageController.jumpToPage(index);
    });
    super.initState();
  }

  // Método para alternar el menú
  void toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen; // Alternar el estado
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: isMenuOpen ? 200 : 105, // Ancho del menú
            child: SideMenu(
              controller: sideMenu,
              showToggle: false, // No mostrar el toggle integrado
              style: SideMenuStyle(
                showTooltip: false,
                displayMode: isMenuOpen
                    ? SideMenuDisplayMode.open
                    : SideMenuDisplayMode.compact,
                hoverColor: Colors.blue[100],
                selectedHoverColor: Color.fromARGB(255, 0, 58, 117),
                selectedColor: Color(0xFF001F3F),
                selectedTitleTextStyle: const TextStyle(color: Colors.white),
                selectedIconColor: Colors.white,
                unselectedTitleTextStyle: const TextStyle(color: Colors.black),
                unselectedIconColor: Colors.black,
                backgroundColor: Colors.white,
              ),
              title: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo + Nombre de la App
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Row(
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 30,
                              maxWidth: 30,
                            ),
                            child: Image.asset(
                              'assets/icono_codx.png', // Cambia con tu logo
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isMenuOpen)
                            const Text(
                              'COTIX',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Botón de toggle
                    IconButton(
                      icon: Icon(
                        isMenuOpen
                            ? Icons.arrow_back_ios
                            : Icons.arrow_forward_ios,
                        color: Colors.black,
                        size: 18,
                      ),
                      onPressed: toggleMenu,
                    ),
                  ],
                ),
              ),
              items: [
                SideMenuItem(
                  title: 'Formulario',
                  onTap: (index, _) {
                    sideMenu.changePage(0);
                  },
                  icon: const Icon(Icons.format_list_bulleted,
                      color: Colors.black),
                ),
                SideMenuItem(
                  title: 'Control',
                  onTap: (index, _) {
                    sideMenu.changePage(1);
                  },
                  icon: const Icon(Icons.receipt, color: Colors.black),
                ),
              ],
            ),
          ),
          Container(
            width: 1, // Grosor de la línea
            height: double.infinity, // Para que ocupe toda la altura
            color: Colors.grey[300], // Color de la línea
          ),
          Expanded(
            child: PageView(
              controller: pageController,
              children: [
                FormularioScreen(),
                ControlScreen(key: _controlKey),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
