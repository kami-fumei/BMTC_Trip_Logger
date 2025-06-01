// lib/screens/bus_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:trip_logger/services/db.dart';
import 'package:trip_logger/services/model.dart';
import 'package:trip_logger/utils/utils.dart';


/// Screen to display all trips (notes, photos, videos) for a specific bus number.
class BusDetailScreen extends StatefulWidget {
  final String busNumber;

  const BusDetailScreen({super.key, required this.busNumber});

  @override
  _BusDetailScreenState createState() => _BusDetailScreenState();
}

class _BusDetailScreenState extends State<BusDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late Future<List<Trip>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips() {
    _tripsFuture = _dbHelper.getTripsByBusNumber(widget.busNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bus ${widget.busNumber} Trips'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Trip>>(
        future: _tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          }
          final trips = snapshot.data;
          if (trips == null || trips.isEmpty) {
            return const Center(child: Text('No trips recorded'));
          }
          return ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text(trip.noteTitle ?? 'No Title'),
                  subtitle: Text(
                    '${DateTime.parse(trip.dateTime).toLocal()}'.split('.').first,
                  ),
                  children: [
                    if (trip.noteBody != null && trip.noteBody!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(trip.noteBody!),
                      ),
                    if (trip.photos != null && trip.photos!.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: trip.photos!.length,
                          itemBuilder: (ctx, i) {
                            return Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.file(
                                File(trip.photos![i]),
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
                    if (trip.videos != null && trip.videos is List && trip.videos!.isNotEmpty)
                      Column(
                        children: (trip.videos as List).map<Widget>((path) {
                          return ListTile(
                            leading: const Icon(Icons.videocam),
                            title: Text(path.toString().split('/').last),
                            onTap: () {
                              // Optional: implement video player
                            },
                          );
                        }).toList(),
                      ),
                    OverflowBar(
                      children: [
                        TextButton(
                          onPressed: () async {
                            final summary = await _dbHelper.previouslyTraveled(widget.busNumber);
                            await showAlreadyTraveledDialog(
                              context,
                              widget.busNumber,
                              summary,
                            );
                          },
                          child: const Text('History'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
