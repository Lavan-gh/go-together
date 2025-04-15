import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_together/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';

class CO2TrackerScreen extends StatefulWidget {
  @override
  _CO2TrackerScreenState createState() => _CO2TrackerScreenState();
}

class _CO2TrackerScreenState extends State<CO2TrackerScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  double _totalCO2Saved = 0.0;
  List<Map<String, dynamic>> _co2History = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCO2Data();
  }

  Future<void> _loadCO2Data() async {
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _totalCO2Saved = userDoc.data()?['co2Saved'] ?? 0.0;
        });
      }

      final ridesSnapshot = await FirebaseFirestore.instance
          .collection('rides')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _co2History = ridesSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'co2Saved': data['co2Saved'] ?? 0.0,
            'date': data['date'] ?? '',
            'distance': data['distance'] ?? 0.0,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading CO2 data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CO2 Tracker'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCO2Summary(),
                  SizedBox(height: 24),
                  _buildCO2Chart(),
                  SizedBox(height: 24),
                  _buildEnvironmentalImpact(),
                  SizedBox(height: 24),
                  _buildCO2History(),
                ],
              ),
            ),
    );
  }

  Widget _buildCO2Summary() {
    final treesEquivalent = _totalCO2Saved / 21.77; // 1 tree absorbs about 21.77 kg CO2 per year
    final percentage = (treesEquivalent * 100).toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total CO2 Saved',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${_totalCO2Saved.toStringAsFixed(1)} kg',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Equivalent to ${treesEquivalent.toStringAsFixed(1)} trees',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.eco,
                        size: 32,
                        color: AppTheme.accentColor,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '$percentage%',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: _totalCO2Saved / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCO2Chart() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CO2 Savings Trend',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _co2History.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value['co2Saved'].toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: AppTheme.accentColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.accentColor.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentalImpact() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Environmental Impact',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 16),
            _buildImpactItem(
              Icons.local_gas_station,
              'Gasoline Saved',
              '${(_totalCO2Saved * 0.4).toStringAsFixed(1)} liters',
            ),
            SizedBox(height: 12),
            _buildImpactItem(
              Icons.monetization_on,
              'Money Saved',
              '\$${(_totalCO2Saved * 0.5).toStringAsFixed(2)}',
            ),
            SizedBox(height: 12),
            _buildImpactItem(
              Icons.forest,
              'Trees Equivalent',
              '${(_totalCO2Saved / 21.77).toStringAsFixed(1)} trees',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.accentColor),
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

  Widget _buildCO2History() {
    if (_co2History.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.directions_car,
                size: 48,
                color: AppTheme.greyColor,
              ),
              SizedBox(height: 16),
              Text(
                'No rides yet',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Start sharing rides to save CO2!',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Rides',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 20,
          ),
        ),
        SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _co2History.length,
          itemBuilder: (context, index) {
            final entry = _co2History[index];
            final treesSaved = (entry['co2Saved'] / 21.77).toStringAsFixed(1);
            return Card(
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: AppTheme.accentColor,
                  ),
                ),
                title: Text('${entry['source']} → ${entry['destination']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry['date']} • ₹${entry['cost']}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${entry['co2Saved'].toStringAsFixed(1)} kg CO2 • ${treesSaved} trees',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${entry['passengers']} passengers',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '₹${(entry['cost'] / entry['passengers']).toStringAsFixed(0)} each',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
} 