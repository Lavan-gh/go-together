import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:url_launcher/url_launcher.dart';

class SecurityScreen extends StatefulWidget {
  @override
  _SecurityScreenState createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  bool _shareLocation = false;
  bool _emergencyAlerts = true;
  List<Map<String, dynamic>> _emergencyContacts = [];
  final _places = GoogleMapsPlaces(apiKey: 'YOUR_API_KEY');

  @override
  void initState() {
    super.initState();
    _loadEmergencyContacts();
  }

  Future<void> _loadEmergencyContacts() async {
    if (user == null) return;

    try {
      final contactsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('emergency_contacts')
          .get();

      setState(() {
        _emergencyContacts = contactsSnapshot.docs
            .map((doc) => doc.data())
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading emergency contacts: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addEmergencyContact() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Get values from text fields
              Navigator.pop(context, {'name': 'Test', 'phone': '1234567890'});
            },
            child: Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('emergency_contacts')
            .add(result);

        _loadEmergencyContacts();
      } catch (e) {
        print('Error adding emergency contact: $e');
      }
    }
  }

  Future<void> _callEmergencyContact(Map<String, dynamic> contact) async {
    final url = 'tel:${contact['phone']}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not make the call')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Security'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safety Features',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('Share Live Location'),
                    subtitle: Text('Share your location with emergency contacts'),
                    value: _shareLocation,
                    onChanged: (value) {
                      setState(() => _shareLocation = value);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Emergency Alerts'),
                    subtitle: Text('Receive alerts for nearby incidents'),
                    value: _emergencyAlerts,
                    onChanged: (value) {
                      setState(() => _emergencyAlerts = value);
                    },
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Emergency Contacts',
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: _addEmergencyContact,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (_emergencyContacts.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.contacts,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No emergency contacts added',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _emergencyContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _emergencyContacts[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(contact['name'][0]),
                          ),
                          title: Text(contact['name']),
                          subtitle: Text(contact['phone']),
                          trailing: IconButton(
                            icon: Icon(Icons.phone),
                            onPressed: () => _callEmergencyContact(contact),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
} 