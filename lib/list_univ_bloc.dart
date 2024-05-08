import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum ASEANCountry {
  Singapore,
  Malaysia,
  Indonesia,
  Thailand,
  Philippines,
  Vietnam,
  Myanmar,
  Cambodia,
  Laos,
  Brunei
}

class University {
  final String name;
  final String website;

  University({required this.name, required this.website});

  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'],
      website: json['web_pages'][0],
    );
  }
}

class UniversityApiService {
  static Future<List<University>> getUniversities(ASEANCountry country) async {
    final response = await http.get(Uri.parse(
        'http://universities.hipolabs.com/search?country=${country.toString().split('.').last}'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => University.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load universities');
    }
  }
}

class UniversityBloc extends ChangeNotifier {
  late List<University> _universities;

  UniversityBloc() {
    fetchUniversities(ASEANCountry.Indonesia); // Default country is Indonesia
  }

  List<University> get universities => _universities;

  get stream => null;

  Future<void> fetchUniversities(ASEANCountry country) async {
    try {
      _universities = await UniversityApiService.getUniversities(country);
      notifyListeners();
    } catch (e) {
      print('Error: $e');
    }
  }
}

class UniversityListView extends StatefulWidget {
  @override
  _UniversityListViewState createState() => _UniversityListViewState();
}

class _UniversityListViewState extends State<UniversityListView> {
  final UniversityBloc _universityBloc = UniversityBloc();
  ASEANCountry _selectedCountry = ASEANCountry.Indonesia;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Universities in ASEAN'),
      ),
      body: Column(
        children: [
          DropdownButton<ASEANCountry>(
            value: _selectedCountry,
            onChanged: (ASEANCountry? newValue) {
              setState(() {
                _selectedCountry = newValue!;
                _universityBloc.fetchUniversities(newValue);
              });
            },
            items: ASEANCountry.values.map((ASEANCountry country) {
              return DropdownMenuItem<ASEANCountry>(
                value: country,
                child: Text(country.toString().split('.').last),
              );
            }).toList(),
          ),
          Expanded(
            child: StreamBuilder<List<University>>(
              stream: _universityBloc.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else {
                  final universities = snapshot.data!;
                  return ListView.builder(
                    itemCount: universities.length,
                    itemBuilder: (context, index) {
                      final university = universities[index];
                      return ListTile(
                        title: Text(university.name),
                        subtitle: Text(university.website),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _universityBloc.dispose();
    super.dispose();
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: UniversityListView(),
  ));
}
