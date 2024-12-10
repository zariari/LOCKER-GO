import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lockergo/screens/home.dart';
import 'package:lockergo/screens/log/on_boarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lockergo/globals/globals.dart' as globals;
import 'package:vibration/vibration.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FocusNode _cedulaFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = true;

  // URL de la API
  final String apiUrl = 'http://pagueya-001-site3.mtempurl.com/api/Usuario';

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  @override
  void dispose() {
    _cedulaFocusNode.dispose();
    _passwordFocusNode.dispose();
    _cedulaController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCedula = prefs.getString('cedula');
    if (savedCedula != null) {
      globals.currentUserCedula = savedCedula;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LockerReservationPage(),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSession(String cedula) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cedula', cedula);
  }

  bool validateCedula(String cedula) {
    const int tamanoCedula = 10;
    const int numeroProvincia = 24;
    const int tercerDigito = 6;
    List<int> coeficientes = [2, 1, 2, 1, 2, 1, 2, 1, 2];
    int total = 0;

    if (cedula.length != tamanoCedula || !RegExp(r'^\d+$').hasMatch(cedula)) {
      return false; // La cédula debe tener exactamente 10 dígitos.
    }

    int provincia = int.tryParse(cedula.substring(0, 2)) ?? -1;
    if (provincia <= 0 || provincia > numeroProvincia) {
      return false; // Código de provincia inválido.
    }

    int digitoTres = int.tryParse(cedula[2]) ?? -1;
    if (digitoTres >= tercerDigito || digitoTres < 0) {
      return false; // El tercer dígito no es válido.
    }

    for (int i = 0; i < coeficientes.length; i++) {
      int digito = int.tryParse(cedula[i]) ?? 0;
      int valor = coeficientes[i] * digito;
      total += valor >= 10 ? valor - 9 : valor;
    }

    int digitoVerificador = (10 - (total % 10)) % 10;
    int digitoVerificadorRecibido = int.tryParse(cedula[9]) ?? -1;

    return digitoVerificador == digitoVerificadorRecibido;
  }

  Future<void> login() async {
    final String cedula = _cedulaController.text.trim();
    final String password = _passwordController.text.trim();

    if (cedula.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos.')),
      );
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 300); // Vibración breve para error.
      }
      return;
    }

    if (!validateCedula(cedula)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cédula inválida.')),
      );
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 300); // Vibración breve para error.
      }
      return;
    }

    try {
      final response = await http.get(Uri.parse('$apiUrl/$cedula'));

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);

        if (userData == null || userData['password'] != password) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario o contraseña incorrectos.')),
          );
          if (await Vibration.hasVibrator() ?? false) {
            Vibration.vibrate(pattern: [0, 200, 100, 200]); // Patrón de error.
          }
          return;
        }

        // Inicio de sesión exitoso
        globals.currentUserCedula = cedula;
        await _saveSession(cedula);
        /*ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicio de sesión exitoso.')),
        );*/
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(
              pattern: [0, 100, 50, 100, 50, 100]); // Patrón de éxito.
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LockerReservationPage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al iniciar sesión. Intenta de nuevo.'),
          ),
        );
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(pattern: [0, 200, 100, 200]); // Patrón de error.
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 200, 100, 200]); // Patrón de error.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    bool isTyping = _cedulaFocusNode.hasFocus || _passwordFocusNode.hasFocus;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Image.asset(
                              'assets/images/upper_image.png',
                              fit: BoxFit.cover,
                              height: screenHeight * 0.3,
                            ),
                          ),
                          Positioned(
                            top: screenHeight * 0.05,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: screenHeight * 0.15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05, vertical: 30),
                        child: Column(
                          children: [
                            const Text(
                              'Inicia sesión',
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              'Cédula',
                              '1234567890',
                              _cedulaController,
                              false,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              'Contraseña',
                              'Abc123@',
                              _passwordController,
                              true,
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0a4c86),
                                padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.1,
                                    vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (keyboardHeight == 0)
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/lower_image.png',
                      fit: BoxFit.cover,
                      height: screenHeight * 0.2,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿No tienes una cuenta? ',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OnboardingPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Regístrate aquí',
                            style: TextStyle(
                              color: Color(0xFF0a4c86),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hintText,
      TextEditingController controller, bool isPassword) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          keyboardType:
              isPassword ? TextInputType.visiblePassword : TextInputType.number,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontSize: 18,
            ),
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.black),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
