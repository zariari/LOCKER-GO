import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:lockergo/custom_bottom_navigation_bar.dart';
import 'package:lockergo/screens/profile/user_profile.dart';
import 'package:lockergo/screens/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:lockergo/globals/globals.dart';
import 'package:vibration/vibration.dart';

class LockerSelectionScreen extends StatefulWidget {
  final String facultyName;
  final String floorNumber;
  final String section;
  final int sectionId;

  const LockerSelectionScreen({
    super.key,
    required this.facultyName,
    required this.floorNumber,
    required this.section,
    required this.sectionId,
  });

  @override
  State<LockerSelectionScreen> createState() => _LockerSelectionScreenState();
}

class _LockerSelectionScreenState extends State<LockerSelectionScreen> {
  List<dynamic> lockers = [];
  bool isLoading = true;
  bool userHasReservation = false;
  bool userModificationCountIsZero = false;

  @override
  void initState() {
    super.initState();
    fetchLockers();
  }

  Future<void> fetchLockers() async {
    try {
      final url = Uri.parse(
          'http://pagueya-001-site3.mtempurl.com/api/locker/${widget.sectionId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          lockers = data;
          isLoading = false;
        });
        debugPrint('Lockers loaded: $lockers');
      } else {
        throw Exception('Failed to load lockers');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error fetching lockers: $e');
    }
  }

  Future<void> checkLockerReservation(int lockerId, int lockerNumber) async {
    try {
      debugPrint(
          'Iniciando verificación para currentUserCedula: $currentUserCedula');

      // Obtener el ID del usuario
      final userUrl = Uri.parse(
          'http://pagueya-001-site3.mtempurl.com/api/Usuario/$currentUserCedula');
      final userResponse = await http.get(userUrl);

      if (userResponse.statusCode != 200) {
        debugPrint('No se encontró el usuario con la cédula proporcionada.');
        // Si no se encuentra el usuario, se procede como si no tuviera reserva
        userHasReservation = false;
        _showConfirmationModal(lockerNumber, lockerId, isUpdate: false);
        return;
      }

      // Parsear la respuesta JSON para obtener el ID del usuario
      final userData = json.decode(userResponse.body);
      final userId = userData['id'];
      debugPrint('ID del usuario obtenido: $userId');

      // Verificar reservas con el ID del usuario
      final reservationUrl = Uri.parse(
          'http://pagueya-001-site3.mtempurl.com/api/Reservas/$userId');
      final reservationResponse = await http.get(reservationUrl);

      if (reservationResponse.statusCode != 200) {
        debugPrint('No se encontró reserva activa para este usuario.');
        // Si no hay reserva, procedemos a ingresar reserva nueva
        userHasReservation = false;
        _showConfirmationModal(lockerNumber, lockerId, isUpdate: false);
        return;
      }

      // Si encontramos una reserva:
      userHasReservation = true;

      // Parsear la respuesta JSON para obtener el modification_count
      final reservationData = json.decode(reservationResponse.body);
      final modificationCount = reservationData['modification_count'];
      debugPrint('modification_count: $modificationCount');

      if (modificationCount == 0) {
        // Primera modificación posible (mostrar advertencia antes de proceder)
        userModificationCountIsZero = true;
        showModalBeforeProceeding(lockerId, lockerNumber);
      } else if (modificationCount == 1) {
        // Si el modification_count == 1, se ha superado el límite de cambios
        _showExceededLimitModal();
      } else {
        // Si hay más de 1, el comportamiento no está especificado,
        // pero asumiremos que también ha superado el límite.
        // Puedes modificar esta lógica según tus necesidades.
        _showExceededLimitModal();
      }
    } catch (e) {
      debugPrint('Error verificando la reserva del locker: $e');
      // En caso de error, por seguridad permitir reserva normal (o mostrar error)
      userHasReservation = false;
      _showConfirmationModal(lockerNumber, lockerId, isUpdate: false);
    }
  }

  void showModalBeforeProceeding(int lockerId, int lockerNumber) async {
    debugPrint(
        'Intentando mostrar modal de advertencia para modification_count == 0');
    // Trigger vibration for warning
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(pattern: [0, 200, 50, 200]); // Warning vibration
    }
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Advertencia',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Si modifica su reserva, será la última vez que podrá realizar este cambio.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 123, 123, 123),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  debugPrint('Modal cancelado por el usuario');
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0a4c86),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  debugPrint('Modal aceptado por el usuario');
                  Navigator.of(context).pop();
                  // Ahora mostramos la confirmación para actualizar
                  _showConfirmationModal(lockerNumber, lockerId,
                      isUpdate: true);
                },
                child: const Text(
                  'Aceptar',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
      debugPrint('Modal mostrado correctamente.');
    } catch (e) {
      debugPrint('Error al intentar mostrar el modal: $e');
    }
  }

  Future<void> saveReservation(int lockerId) async {
    try {
      const String apiUrl =
          'http://pagueya-001-site3.mtempurl.com/api/Reservas';

      // Obtener el ID del usuario
      final userResponse = await http.get(Uri.parse(
          'http://pagueya-001-site3.mtempurl.com/api/Usuario/$currentUserCedula'));

      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        final userId = userData['id'];

        final reservation = {
          "user_id": userId.toString().trim(),
          "locker_id": lockerId.toString().trim()
        };

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(reservation),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('Reservation successful: ${response.body}');

          /*ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reserva realizada con éxito')),
          );*/
          _showSuccessModal(context);
        } else {
          final errorData = jsonDecode(response.body);
          debugPrint('Failed to save reservation: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Error: ${errorData['ExceptionMessage'] ?? 'Error desconocido'}')),
          );
          _showErrorModal(context, message: 'Error al guardar la reserva.');
        }
      } else {
        debugPrint('Failed to fetch user ID: ${userResponse.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al obtener datos del usuario')),
        );
        _showErrorModal(context,
            message: 'Error al obtener datos del usuario.');
      }
    } catch (e) {
      debugPrint('Error saving reservation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al conectar con la API: $e')),
      );
      _showErrorModal(context,
          message: 'Error inesperado al guardar la reserva.');
    }
  }

  Future<void> updateReservation(int lockerId) async {
    try {
      // Primero obtenemos el ID del usuario logueado
      final userResponse = await http.get(Uri.parse(
          'http://pagueya-001-site3.mtempurl.com/api/Usuario/$currentUserCedula'));

      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        final userId = userData['id'];

        // Ahora usamos el userId en la URL para actualizar la reserva
        final String apiUrl =
            'http://pagueya-001-site3.mtempurl.com/api/Reservas/$userId';

        final updatedReservation = {
          "user_id": userId.toString().trim(),
          "locker_id": lockerId.toString().trim()
        };

        final response = await http.put(
          Uri.parse(apiUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(updatedReservation),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('Reservation updated successfully: ${response.body}');
          /**ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reserva actualizada con éxito')),
          );**/
          _showSuccessModal(context);
        } else {
          final errorData = jsonDecode(response.body);
          debugPrint('Failed to update reservation: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Error: ${errorData['ExceptionMessage'] ?? 'Error desconocido'}')),
          );
          _showErrorModal(context, message: 'Error al actualizar la reserva.');
        }
      } else {
        debugPrint('Failed to fetch user ID: ${userResponse.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al obtener datos del usuario')),
        );
        _showErrorModal(context,
            message: 'Error al obtener datos del usuario.');
      }
    } catch (e) {
      debugPrint('Error updating reservation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al conectar con la API: $e')),
      );
      _showErrorModal(context,
          message: 'Error inesperado al actualizar la reserva.');
    }
  }

  void _showConfirmationModal(int lockerNumber, int lockerId,
      {required bool isUpdate}) {
    String actionText = isUpdate ? 'actualizar' : 'reservar';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Confirmar $actionText',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            '¿Deseas $actionText el locker número $lockerNumber?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 123, 123, 123),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0a4c86),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                if (isUpdate) {
                  updateReservation(lockerId);
                } else {
                  saveReservation(lockerId);
                }
              },
              child: const Text(
                'Aceptar',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showExceededLimitModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Límite alcanzado',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black, // Siempre negro
            ),
          ),
          content: const Text(
            'Has superado el límite de cambios de locker.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.black, // Siempre negro
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 123, 123, 123),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    final themeProvider = Provider.of<ThemeProvider>(context);

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
      body: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text(
                'Selecciona tu Locker',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 5),
            const SizedBox(height: 20),
            Text(
              'Facultad de ${widget.facultyName}\n${widget.floorNumber}\n${widget.section}',
              style: TextStyle(
                fontSize: screenHeight * 0.025,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode
                    ? const Color(0xFF9de9ff)
                    : const Color(0xFF0a4c86),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.only(
                        left: screenWidth * 0.05,
                        right: screenWidth * 0.05,
                        bottom: screenHeight * 0.02,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemCount: lockers.length,
                      itemBuilder: (context, index) {
                        final locker = lockers[index];
                        return LockerTile(
                          lockerNumber: locker['locker_number'],
                          isAvailable: !locker['is_reserved'],
                          section: widget.section,
                          onLockerSelected: () => checkLockerReservation(
                              locker['id'], locker['locker_number']),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 10),
            Divider(
                color: themeProvider.isDarkMode
                    ? const Color(0xFF9de9ff)
                    : Colors.black,
                thickness: 5),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: 'Lockers en ',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: 'verde',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.green
                          : Colors.green,
                    ),
                  ),
                  TextSpan(
                    text: ' están disponibles \n Lockers en ',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: 'gris',
                    style: TextStyle(
                      color:
                          themeProvider.isDarkMode ? Colors.grey : Colors.grey,
                    ),
                  ),
                  TextSpan(
                    text: ' ya están reservados',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }

  void _showSuccessModal(BuildContext context) async {
    // Trigger vibration for success
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(pattern: [0, 100, 50, 100]); // Success vibration
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 50),
              SizedBox(height: 10),
              Text(
                'Tu locker ha sido reservado/actualizado con éxito.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 123, 123, 123),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage()));
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

  void _showErrorModal(BuildContext context,
      {String message =
          'Este locker ya está reservado. Por favor, selecciona otro locker.'}) async {
    // Trigger vibration for error
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(pattern: [0, 200, 100, 200]); // Error vibration
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 50),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.black),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 123, 123, 123),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
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
}

