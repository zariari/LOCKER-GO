import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lockergo/screens/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:lockergo/globals/globals.dart' as globals;
import 'package:vibration/vibration.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final GlobalKey _containerKey = GlobalKey();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _formKey = GlobalKey<FormState>();
  String currentSection = "Datos Personales";

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
          _firstNameController.text = userData['first_name'];
          _lastNameController.text = userData['last_name'];
        });
      } else {
        _showResponsiveSnackBar(
          'Error al cargar el perfil: ${response.statusCode}',
        );
      }
    } catch (e) {
      _showResponsiveSnackBar('Error de conexión: $e');
    }
  }

  Future<void> _updateProfile() async {
    const String apiUrl = 'http://pagueya-001-site3.mtempurl.com/api/Usuario';

    if (_formKey.currentState?.validate() ?? false) {
      // Validar la contraseña si no está vacía
      if (_passwordController.text.isNotEmpty) {
        final passwordError = validatePassword(_passwordController.text);
        if (passwordError != null) {
          _showResponsiveSnackBar(passwordError);
          // Vibration for validation error
          if (await Vibration.hasVibrator() == true) {
            Vibration.vibrate(pattern: [0, 200, 100, 200]); // Error pattern
          }
          return;
        }
      }

      // Validar si las contraseñas coinciden
      if (_passwordController.text != _confirmPasswordController.text) {
        _showResponsiveSnackBar('Las contraseñas no coinciden.');
        // Vibration for mismatch passwords
        if (await Vibration.hasVibrator() == true) {
          Vibration.vibrate(pattern: [0, 200, 100, 200]); // Error pattern
        }
        return;
      }

      // Crear objeto de usuario actualizado
      final updatedUser = {
        "cedula": globals.currentUserCedula,
        "first_name": _firstNameController.text.trim(),
        "last_name": _lastNameController.text.trim(),
        if (_passwordController.text.isNotEmpty)
          "password": _passwordController.text.trim(),
      };

      try {
        final response = await http.put(
          Uri.parse('$apiUrl/${globals.currentUserCedula}'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(updatedUser),
        );

        if (response.statusCode == 200) {
          _showSuccessModal();
          // Vibration for success
          if (await Vibration.hasVibrator() == true) {
            Vibration.vibrate(pattern: [0, 100, 50, 100]); // Success pattern
          }
        } else {
          final errorData = jsonDecode(response.body);
          _showResponsiveSnackBar(
              'Error al actualizar el perfil: ${errorData['message'] ?? 'No se pudo actualizar el perfil.'}');
          // Vibration for server error
          if (await Vibration.hasVibrator() == true) {
            Vibration.vibrate(pattern: [0, 200, 100, 200]); // Error pattern
          }
        }
      } catch (e) {
        _showResponsiveSnackBar('Error de conexión: $e');
        // Vibration for connection error
        if (await Vibration.hasVibrator() == true) {
          Vibration.vibrate(pattern: [0, 200, 100, 200]); // Error pattern
        }
      }
    }
  }

  String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'La contraseña es obligatoria.';
    }
    if (password.length < 8) {
      return 'Mínimo de 8 caracteres.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Al menos una letra minúscula.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Al menos una letra mayúscula.';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Al menos un número.';
    }
    if (!RegExp(r'[@\$!%*?&]').hasMatch(password)) {
      return 'Al menos un carácter especial.';
    }
    return null;
  }

  void _showSuccessModal() async {
    // Vibration for success
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100]); // Success pattern
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
                child: const Icon(Icons.check_circle,
                    color: Colors.green, size: 50),
              ),
              const Text(
                'Los cambios en tu perfil se han guardado con éxito.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                backgroundColor: const Color(0xFF0a4c86),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el modal
                Navigator.of(context)
                    .pop(true); // Regresa a la pantalla de perfil
              },
              child: const Text(
                'Cerrar',
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

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
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
          height: screenHeight * 0.04,
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Form(
            key: _formKey,
            child: Container(
              key: _containerKey, // Añade el key aquí

              padding: EdgeInsets.all(screenWidth * 0.05),
              margin: EdgeInsets.only(
                  left: screenWidth * 0.05,
                  right: screenWidth * 0.05,
                  top: screenHeight * 0.02),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: themeProvider.isDarkMode
                      ? const Color(0xFF9de9ff)
                      : const Color.fromARGB(255, 0, 0, 0),
                  width: 2,
                ),
                color: themeProvider.isDarkMode
                    ? const Color(0xFF0a4c86)
                    : Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Editar Perfil',
                      style: TextStyle(
                        fontSize: screenHeight * 0.030,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    'Cédula',
                    globals.currentUserCedula ?? 'Cargando...',
                    enabled: false,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        flex: 1,
                        child: _buildSectionButton(
                          label: "Datos Personales",
                          isSelected: currentSection == "Datos Personales",
                          onPressed: () {
                            setState(() {
                              currentSection = "Datos Personales";
                            });
                          },
                          screenWidth: screenWidth,
                        ),
                      ),
                      const SizedBox(width: 10), // Espacio entre botones
                      Flexible(
                        flex: 1,
                        child: _buildSectionButton(
                          label: "Cambiar Contraseña",
                          isSelected: currentSection == "Cambiar Contraseña",
                          onPressed: () {
                            setState(() {
                              currentSection = "Cambiar Contraseña";
                            });
                          },
                          screenWidth: screenWidth,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (currentSection == "Datos Personales") ...[
                    _buildTextField(
                      'Nombre',
                      _firstNameController.text,
                      controller: _firstNameController,
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      'Apellido',
                      _lastNameController.text,
                      controller: _lastNameController,
                    ),
                  ] else if (currentSection == "Cambiar Contraseña") ...[
                    _buildPasswordField(
                      'Contraseña',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      toggleObscure: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      validator: validatePassword,
                    ),
                    const SizedBox(height: 10),
                    _buildPasswordField(
                      'Confirmar Contraseña',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      toggleObscure: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _updateProfile,
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionButton({
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
    required double screenWidth,
  }) {
    return Container(
      width:
          screenWidth * 0.4, // Ajustar el ancho del botón de forma proporcional
      height: 50, // Ajustar altura consistente
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF0a4c86) : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(
            color: const Color(0xFF0a4c86),
            width: 2,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String value,
      {TextEditingController? controller,
      bool enabled = true,
      String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        TextFormField(
          controller: controller ?? TextEditingController(text: value),
          enabled: enabled,
          validator: validator ??
              (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El campo $label no puede estar vacío.';
                }
                
                return null;
              },
          decoration: const InputDecoration(),
        ),
      ],
    );
  }

  void _showResponsiveSnackBar(String message) {
    final containerContext = _containerKey.currentContext;
    double snackBarMaxWidth = MediaQuery.of(context).size.width *
        0.9; // Máximo 90% del ancho de la pantalla
    double horizontalMargin = 16; // Márgenes por defecto

    if (containerContext != null) {
      final containerRenderBox =
          containerContext.findRenderObject() as RenderBox?;

      if (containerRenderBox != null) {
        snackBarMaxWidth = containerRenderBox.size.width.clamp(
          200.0, // Ancho mínimo del SnackBar
          MediaQuery.of(context).size.width * 0.9, // Ancho máximo del SnackBar
        );
        horizontalMargin =
            (MediaQuery.of(context).size.width - snackBarMaxWidth) / 2;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin:
            EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 10),
        duration: const Duration(seconds: 4),
        content: Container(
          constraints: BoxConstraints(
            maxWidth: snackBarMaxWidth, // Límite dinámico para el ancho
          ),
          child: FittedBox(
            fit:
                BoxFit.scaleDown, // Reducir el tamaño del texto si es necesario
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14, // Tamaño base
                color: Colors.white,
              ),
              textAlign: TextAlign.left,
              softWrap: true, // Permitir saltos de línea
              overflow: TextOverflow
                  .visible, // Asegurar que todo el texto sea visible
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label,
      {required TextEditingController controller,
      required bool obscureText,
      required VoidCallback toggleObscure,
      String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
              onPressed: toggleObscure,
            ),
          ),
        ),
      ],
    );
  }
}
