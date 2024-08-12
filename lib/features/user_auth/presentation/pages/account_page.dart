import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/app_drawer.dart';

class AccountScreen extends StatefulWidget {
  final User user;

  const AccountScreen({Key? key, required this.user}) : super(key: key);

  @override
  _AccountScreenPageState createState() => _AccountScreenPageState();
}

class _AccountScreenPageState extends State<AccountScreen> with WidgetsBindingObserver {
  final TextEditingController _nameController = TextEditingController();
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  int _points = 0;
  int _previousPoints = 0;
  late DocumentReference _userDoc;
  String? _imageUrl;
  bool _isLoadingImage = false;
  bool _newPointsIndicator = false;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userDoc = FirebaseFirestore.instance.collection('users').doc(widget.user.email);
    _loadPreferences();
    _loadUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _previousPoints = _prefs.getInt('previousPoints') ?? 0;
    _newPointsIndicator = _prefs.getBool('newPointsIndicator') ?? false;
  }

  Future<void> _savePreferences() async {
    await _prefs.setInt('previousPoints', _points);
    await _prefs.setBool('newPointsIndicator', _newPointsIndicator);
  }

  Future<void> _loadUserData() async {
    final doc = await _userDoc.get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _nameController.text = data['name'] as String? ?? '';
        _points = data['points'] as int? ?? 0;
        _imageUrl = data['image_url'] as String?;

        // Detect changes in points
        if (_points != _previousPoints) {
          _newPointsIndicator = true;
        } else {
          _newPointsIndicator = false;
        }
        _savePreferences();
      });
    }
  }

  Future<void> _saveUserData() async {
    await _userDoc.set({
      'name': _nameController.text,
      'points': _points,
      'image_url': _imageUrl,
    }, SetOptions(merge: true));
  }

  Future<void> _pickImage() async {
    final XFile? selectedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (selectedImage != null) {
      setState(() {
        _image = selectedImage;
        _isLoadingImage = true;
      });
      await _uploadImageToStorage();
    }
  }

  Future<void> _uploadImageToStorage() async {
    final email = widget.user.email;
    if (email == null) {
      print('User email is null');
      return;
    }

    final storageRef = FirebaseStorage.instance.ref();
    final profileImagesRef = storageRef.child('profile_images/$email.png');

    try {
      final uploadTask = await profileImagesRef.putFile(File(_image!.path));
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      setState(() {
        _imageUrl = downloadUrl;
        _isLoadingImage = false;
      });
      await _saveUserData();
    } catch (e) {
      print('Error uploading image: $e');
      setState(() {
        _isLoadingImage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int pointsDifference = _points - _previousPoints;
    final String pointsDifferenceText =
    pointsDifference > 0 ? '+$pointsDifference' : '$pointsDifference';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.person),
            SizedBox(width: 8),
            Text('Account'),
          ],
        ),
      ),
      drawer: AppDrawer(user: widget.user),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            FutureBuilder<void>(
              future: _loadUserData(),
              builder: (context, snapshot) {
                if (_isLoadingImage) {
                  return CircleAvatar(
                    radius: 50,
                    child: CircularProgressIndicator(),
                  );
                } else {
                  return CircleAvatar(
                    radius: 50,
                    backgroundImage: _imageUrl != null
                        ? NetworkImage(_imageUrl!)
                        : AssetImage('assets/img.png') as ImageProvider,
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 20,
                              child: Icon(Icons.edit, color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
              ),
            ),
            SizedBox(height: 10),
            Text(
              widget.user.email ?? 'No email',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _saveUserData();
                _loadUserData(); // Refresh data to ensure points are updated
              },
              child: Text('Save'),
            ),
            SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                setState(() {
                  _newPointsIndicator = false; // Clear the indicator on tap
                  _savePreferences();
                });
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(
                    'Points: $_points 🪙',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  if (_newPointsIndicator)
                    Positioned(
                      right: -20,
                      top: -20,
                      child: AnimatedOpacity(
                        duration: Duration(seconds: 1),
                        opacity: _newPointsIndicator ? 0.8 : 0.0,
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: pointsDifference > 0 ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            pointsDifferenceText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
