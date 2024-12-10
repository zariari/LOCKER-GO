import 'package:flutter/material.dart';
import 'package:lockergo/screens/log/login.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  void _showSuccessModal(BuildContext context) {
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
                'Tu registro en LockerGo ha sido exitoso!',
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
                backgroundColor: const Color.fromARGB(255, 123, 123, 123),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
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

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Image.asset(
          'assets/images/header.png',
          fit: BoxFit.cover,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0, // Removes shadow
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text(
                'Términos y Condiciones',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black),
                ),
                child: const SingleChildScrollView(
                  child: Text(
                    '''1. Aceptación de los Términos: 
Al acceder y utilizar la aplicación LockerGO, usted acepta cumplir con estos Términos y Condiciones. Si no está de acuerdo con estos términos, no podrá utilizar la aplicación.

2. Registro de Usuario: 
Para utilizar LockerGO, debe registrarse proporcionando su cédula de identidad y otra información personal requerida. Usted se compromete a proporcionar información veraz y actualizada durante el registro.

3. Uso de la Aplicación: 
LockerGO le permite reservar lockers de acuerdo con la disponibilidad y las políticas establecidas. Cada usuario puede tener una sola reserva activa por semestre académico. Está prohibido el uso indebido de la aplicación, incluyendo cualquier acto que interfiera con su funcionamiento o con los derechos de otros usuarios.

4. Modificación de Reservas: 
Cada usuario tiene derecho a realizar una sola modificación a su reserva de locker durante todo el semestre. Una vez realizada esta modificación, no se permitirán cambios adicionales.

5. Responsabilidad del Usuario: 
El usuario es responsable del uso adecuado del locker reservado. LockerGO no se hace responsable de la pérdida, daño o robo de artículos almacenados en los lockers. Es responsabilidad del usuario cancelar o modificar su reserva en caso de que ya no necesite el locker.

6. Duración de las Reservas: 
Cada reserva tiene una duración predefinida, que coincide con el semestre académico en curso. Al finalizar el periodo de reserva, el usuario deberá liberar el locker.

7. Cancelación de Reservas: 
El usuario puede cancelar su reserva en cualquier momento a través de la aplicación. Una vez cancelada, el locker quedará disponible para otros usuarios.

8. Privacidad: 
LockerGO recopila y almacena información personal del usuario de manera segura. No compartimos la información personal con terceros sin el consentimiento del usuario, excepto en los casos requeridos por ley.

9. Cambios en los Términos y Condiciones: 
LockerGO se reserva el derecho de modificar estos Términos y Condiciones en cualquier momento. Los cambios serán notificados a los usuarios a través de la aplicación, y su uso continuo de la misma implica la aceptación de dichas modificaciones.

10. Propiedad Intelectual: 
Todos los contenidos y materiales presentes en LockerGO, incluyendo diseño, logotipo, textos e imágenes, son propiedad exclusiva de LockerGO y están protegidos por las leyes de propiedad intelectual. Queda prohibida su reproducción sin autorización previa.

11. Contacto: 
Para cualquier pregunta o soporte relacionado con la aplicación, el usuario puede ponerse en contacto a través del correo electrónico: soporte@lockergo.com.
''',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _showSuccessModal(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005DA7),
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.1,
                      vertical: 10), // Dynamic horizontal padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Leí y Acepto',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
