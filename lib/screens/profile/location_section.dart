import 'package:flutter/material.dart';
import 'package:lockergo/screens/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lockergo/globals/globals.dart' as globals;

class LocationSection extends StatelessWidget {
  const LocationSection({super.key});

  Future<String> _fetchFacultyImage(BuildContext context) async {
    try {
      final url =
          "http://pagueya-001-site3.mtempurl.com/api/Reservas/InfoPorCedula/${globals.currentUserCedula}";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final facultyName = _parseFacultyNameFromJson(jsonData);

        if (facultyName.isEmpty) {
          return 'assets/images/map.png'; // Imagen predeterminada
        }

        final normalizedFacultyName = _mapFacultyNameToAssetPath(facultyName);
        final assetPath = 'assets/images/Mapa/$normalizedFacultyName.png';

        // Comprobación de existencia
        final imageExists = await _checkIfImageExists(assetPath, context);
        return imageExists ? assetPath : 'assets/images/map.png';
      } else {
        return 'assets/images/map.png'; // Imagen predeterminada
      }
    } catch (e) {
      return 'assets/images/map.png'; // Imagen predeterminada
    }
  }

  Future<bool> _checkIfImageExists(
      String assetPath, BuildContext context) async {
    try {
      final data = await DefaultAssetBundle.of(context).load(assetPath);
      return data != null;
    } catch (e) {
      return false;
    }
  }

  String _mapFacultyNameToAssetPath(String facultyName) {
    return facultyName
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[ ,]'), '_')
        .replaceAll(RegExp(r'_{2,}'), '_')
        .replaceAll(RegExp(r'[^\w]'), '');
  }

  String _parseFacultyNameFromJson(dynamic jsonData) {
    try {
      return jsonData[0]['FacultyName'] ?? '';
    } catch (e) {
      return '';
    }
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true, // Permite cerrar el diálogo al tocar fuera
      barrierColor: Colors.black.withOpacity(0.8), // Fondo semi-transparente
      barrierLabel:
          'Cerrar imagen', // Proporciona una etiqueta de accesibilidad
      pageBuilder: (context, _, __) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.black,
            child: InteractiveViewer(
              panEnabled: true, // Permite desplazamiento
              minScale: 1.0, // Tamaño original mínimo
              maxScale: 5.0, // Máximo zoom 5x
              child: Image.asset(
                imageUrl,
                fit: BoxFit.contain, // Ajuste de la imagen
                filterQuality: FilterQuality.high, // Alta calidad de zoom
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return FutureBuilder<String>(
      future: _fetchFacultyImage(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final imageUrl = snapshot.data ?? 'assets/images/map.png';

        return GestureDetector(
          onTap: () => _showFullImage(
              context, imageUrl), // Amplía la imagen al presionar
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: themeProvider.isDarkMode
                    ? Color(0xFF9de9ff)
                    : Color.fromARGB(255, 0, 0, 0),
                width: 2,
              ),
              color:
                  themeProvider.isDarkMode ? Color(0xFF0a4c86) : Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                imageUrl,
                fit: BoxFit.contain, // Ajusta el tamaño sin recortar
              ),
            ),
          ),
        );
      },
    );
  }
}
