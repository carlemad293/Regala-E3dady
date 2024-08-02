// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Help Screen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.orangeAccent,
          background: Colors.white,
        ),
        textTheme: TextTheme(
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          titleMedium: TextStyle(fontSize: 20, color: Colors.blueGrey),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
          bodyLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        listTileTheme: ListTileThemeData(
          tileColor: Colors.white,
          textColor: Colors.black,
          iconColor: Colors.blueAccent,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.blueAccent,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: HelpScreen(),
    );
  }
}

class HelpScreen extends StatefulWidget {
  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<Map<String, String>> fixers = [
    {'name': 'U. Mina Nazeh', 'number': '+201003319931'},
    {'name': 'U. Rafik Kamal', 'number': '+201222201095'},
    {'name': 'U. Usama Youssef', 'number': '+201222469147'},
    {'name': 'U. Andrew Gendy', 'number': '+201224509880'},
    {'name': 'U. Mina Ihab', 'number': '+201063191068'},
    {'name': 'U. KOJO⚡️', 'number': '+201069344594'},
    {'name': 'U. Tony', 'number': '+201010012395'},
    {'name': 'U. John Micheal', 'number': '+201023026372'},
    {'name': 'U. John Amir', 'number': '+201285144779'},
    {'name': 'U. John Ragy', 'number': '+201280000284'},
    {'name': 'U. Mark Maged', 'number': '+201067494010'},
    {'name': 'U. George', 'number': '+201285661308'},
    {'name': 'U. Bishoy Emile', 'number': '+201285635730'},
  ];

  List<Map<String, String>> filteredFixers = [];
  TextEditingController searchController = TextEditingController();
  String sortBy = 'name'; // Default sort by name

  @override
  void initState() {
    super.initState();
    filteredFixers = fixers;
    searchController.addListener(() {
      filterFixers();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void filterFixers() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredFixers = fixers.where((fixer) {
        final name = fixer['name']!.toLowerCase();
        final number = fixer['number']!.toLowerCase();
        return name.contains(query) || number.contains(query);
      }).toList();
      sortFixers(); // Sort the filtered results
    });
  }

  void sortFixers() {
    setState(() {
      filteredFixers.sort((a, b) {
        if (sortBy == 'name') {
          return a['name']!.compareTo(b['name']!);
        } else if (sortBy == 'number') {
          return a['number']!.compareTo(b['number']!);
        }
        return 0;
      });
    });
  }

  Widget highlightText(String text, String query, {bool isName = false}) {
    if (query.isEmpty) {
      return Text(
        text,
        style: isName ? TextStyle(fontWeight: FontWeight.bold) : null,
      );
    }
    final matches = query.toLowerCase().allMatches(text.toLowerCase());
    if (matches.isEmpty) {
      return Text(
        text,
        style: isName ? TextStyle(fontWeight: FontWeight.bold) : null,
      );
    }
    final spans = <TextSpan>[];
    int start = 0;
    for (final match in matches) {
      if (match.start != start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: TextStyle(backgroundColor: Colors.yellow),
      ));
      start = match.end;
    }
    if (start != text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return RichText(
      text: TextSpan(
        style: isName
            ? TextStyle(fontWeight: FontWeight.bold, color: Colors.black)
            : TextStyle(color: Colors.black),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help Screen'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[200]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
                margin: EdgeInsets.only(bottom: 20.0),
                child: ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.push_pin, color: Colors.red),
                      SizedBox(width: 8),
                      CircleAvatar(
                        backgroundImage: AssetImage('assets/logo_el_group.png'), // Group icon from assets
                        radius: 22,
                      ),
                    ],
                  ),
                  title: Text(
                    'رجالة اعدادي مارجرجس',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.arrow_forward),
                    onPressed: () async {
                      final Uri url = Uri.parse('https://chat.whatsapp.com/J3vJ3dM0i5AISJnxV2Vq5e');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not launch WhatsApp')),
                        );
                      }
                    },
                  ),
                  onTap: () async {
                    final Uri url = Uri.parse('https://chat.whatsapp.com/J3vJ3dM0i5AISJnxV2Vq5e');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not launch WhatsApp')),
                      );
                    }
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  DropdownButton<String>(
                    value: sortBy,
                    onChanged: (String? newValue) {
                      setState(() {
                        sortBy = newValue!;
                        sortFixers();
                      });
                    },
                    items: <String>['name', 'number']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text('Sort by $value'),
                      );
                    }).toList(),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredFixers.length,
                  itemBuilder: (context, index) {
                    final fixer = filteredFixers[index];
                    final name = fixer['name']!;
                    final number = fixer['number']!;
                    return Dismissible(
                      key: Key(number),
                      direction: DismissDirection.horizontal,
                      background: slideRightBackground(),
                      secondaryBackground: slideLeftBackground(),
                      confirmDismiss: (direction) async {
                        if (await Vibration.hasVibrator() ?? false) {
                          Vibration.vibrate(duration: 50); // Vibration on swipe
                        }
                        if (direction == DismissDirection.startToEnd) {
                          _launchWhatsApp(context, number);
                        } else if (direction == DismissDirection.endToStart) {
                          _launchCall(context, number);
                        }
                        return false; // Contact goes back to its place
                      },
                      child: GestureDetector(
                        onLongPress: () {
                          _showActionDialog(context, name, number);
                        },
                        child: Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                            title: highlightText(name, searchController.text, isName: true),
                            subtitle: highlightText(number, searchController.text),
                            trailing: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100], // Subtle background for the icon
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2), // Refined shadow
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(Icons.copy),
                                onPressed: () async {
                                  Clipboard.setData(ClipboardData(text: number));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$number copied to clipboard')),
                                  );
                                  if (await Vibration.hasVibrator() ?? false) {
                                    Vibration.vibrate(duration: 50); // Vibration on copy
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget slideRightBackground() {
    return Container(
      color: Colors.transparent, // Transparent background
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: 20.0),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3), // Refined shadow
              spreadRadius: 2,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 30,
          child: FaIcon(
            FontAwesomeIcons.whatsapp,
            color: Colors.green,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget slideLeftBackground() {
    return Container(
      color: Colors.transparent, // Transparent background
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20.0),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3), // Refined shadow
              spreadRadius: 2,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 30,
          child: Icon(
            Icons.call,
            color: Colors.blue,
            size: 30,
          ),
        ),
      ),
    );
  }

  void _showActionDialog(BuildContext context, String name, String number) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Action'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
                title: Text('WhatsApp'),
                onTap: () async {
                  if (await Vibration.hasVibrator() ?? false) {
                    Vibration.vibrate(duration: 50);
                  }
                  _launchWhatsApp(context, number);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.call, color: Colors.blue),
                title: Text('Call'),
                onTap: () async {
                  if (await Vibration.hasVibrator() ?? false) {
                    Vibration.vibrate(duration: 50);
                  }
                  _launchCall(context, number);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _launchWhatsApp(BuildContext context, String number) async {
    final cleanedNumber = number.replaceAll(RegExp(r'\D'), ''); // Remove non-digit characters
    final Uri url = Uri.parse('https://wa.me/$cleanedNumber');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch WhatsApp')),
      );
    }
  }

  void _launchCall(BuildContext context, String number) async {
    final Uri url = Uri.parse('tel:$number');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not make the call')),
      );
    }
  }
}
