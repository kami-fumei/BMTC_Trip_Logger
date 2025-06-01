// import 'package:flutter/material.dart';
import '../services/db.dart';
import '../services/model.dart';

final dbHelper = DatabaseHelper();

Future<int> insertTripWithFields( {
    required String busNumber,
    required String routeName,
    required DateTime dateTime,
    String? source,
    String? destination,
    String? noteTitle,
    String? noteBody,
    String? photos,
    String? videos,
  }) async {
    final trip = Trip(
      busNumber: busNumber,
      routeName: routeName,
      source: source,
      destination: destination,
      dateTime: dateTime.toIso8601String(),
      noteTitle: noteTitle,
      noteBody: noteBody,
      photos: photos ,
      videos: videos,
    );
    final id = await dbHelper.insertTrip(trip);
    return id;
  }
