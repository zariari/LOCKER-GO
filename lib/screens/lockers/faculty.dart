import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lockergo/custom_bottom_navigation_bar.dart';
import 'package:lockergo/screens/lockers/floor.dart';
import 'package:lockergo/screens/theme_provider.dart';
import 'package:provider/provider.dart';

class FacultyScreen extends StatefulWidget {
  const FacultyScreen({super.key});

  @override
  _FacultyScreenState createState() => _FacultyScreenState();
}

class _FacultyScreenState extends State<FacultyScreen> {
  List<dynamic> faculties = [];
  List<dynamic> filteredFaculties = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSearchBar = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    fetchFaculties();
    _searchController.addListener(_filterFaculties);
    _scrollController.addListener(_handleScroll);
  }

  Future<void> fetchFaculties() async {
    try {
      // Llamada a la nueva URI
      final response = await http.get(Uri.parse(
          'http://pagueya-001-site3.mtempurl.com/api/facultades/detail'));
      if (response.statusCode == 200) {
        // Parsear los datos directamente desde la nueva URI
        final data = json.decode(response.body);
        setState(() {
          faculties = data.map((faculty) {
            return {
              'id': faculty['FacultyId'],
              'name': faculty['FacultyName'],
              'available': faculty['AvailableLockers'],
            };
          }).toList();
          filteredFaculties = faculties;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load faculties');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error fetching faculties: $e');
    }
  }

  void _filterFaculties() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredFaculties = faculties
          .where((faculty) =>
              faculty['name'].toString().toLowerCase().contains(query))
          .toList();
    });
  }

  void _handleScroll() {
    double currentScrollOffset = _scrollController.position.pixels;

    if (currentScrollOffset > _lastScrollOffset && _showSearchBar) {
      // Si el usuario hace scroll hacia abajo, oculta la barra
      setState(() {
        _showSearchBar = false;
      });
    } else if (currentScrollOffset < _lastScrollOffset && !_showSearchBar) {
      // Si el usuario hace scroll hacia arriba, muestra la barra
      setState(() {
        _showSearchBar = true;
      });
    }

    _lastScrollOffset = currentScrollOffset;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05, vertical: 10), // Dynamic padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text(
                'Selecciona la Facultad',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode
                      ? Colors.white
                      : Colors.black, // Night mode color
                ),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showSearchBar ? 60 : 0,
              child: _showSearchBar
                  ? TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Busca tu facultad...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : Colors.black, // White for night mode
                          ),
                        ),
                        hintStyle: TextStyle(
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black, // White for night mode
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredFaculties.length,
                      itemBuilder: (context, index) {
                        final faculty = filteredFaculties[index];
                        return FacultyTile(
                          facultyId: faculty['id'],
                          facultyName: faculty['name'],
                          availability: '${faculty['available']} Disponible',
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }
}

class FacultyTile extends StatelessWidget {
  final int facultyId;
  final String facultyName;
  final String availability;

  const FacultyTile({
    super.key,
    required this.facultyId,
    required this.facultyName,
    required this.availability,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider =
        Provider.of<ThemeProvider>(context); // Access the theme provider

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: themeProvider.isDarkMode
              ? Color(0xFF9de9ff)
              : Color(0xFF0a4c86), // Blue for night mode
          width: 2.0,
        ),
      ),
      color: themeProvider.isDarkMode
          ? Color(0xFF0a4c86)
          : Colors.white, // Box background color
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FloorSelectionScreen(
                facultyId: facultyId,
                facultyName: facultyName,
              ),
            ),
          );
        },
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              facultyName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode
                    ? Color(0xFF9de9ff)
                    : Color(0xFF0a4c86), // Blue for night mode
              ),
              softWrap: true,
            ),
            const SizedBox(height: 5),
            Text(
              availability,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward,
          color: themeProvider.isDarkMode
              ? Color(0xFF9de9ff)
              : Color(0xFF0a4c86), // Blue for night mode
        ),
      ),
    );
  }
}
