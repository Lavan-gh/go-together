import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_together/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
        // TODO: Upload image to Firebase Storage
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  SizedBox(height: 24),
                  _buildUserStats(),
                  SizedBox(height: 24),
                  _buildUserInfo(),
                  SizedBox(height: 24),
                  _buildPreferences(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : null,
                  child: _profileImage == null
                      ? Text(
                          _userData?['name']?[0] ?? '?',
                          style: TextStyle(
                            fontSize: 32,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.camera_alt, size: 20),
                      color: AppTheme.secondaryColor,
                      onPressed: _pickImage,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              _userData?['name'] ?? 'User',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              _userData?['email'] ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStats() {
    final treesEquivalent = (_userData?['co2Saved'] ?? 0.0) / 21.77;
    final percentage = (treesEquivalent * 100).toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.directions_car,
                  'Total Rides',
                  '${_userData?['totalRides'] ?? 0}',
                ),
                _buildStatItem(
                  Icons.eco,
                  'CO2 Saved',
                  '${_userData?['co2Saved']?.toStringAsFixed(1) ?? '0.0'} kg',
                ),
                _buildStatItem(
                  Icons.star,
                  'Rating',
                  '${_userData?['rating']?.toStringAsFixed(1) ?? '5.0'}',
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.forest,
                    color: AppTheme.accentColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Equivalent to ${treesEquivalent.toStringAsFixed(1)} trees saved',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.accentColor,
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

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 20,
              ),
            ),
            SizedBox(height: 16),
            _buildInfoItem(
              Icons.person,
              'Name',
              _userData?['name'] ?? 'Not set',
            ),
            SizedBox(height: 12),
            _buildInfoItem(
              Icons.email,
              'Email',
              _userData?['email'] ?? 'Not set',
            ),
            SizedBox(height: 12),
            _buildInfoItem(
              Icons.phone,
              'Phone',
              _userData?['phone'] ?? 'Not set',
            ),
            SizedBox(height: 12),
            _buildInfoItem(
              Icons.calendar_today,
              'Member Since',
              _userData?['createdAt']?.toDate().toString().split(' ')[0] ?? 'Not set',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreferences() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferences',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Notifications'),
              subtitle: Text('Receive ride updates and alerts'),
              value: _userData?['notifications'] ?? true,
              onChanged: (value) {
                // TODO: Update notification preference
              },
            ),
            SwitchListTile(
              title: Text('Dark Mode'),
              subtitle: Text('Use dark theme'),
              value: _userData?['darkMode'] ?? false,
              onChanged: (value) {
                // TODO: Update dark mode preference
              },
            ),
          ],
        ),
      ),
    );
  }
} 