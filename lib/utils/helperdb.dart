// import 'package:flutter/material.dart';
import 'dart:developer';

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
    List<String>? photos,
    List<String>? videos,
  }) async {
    final trip = Trip(
      busNumber: busNumber,
      routeName: routeName,
      source: source,
      destination: destination,
      dateTime: dateTime.toIso8601String(),
      noteTitle: noteTitle,
      noteBody: noteBody,
      photos: photos,
      videos: videos,
    );
    log("insett ${trip.videos}");
    final id = await dbHelper.insertTrip(trip);
    return id;
  }
