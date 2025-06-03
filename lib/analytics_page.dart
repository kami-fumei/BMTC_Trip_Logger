import 'package:flutter/material.dart';
import 'package:trip_logger/buslist.dart';
import 'package:trip_logger/services/db.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final dbHelper = DatabaseHelper();
  late Future<Map<String, dynamic>> _analyticsFuture;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = _fetchAnalytics();
  }

  Future<void> _showCustomDateRangeDialog(DateTime first, DateTime last) async {
    DateTime tempStart = _startDate ?? first;
    DateTime tempEnd = _endDate ?? last;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Date Range'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Start: ${DateFormat('dd MMM yyyy').format(tempStart)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: tempStart,
                    firstDate: first,
                    lastDate: last,
                  );
                  if (picked != null) {
                    setDialogState(() {
                      tempStart = picked;
                      if (tempEnd.isBefore(tempStart)) tempEnd = tempStart;
                    });
                  }
                },
              ),
              ListTile(
                title: Text('End: ${DateFormat('dd MMM yyyy').format(tempEnd)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: tempEnd,
                    firstDate: tempStart,
                    lastDate: last,
                  );
                  if (picked != null) {
                    setDialogState(() {
                      tempEnd = picked;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Apply'),
              onPressed: () {
                setState(() {
                  _startDate = tempStart;
                  _endDate = tempEnd;
                  _analyticsFuture = _fetchAnalytics();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchAnalytics() async {
    final trips = await dbHelper.getAllTrips();

    // Find first and last trip dates
    DateTime? firstTrip, lastTrip;
    for (var trip in trips) {
      final date = DateTime.tryParse(trip.dateTime);
      if (date != null) {
        if (firstTrip == null || date.isBefore(firstTrip)) firstTrip = date;
        if (lastTrip == null || date.isAfter(lastTrip)) lastTrip = date;
      }
    }

    // Use selected range or default to first/last trip
    final start = _startDate ?? firstTrip;
    final end = _endDate ?? lastTrip;

    // Filter trips by selected date range
    final filteredTrips = trips.where((trip) {
      final date = DateTime.tryParse(trip.dateTime);
      if (date == null || start == null || end == null) return false;
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();

    final totalTrips = filteredTrips.length;
    final routeCounts = <String, int>{};
    final busCounts = <String, int>{};
    final months = <String, int>{};

    for (var trip in filteredTrips) {
      final route = trip.routeName ?? '';
      final bus = trip.busNumber;
      final date = DateTime.tryParse(trip.dateTime);

      if (route.isNotEmpty) {
        routeCounts[route] = (routeCounts[route] ?? 0) + 1;
      }
      if (bus.isNotEmpty) {
        busCounts[bus] = (busCounts[bus] ?? 0) + 1;
      }
      if (date != null) {
        final monthKey = DateFormat('yyyy-MM').format(date);
        months[monthKey] = (months[monthKey] ?? 0) + 1;
      }
    }

    final mostTraveledRoute = routeCounts.entries.isEmpty
        ? null
        : routeCounts.entries.reduce((a, b) => a.value > b.value ? a : b);

    final mostUsedBus = busCounts.entries.isEmpty
        ? null
        : busCounts.entries.reduce((a, b) => a.value > b.value ? a : b);

    return {
      'totalTrips': totalTrips,
      'uniqueRoutes': routeCounts.length,
      'uniqueBuses': busCounts.length,
      'firstTrip': start,
      'lastTrip': end,
      'mostTraveledRoute': mostTraveledRoute,
      'mostUsedBus': mostUsedBus,
      'routeCounts': routeCounts,
      'busCounts': busCounts,
      'months': months,
      'allFirstTrip': firstTrip,
      'allLastTrip': lastTrip,
    };
  }

  void _showListDialog(BuildContext context, String title, List<String> items, {bool isRoute = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(items[i]),
              onTap: () {
                Navigator.pop(context); // Close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => isRoute
                        ? Buslist(routeName: items[i])
                        : Buslist(busNumber: items[i]),
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Analytics')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final routeCounts = data['routeCounts'] as Map<String, int>;
          final busCounts = data['busCounts'] as Map<String, int>;
          final months = data['months'] as Map<String, int>;
          final colors = [
            Colors.blue,
            Colors.green,
            Colors.orange,
            Colors.purple,
            Colors.red,
            Colors.teal,
            Colors.brown,
            Colors.pink,
            Colors.indigo,
            Colors.cyan,
          ];

          // Date range UI
          final allFirstTrip = data['allFirstTrip'] as DateTime?;
          final allLastTrip = data['allLastTrip'] as DateTime?;
          final start = data['firstTrip'] as DateTime?;
          final end = data['lastTrip'] as DateTime?;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (allFirstTrip != null && allLastTrip != null)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'From: ${DateFormat('dd MMM yyyy').format(start ?? allFirstTrip)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'To: ${DateFormat('dd MMM yyyy').format(end ?? allLastTrip)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: const Text('Change'),
                        onPressed: () {
                          _showCustomDateRangeDialog(allFirstTrip, allLastTrip);
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.analytics, color: Colors.blue),
                  title: const Text('Total Trips'),
                  trailing: Text('${data['totalTrips']}'),
                ),
              ),
              // Unique Routes (clickable)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.route, color: Colors.deepPurple),
                  title: const Text('Unique Routes'),
                  trailing: Text('${data['uniqueRoutes']}'),
                  onTap: () {
                    final routes = routeCounts.keys.toList()..sort();
                    _showListDialog(context, 'Unique Routes', routes, isRoute: true);
                  },
                ),
              ),
              // Unique Buses (clickable)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_bus, color: Colors.teal),
                  title: const Text('Unique Buses'),
                  trailing: Text('${data['uniqueBuses']}'),
                  onTap: () {
                    final buses = busCounts.keys.toList()..sort();
                    _showListDialog(context, 'Unique Buses', buses, isRoute: false);
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.indigo),
                  title: const Text('First Trip'),
                  trailing: Text(
                    data['firstTrip'] != null
                        ? DateFormat('dd MMM yyyy').format(data['firstTrip'])
                        : 'N/A',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.red),
                  title: const Text('Last Trip'),
                  trailing: Text(
                    data['lastTrip'] != null
                        ? DateFormat('dd MMM yyyy').format(data['lastTrip'])
                        : 'N/A',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.alt_route, color: Colors.green),
                  title: const Text('Most Traveled Route'),
                  subtitle: Text(
                    data['mostTraveledRoute'] != null
                        ? '${data['mostTraveledRoute'].key}'
                        : 'N/A',
                  ),
                  trailing: Text(
                    data['mostTraveledRoute'] != null
                        ? '${data['mostTraveledRoute'].value} times'
                        : '',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_bus, color: Colors.orange),
                  title: const Text('Most Used Bus Number'),
                  subtitle: Text(
                    data['mostUsedBus'] != null
                        ? '${data['mostUsedBus'].key}'
                        : 'N/A',
                  ),
                  trailing: Text(
                    data['mostUsedBus'] != null
                        ? '${data['mostUsedBus'].value} times'
                        : '',
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (routeCounts.isNotEmpty) ...[
                const Text(
                  'Trips per Route',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: List.generate(routeCounts.length, (i) {
                        final entry = routeCounts.entries.elementAt(i);
                        return PieChartSectionData(
                          color: colors[i % colors.length],
                          value: entry.value.toDouble(),
                          title: entry.key,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Legend
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: List.generate(routeCounts.length, (i) {
                    final entry = routeCounts.entries.elementAt(i);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          color: colors[i % colors.length],
                        ),
                        const SizedBox(width: 6),
                        Text(entry.key),
                        const SizedBox(width: 10),
                        Text('(${entry.value})'),
                      ],
                    );
                  }),
                ),
              ],
              const SizedBox(height: 32),
              if (months.isNotEmpty) ...[
                const Text(
                  'Trips per Month',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (months.values.isNotEmpty)
                          ? (months.values.reduce((a, b) => a > b ? a : b) + 1).toDouble()
                          : 1,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= months.length) return const SizedBox();
                              final key = months.keys.elementAt(idx);
                              return Text(
                                key.substring(2), // show yy-MM
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(months.length, (i) {
                        final value = months.values.elementAt(i);
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: value.toDouble(),
                              color: colors[i % colors.length],
                              width: 18,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}