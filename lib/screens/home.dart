import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lockergo/custom_bottom_navigation_bar.dart';
import 'package:lockergo/screens/lockers/faculty.dart';
import 'package:lockergo/screens/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:lockergo/globals/globals.dart' as globals;

class LockerReservationPage extends StatefulWidget {
  const LockerReservationPage({super.key});

  @override
  _LockerReservationPageState createState() => _LockerReservationPageState();
}

class _LockerReservationPageState extends State<LockerReservationPage> {
  String? firstName;
  String? lastName;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    const String apiUrl = 'http://pagueya-001-site3.mtempurl.com/api/Usuario';

    try {
      final response =
          await http.get(Uri.parse('$apiUrl/${globals.currentUserCedula}'));

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          firstName = userData['first_name'];
          lastName = userData['last_name'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error al cargar datos del usuario: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width and height
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    final themeProvider =
        Provider.of<ThemeProvider>(context); // Access the theme provider

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/header.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        centerTitle: true,
        title: Image.asset(
          'assets/images/logo_name_black.png',
          height: screenHeight * 0.04, // Dynamically adjust logo size
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Bienvenido ${firstName ?? ''}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: themeProvider.isDarkMode
                      ? Colors.white
                      : Colors.black, // Night mode color
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Reservar tu\nLocker Universitario',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode
                    ? const Color(0xFF9de9ff)
                    : Colors.black, // Blue for night mode
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/images/locker_image.png',
              height: screenHeight * 0.25, // 25% of screen height for image
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 30),
            Text(
              'Total Lockers',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode
                    ? const Color(0xFF9de9ff)
                    : Colors.black, // Blue for night mode
              ),
            ),
            Text(
              '1200',
              style: TextStyle(
                fontSize: 68,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode
                    ? const Color(0xFF9de9ff)
                    : Colors.black, // Blue for night mode
              ),
            ),
            Text(
              'Periodo Academico 2024-2025',
              style: TextStyle(
                fontSize: 16,
                color: themeProvider.isDarkMode
                    ? const Color(0xFF9de9ff)
                    : Colors.black, // Blue for night mode
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FacultyScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf39200),
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.1,
                    vertical: 10), // Dynamic padding based on screen width
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Reserva tu Locker Ya!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              '¿Necesitas ayuda con tu reserva?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : Colors.black, // White for night mode
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Contáctanos en ',
                    style: TextStyle(
                      fontSize: 16,
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black, // White for night mode
                    ),
                  ),
                  TextSpan(
                    text: 'soporte@lockergo.com',
                    style: TextStyle(
                      fontSize: 16,
                      color: themeProvider.isDarkMode
                          ? const Color(0xFFf39200)
                          : const Color(0xFF0a4c86), // Orange for night mode
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 0),
    );
  }
}
