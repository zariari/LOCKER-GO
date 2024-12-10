import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lockergo/screens/lockers/faculty.dart';
import 'package:lockergo/screens/profile/qr_screen.dart';
import 'package:lockergo/screens/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:lockergo/globals/globals.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vibration/vibration.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReservationsSection extends StatefulWidget {
  const ReservationsSection({super.key});

  @override
  _ReservationsSectionState createState() => _ReservationsSectionState();
}

class _ReservationsSectionState extends State<ReservationsSection> {
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, String> _reservationData = {
    'Facultad': 'N/A',
    'Piso': 'N/A',
    'Sección': 'N/A',
    'Número de Locker': 'N/A',
  };

  @override
  void initState() {
    super.initState();
    _fetchReservationData();
  }

  Future<void> _fetchReservationData() async {
    final String? cedula = globals.currentUserCedula;
    if (cedula == null) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('reservationData_$cedula');

    // Mostrar datos en caché si existen
    if (cachedData != null) {
      setState(() {
        _reservationData = Map<String, String>.from(jsonDecode(cachedData));
        _isLoading = false;
      });
    }

    final String apiUrl =
        'http://pagueya-001-site3.mtempurl.com/api/Reservas/InfoPorCedula/$cedula';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isEmpty) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
          return;
        }

        final reservation = data.first;
        final newReservationData = {
          'Facultad': reservation['FacultyName'] ?? 'N/A',
          'Piso': reservation['FloorNumber'] ?? 'N/A',
          'Sección': reservation['SectionName'] ?? 'N/A',
          'Número de Locker': reservation['LockerNumber']?.toString() ?? 'N/A',
        };

        // Guardar en caché
        await prefs.setString(
            'reservationData_$cedula', jsonEncode(newReservationData));

        setState(() {
          _reservationData = newReservationData
              .map((key, value) => MapEntry(key, value.toString()));
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(4, (index) {
            return Container(
              height: 20,
              margin: const EdgeInsets.only(bottom: 10),
              color: Colors.grey[400],
            );
          }),
        ),
      ),
    );
  }

  void _navigateToFacultyScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FacultyScreen()),
    );
  }

  void _showDeleteConfirmation(BuildContext context) async {
    // Vibrate to indicate a critical action
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(
          pattern: [0, 200, 100, 200, 100, 200]); // Warning pattern
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 10),
                child: const Icon(Icons.delete, color: Colors.red, size: 50),
              ),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(fontSize: 18, color: Colors.black),
                  children: [
                    TextSpan(text: 'Estás a punto de eliminar tu reserva.\n'),
                    TextSpan(
                      text: 'Esta acción es irreversible.\n',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: '¿Estás seguro de que deseas continuar?',
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                backgroundColor: const Color.fromARGB(255, 123, 123, 123),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                backgroundColor: const Color(0xFF0a4c86),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                // Add vibration feedback for delete action
                if (await Vibration.hasVibrator() == true) {
                  Vibration.vibrate(
                      pattern: [0, 300, 100, 300]); // Deletion pattern
                }
              },
              child: const Text(
                'Continuar',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  /*void _showQRDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // Permitir cerrar al tocar fuera del diálogo
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Muestra el código QR en tu asociación de facultad para realizar el pago',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Image.asset(
                  'assets/images/qr_code_sample.png', // Reemplaza con la ruta de tu imagen QR
                  fit: BoxFit.contain,
                  height: MediaQuery.of(context).size.height *
                      0.3, // Altura dinámica
                  width: MediaQuery.of(context).size.width *
                      0.6, // Anchura dinámica
                ),
              ],
            ),
          ),
        );
      },
    );
  }*/
  void _showQRDialog(BuildContext context) async {
    final String? cedula = globals.currentUserCedula;
    if (cedula == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: const Text("No se pudo obtener la cédula del usuario."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cerrar"),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final reservationUrl =
          'http://pagueya-001-site3.mtempurl.com/api/Reservas/InfoPorCedula/$cedula';
      final userUrl =
          'http://pagueya-001-site3.mtempurl.com/api/Usuario/$cedula';

      final reservationResponse = await http.get(Uri.parse(reservationUrl));
      final userResponse = await http.get(Uri.parse(userUrl));

      if (reservationResponse.statusCode == 200 &&
          userResponse.statusCode == 200) {
        final reservationData =
            jsonDecode(reservationResponse.body) as List<dynamic>;
        if (reservationData.isEmpty) {
          throw Exception("No se encontraron reservas.");
        }

        final reservation = reservationData.first;

        final userData = jsonDecode(userResponse.body);

        // Obtener datos de reserva y usuario
        final reservationId = reservation['ReservationId'] ?? 'N/A';
        final facultyName = reservation['FacultyName'] ?? 'N/A';
        final floorNumber = reservation['FloorNumber'] ?? 'N/A';
        final sectionName = reservation['SectionName'] ?? 'N/A';
        final lockerNumber = reservation['LockerNumber']?.toString() ?? 'N/A';

        final firstName = userData['first_name'] ?? 'N/A';
        final lastName = userData['last_name'] ?? 'N/A';
        final userCedula = userData['cedula'] ?? 'N/A';

        // Sanitizar y simplificar contenido del QR
        final qrContent = '''
Reserva ID: $reservationId, Usuario: $firstName $lastName ,Cédula: $userCedula, Facultad: $facultyName, $floorNumber, $sectionName , Locker: $lockerNumber
'''
            .replaceAll(',', '')
            .replaceAll('á', 'a')
            .replaceAll('é', 'e')
            .replaceAll('í', 'i')
            .replaceAll('ó', 'o')
            .replaceAll('ú', 'u')
            .replaceAll('\n', ' ')
            .trim();

        print("Contenido del QR:\n$qrContent");
        print("Longitud del contenido del QR: ${qrContent.length}");

        // Navegar a la pantalla del QR
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QRScreen(qrData: qrContent),
          ),
        );
      } else {
        throw Exception("Error al obtener los datos del usuario o la reserva.");
      }
    } catch (e) {
      // Mostrar diálogo de error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text("Error: ${e.toString()}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cerrar"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: themeProvider.isDarkMode
              ? const Color(0xFF9de9ff)
              : const Color.fromARGB(255, 0, 0, 0),
          width: 2,
        ),
        color:
            themeProvider.isDarkMode ? const Color(0xFF0a4c86) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tu reserva',
                style: TextStyle(
                  fontSize: screenHeight * 0.030,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode
                      ? Colors.white
                      : const Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showDeleteConfirmation(context),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _navigateToFacultyScreen(context),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.edit, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03, vertical: screenHeight * 0.02),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? const Color(0xFF9de9ff)
                  : const Color(0xFF0a4c86),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading)
                  _buildShimmerPlaceholder()
                else if (_hasError)
                  const Text(
                    'No tienes una reserva activa.',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  )
                else
                  ..._reservationData.entries.map((entry) {
                    return Text(
                      '${entry.key}: ${entry.value}',
                      style: TextStyle(
                        fontSize: screenHeight * 0.018,
                        color: themeProvider.isDarkMode
                            ? const Color(0xFF0a4c86)
                            : Colors.white,
                      ),
                    );
                  }).toList(),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _showQRDialog(context),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code,
                          size: screenHeight * 0.1,
                          color: themeProvider.isDarkMode
                              ? const Color(0xFF0a4c86)
                              : Colors.white,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Presionar QR',
                          style: TextStyle(
                            fontSize: screenHeight * 0.018,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.isDarkMode
                                ? const Color(0xFF0a4c86)
                                : Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
