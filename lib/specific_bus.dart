// ignore: unused_import
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trip_logger/widgets/image_video_open.dart';
import 'package:trip_logger/services/db.dart';
import 'package:trip_logger/services/model.dart';

/// Screen to display details for a single Trip by its ID, using FutureBuilder.
class SingleTripScreen extends StatefulWidget {
  final int id;
  const SingleTripScreen({Key? key, required this.id}) : super(key: key);

  @override
  _SingleTripScreenState createState() => _SingleTripScreenState();
}

class _SingleTripScreenState extends State<SingleTripScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late var _tripFuture;

  @override
  void initState() {
    super.initState();
    _tripFuture = _dbHelper.getTripsById(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Details'), centerTitle: true),
      body: FutureBuilder(
        future: _tripFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \ ${snapshot.error}'));
          }
          final trips = snapshot.data as List<Trip>?;
          if (trips == null || trips.isEmpty) {
            return const Center(child: Text('Trip not found'));
          }
          final trip = trips[0];

          // log("${trip.photos?[0]}  ${trip.videos}");

          final dateStr = DateFormat(
            'h:mma dd/MM/yy',
          ).format(DateTime.parse(trip.dateTime));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bus: \ ${trip.busNumber}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Route: \ ${trip.routeName}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Divider(height: 24),
                    Text(
                      'Date: \ $dateStr',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    if (trip.noteTitle!=null&&trip.noteTitle.toString().trim() != '') ...[
                      Text(
                        'Notes: ${trip.noteTitle!}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (trip.noteBody != null && trip.noteBody!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(trip.noteBody!),
                      const SizedBox(height: 16),
                    ],
                    if ((trip.source.toString().trim() != '')&&(trip.source!=null) ) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "From: ${trip.source}",
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.teal[700],
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_sharp,
                            size: 20,
                            color: Colors.teal[700],
                          ),
                          SizedBox(width: 4),
                          Text(
                            "To: ${trip.destination}",
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.teal[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                if (trip.photos != null) ...[
                  const Text(
                    'Photos:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: trip.photos!.length,
                      itemBuilder: (ctx, i) {
                        final file = File(trip.photos![i]);
                        if (!file.existsSync()) {
                          return Container(
                            alignment: Alignment.center,
                            child: const Text("File not found\nIt appears to be you Deleted File from the cash", style: TextStyle(color: Colors.red,fontSize: 16)),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullImageViewer(
                                    imagePaths: trip.photos!,
                                    initialIndex: i,
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                file,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),                    
                  if (trip.videos != null  ) ...[
                      const Text(
                        'Videos:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children:
                            trip.videos!.map((path) {
                              return ListTile(
                                leading: const Icon(Icons.videocam),
                                title: Text(path.split('/').last),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              FullVideoPlayer(videoPath: path),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                      ),
                    ],
                  ],
                  ]
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
