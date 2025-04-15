import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class CO2TrackerPage extends StatefulWidget {
  const CO2TrackerPage({super.key});

  @override
  State<CO2TrackerPage> createState() => _CO2TrackerPageState();
}

class _CO2TrackerPageState extends State<CO2TrackerPage> {
  // Sample data for demonstration
  final List<Map<String, dynamic>> _rideHistory = [
    {
      'date': DateTime.now().subtract(const Duration(days: 6)),
      'distance': 10.5,
      'passengers': 2,
      'savings': 2.1,
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'distance': 15.0,
      'passengers': 3,
      'savings': 3.0,
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 4)),
      'distance': 8.2,
      'passengers': 1,
      'savings': 0.82,
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'distance': 12.7,
      'passengers': 2,
      'savings': 2.54,
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'distance': 5.3,
      'passengers': 1,
      'savings': 0.53,
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'distance': 18.4,
      'passengers': 3,
      'savings': 3.68,
    },
    {
      'date': DateTime.now(),
      'distance': 9.6,
      'passengers': 2,
      'savings': 1.92,
    },
  ];

  double get _totalSavings => _rideHistory.fold(0, (sum, ride) => sum + ride['savings']);
  double get _totalDistance => _rideHistory.fold(0, (sum, ride) => sum + ride['distance']);
  int get _totalPassengers => _rideHistory.fold(0, (sum, ride) => sum + (ride['passengers'] as int));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CO2 Tracker'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total CO2 Saved',
                    '${_totalSavings.toStringAsFixed(1)} kg',
                    Icons.eco,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Distance',
                    '${_totalDistance.toStringAsFixed(1)} km',
                    Icons.directions_car,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryCard(
              'Total Passengers',
              '$_totalPassengers',
              Icons.people,
              Colors.orange,
            ),
            const SizedBox(height: 32),
            // CO2 Savings Chart
            const Text(
              'Weekly CO2 Savings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < _rideHistory.length) {
                            return Text(
                              DateFormat('MMM d').format(_rideHistory[value.toInt()]['date']),
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        _rideHistory.length,
                        (index) => FlSpot(
                          index.toDouble(),
                          _rideHistory[index]['savings'],
                        ),
                      ),
                      isCurved: true,
                      color: Colors.teal,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.teal.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Ride History
            const Text(
              'Ride History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._rideHistory.reversed.map((ride) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.directions_car, color: Colors.teal),
                    title: Text(
                      '${ride['distance'].toStringAsFixed(1)} km with ${ride['passengers']} passenger${ride['passengers'] > 1 ? 's' : ''}',
                    ),
                    subtitle: Text(
                      DateFormat('MMM d, yyyy').format(ride['date']),
                    ),
                    trailing: Text(
                      '${ride['savings'].toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}