class LockerTile extends StatelessWidget {
  final int lockerNumber;
  final bool isAvailable;
  final String section;
  final VoidCallback onLockerSelected;

  const LockerTile({
    super.key,
    required this.lockerNumber,
    required this.isAvailable,
    required this.section,
    required this.onLockerSelected,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    final themeProvider = Provider.of<ThemeProvider>(context);

    return GestureDetector(
      onTap: () async {
        if (isAvailable) {
          debugPrint('Locker $lockerNumber seleccionado');
          onLockerSelected();
        } else {
          // Trigger vibration for unavailable locker
          if (await Vibration.hasVibrator() == true) {
            Vibration.vibrate(pattern: [0, 200, 100, 200]); // Error vibration
          }
          _showErrorModal(context);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isAvailable
              ? const Color.fromARGB(255, 96, 206, 100)
              : const Color.fromARGB(255, 150, 145, 145),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: themeProvider.isDarkMode
                  ? const Color(0xFF9de9ff)
                  : const Color(0xFF0a4c86),
              width: 2.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$lockerNumber',
            style: TextStyle(
              fontSize: screenWidth * 0.065,
              fontWeight: FontWeight.w900,
              color: themeProvider.isDarkMode
                  ? const Color(0xFF0a4c86)
                  : const Color(0xFF0a4c86),
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, color: Colors.red, size: 50),
              SizedBox(height: 10),
              Text(
                'Este locker ya está reservado. Por favor, selecciona otro locker.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 123, 123, 123),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
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
}
