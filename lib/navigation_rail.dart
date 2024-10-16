import 'package:cotizacion/screens/calculos.dart';
import 'package:cotizacion/screens/estadisticas.dart';
import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/control.dart';
import 'screens/formulario.dart';

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
    final isDarkMode = Provider.of<CotizacionProvider>(context)
        .isDarkMode; // Obtener el estado del modo oscuro

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: isMenuOpen ? 200 : 110, // Ancho del menú
            child: SideMenu(
              controller: sideMenu,
              showToggle: false, // No mostrar el toggle integrado
              style: SideMenuStyle(
                showTooltip: false,
                displayMode: isMenuOpen
                    ? SideMenuDisplayMode.open
                    : SideMenuDisplayMode.compact,
                hoverColor:
                    isDarkMode ? Colors.blueGrey[700] : Colors.blue[100],
                selectedHoverColor: Color.fromARGB(255, 0, 58, 117),
                selectedColor: isDarkMode
                    ? Color.fromARGB(255, 0, 73, 147)
                    : Color(0xFF001F3F),
                selectedTitleTextStyle: const TextStyle(color: Colors.white),
                selectedIconColor: Colors.white,
                unselectedTitleTextStyle: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                unselectedIconColor: isDarkMode ? Colors.white : Colors.black,
                backgroundColor: isDarkMode ? Colors.black : Colors.white,
              ),
              title: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16.0, horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo + Nombre de la App
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Image.asset(
                              'assets/cotix logo solo circulo.png',
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isMenuOpen)
                            Text(
                              'COTIX',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 28,
                                fontFamily: 'Fredoka',
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
                        color: isDarkMode ? Colors.white : Colors.black,
                        size: 18,
                      ),
                      onPressed: toggleMenu,
                    ),
                  ],
                ),
              ),
              footer: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Developed by',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: 12,
                              fontFamily: 'Verdana',
                              fontWeight: FontWeight.w100,
                            )),
                        SizedBox(height: 2),
                        Container(
                          alignment: Alignment.center,
                          height: 30,
                          width: 200,
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: Image.asset(
                              'assets/codx_transparente_full_negro.png',
                            ),
                          ),
                        ),
                      ],
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
                  icon: const Icon(Icons.assignment),
                ),
                SideMenuItem(
                  title: 'Control',
                  onTap: (index, _) {
                    sideMenu.changePage(1);
                  },
                  icon: const Icon(Icons.dashboard),
                ),
                SideMenuItem(
                  title: 'Estadísticas',
                  onTap: (index, _) {
                    sideMenu.changePage(2);
                  },
                  icon: const Icon(Icons.stacked_bar_chart_sharp),
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
                EstadisticasScreen()
              ],
            ),
          ),
        ],
      ),
    );
  }
}
