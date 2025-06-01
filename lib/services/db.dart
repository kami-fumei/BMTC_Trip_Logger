import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import './model.dart';

class DatabaseHelper {
  // Table and column names
  static const String tableTrips = 'trips';
  static const String colId = 'id';
  static const String colBusNumber = 'bus_number';
  static const String colRouteName = 'route_name';
  static const String colSource = 'source';
  static const String colDestination = 'destination';
  static const String colDateTime = 'date_time';
  static const String colNoteTitle = 'note_title';
  static const String colNoteBody = 'note_body';
  static const String colPhotos = 'photos';
  static const String colVideos = 'videos';

  // Singleton instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  // Initialize SQLite DB
  Future<Database> _initDb() async {
    Directory dir = await getApplicationDocumentsDirectory();
       String path = join(dir.path, 'trip_logger.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    // 
    await db.execute('''
      CREATE TABLE $tableTrips (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colBusNumber TEXT NOT NULL,
        $colRouteName TEXT NOT NULL,
        $colDateTime TEXT NOT NULL,
        $colSource TEXT ,
        $colDestination TEXT ,
        $colNoteTitle TEXT,
        $colNoteBody TEXT,
         $colPhotos TEXT,
         $colVideos TEXT
      )
    ''');
  }

  // CRUD Operations

  /// Insert a new trip, returns inserted row id
  Future<int> insertTrip(Trip trip) async {
    final db = await database;
    return await db.insert(
      tableTrips,
      trip.toMap(),
      // conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

 Future<List<Map<String, dynamic>>> getRouteSummary() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        $colRouteName AS route_name,
        COUNT(*) AS total_trips,
        MAX($colDateTime) AS last_traveled
      FROM $tableTrips
      GROUP BY $colRouteName
      ORDER BY last_traveled DESC
    ''');
    return result;
  }


  /// Retrieve all trips ordered by date_time descending
  Future<List<Trip>> getAllTrips() async {
    final db = await database;
    final maps = await db.query(
      tableTrips,
      orderBy: '$colDateTime DESC',
    );
    return maps.map((m) => Trip.fromMap(m)).toList();
  }

 Future<List<Trip>> getTripsByRoute(String routeName) async {
    final db = await database;
    final maps = await db.query(
      tableTrips,
      where: '$colRouteName = ?',
      whereArgs: [routeName],
      orderBy: '$colDateTime DESC',
    );
    return maps.map((m) => Trip.fromMap(m)).toList();
  }


  /// Retrieve trips filtered by bus number
  Future<List<Trip>> getTripsByBusNumber(String busNumber) async {
    final db = await database;
    final maps = await db.query(
      tableTrips,
      where: '$colBusNumber = ?',
      whereArgs: [busNumber],
      orderBy: '$colDateTime DESC',
    );
    return maps.map((m) => Trip.fromMap(m)).toList();
  }

  /// Update an existing trip record
  Future<int> updateTrip(Trip trip) async {
    final db = await database;
    return await db.update(
      tableTrips,
      trip.toMap(),
      where: '$colId = ?',
      whereArgs: [trip.id],
    );
  }

  /// Delete a trip by id
  Future<int> deleteTrip(int id) async {
    final db = await database;
    return await db.delete(
      tableTrips,
      where: '$colId = ?',
      whereArgs: [id],
    );
  }
  Future<List<Map<String, dynamic>>> previouslyTraveled(String busNumber) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        $colRouteName AS route_name,
        COUNT(*) AS total_travels
      FROM $tableTrips
      WHERE $colBusNumber = ?
      GROUP BY $colRouteName
    ''', [busNumber]);
    return result;
  }
}

