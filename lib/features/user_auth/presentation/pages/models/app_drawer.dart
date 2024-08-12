import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:your_project_name/features/user_auth/presentation/pages/account_page.dart';
import 'package:your_project_name/features/user_auth/presentation/pages/help_page.dart';
import 'package:your_project_name/features/user_auth/presentation/pages/points_page.dart';
import 'package:your_project_name/features/user_auth/presentation/pages/Mwa3ed_page.dart';
import 'package:your_project_name/features/user_auth/presentation/pages/dawra_organizer_screen.dart';

import '../home_page.dart';

class AppDrawer extends StatelessWidget {
  final User user;

  AppDrawer({required this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/regala_e3dady.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3), // Darken the image
                  BlendMode.darken,
                ),
              ),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                'Regala E3dady',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(2.0, 2.0), // Slight shadow for contrast
                      blurRadius: 25.0,
                      color: Colors.white.withOpacity(1),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildListTile(
                  context,
                  icon: Icons.home,
                  title: 'Home',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(user: user, userName: '', points: 0),
                      ),
                    );
                  },
                ),
                Divider(),
                _buildListTile(
                  context,
                  icon: Icons.person,
                  title: 'Account',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AccountScreen(user: user)),
                    );
                  },
                ),
                Divider(),
                _buildListTile(
                  context,
                  icon: Icons.help,
                  title: 'Help',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HelpScreen()),
                    );
                  },
                ),
                Divider(),
                _buildListTile(
                  context,
                  icon: Icons.monetization_on,
                  title: 'Points',
                  onTap: () async {
                    bool isAdmin = await _checkIfAdmin(user.email ?? '');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PointScreen(isAdmin: isAdmin)),
                    );
                  },
                ),
                Divider(),
                _buildListTile(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Calendar',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WebViewApp()),
                    );
                  },
                ),
                Divider(),
                _buildListTile(
                  context,
                  icon: Icons.drive_file_move,
                  title: '5edma Resources',
                  onTap: () async {
                    String googleDriveLink = await _getGoogleDriveLink();
                    if (await canLaunch(googleDriveLink)) {
                      await launch(googleDriveLink);
                    } else {
                      print('Could not launch $googleDriveLink');
                    }
                  },
                ),
                Divider(),
                _buildListTile(
                  context,
                  icon: Icons.sports_esports,
                  title: 'Dawra Organizer',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DawraOrganizerScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ListTile _buildListTile(BuildContext context, {required IconData icon, required String title, required Function() onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20.0),
    );
  }

  Future<bool> _checkIfAdmin(String? email) async {
    if (email == null) return false;

    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(email)
          .get();

      return adminDoc.exists;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  Future<String> _getGoogleDriveLink() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('resources')
          .doc('google_drive_link')
          .get();

      if (doc.exists) {
        return doc['link'];
      } else {
        return 'https://drive.google.com/drive/';
      }
    } catch (e) {
      print('Error fetching Google Drive link: $e');
      return 'https://drive.google.com/drive/';
    }
  }
}