import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lockergo/screens/log/login.dart';
import 'package:lockergo/screens/profile/user_edit.dart';
import 'package:lockergo/screens/theme_provider.dart';
import 'package:lockergo/globals/globals.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

class ProfileSection extends StatefulWidget {
  const ProfileSection({super.key});

  @override
  _ProfileSectionState createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  String? firstName;
  String? lastName;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
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
              content:
                  Text('Error al cargar el perfil: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    const String apiUrl = 'http://pagueya-001-site3.mtempurl.com/api/Usuario';

    try {
      final response =
          await http.delete(Uri.parse('$apiUrl/${globals.currentUserCedula}'));

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta eliminada correctamente.')),
        );
        // Vibrate for success
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(
              pattern: [0, 100, 50, 100, 50, 100]); // Success pattern
        }

        globals.currentUserCedula = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cedula');

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error: ${errorData['message'] ?? 'No se pudo eliminar la cuenta.'}')),
        );
        // Vibrate for error
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(pattern: [0, 200, 100, 200]); // Error pattern
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
      // Vibrate for error
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 200, 100, 200]); // Error pattern
      }
    }
  }

  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cedula');
    globals.currentUserCedula = null;
    // Vibrate for success
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100]); // Success pattern
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _navigateToEditProfilePage(BuildContext context) async {
    // Navega a la página de edición del perfil y espera el resultado
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    );

    // Recarga los datos del perfil al regresar
    _loadUserProfile();
  }

  void _showDeleteConfirmation(BuildContext context) async {
    // Vibrate to draw attention to the dialog
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(
        pattern: [0, 200, 100, 200, 100, 200], // Warning pattern
      );
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
                child: const Icon(Icons.warning, color: Colors.red, size: 50),
              ),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(fontSize: 18, color: Colors.black),
                  children: [
                    TextSpan(text: 'Estás a punto de eliminar tu cuenta.\n'),
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
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
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
                'Tu perfil',
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
                    onTap: () => themeProvider.toggleTheme(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        themeProvider.isDarkMode
                            ? Icons.wb_sunny
                            : Icons.nightlight_round,
                        color: themeProvider.isDarkMode
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
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
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () => _navigateToEditProfilePage(context),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.edit, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () => _logout(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode
                            ? const Color(0xFF9de9ff)
                            : const Color(0xFF0a4c86),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.power_settings_new,
                        color: themeProvider.isDarkMode
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: themeProvider.isDarkMode
                      ? const Color(0xFF9de9ff)
                      : const Color.fromARGB(255, 0, 0, 0),
                  child: Icon(
                    Icons.person,
                    color: themeProvider.isDarkMode
                        ? const Color(0xFF0a4c86)
                        : Colors.white,
                    size: 35,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nombre: ${firstName ?? 'Cargando...'}',
                    style: TextStyle(
                      fontSize: screenHeight * 0.018,
                      color: themeProvider.isDarkMode
                          ? const Color(0xFF9de9ff)
                          : const Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Apellido: ${lastName ?? 'Cargando...'}',
                    style: TextStyle(
                      fontSize: screenHeight * 0.018,
                      color: themeProvider.isDarkMode
                          ? const Color(0xFF9de9ff)
                          : const Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Cédula: ${globals.currentUserCedula ?? 'No disponible'}',
                    style: TextStyle(
                      fontSize: screenHeight * 0.018,
                      color: themeProvider.isDarkMode
                          ? const Color(0xFF9de9ff)
                          : const Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
