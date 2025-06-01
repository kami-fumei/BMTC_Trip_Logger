// import 'dart:developer';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trip_logger/search_page.dart';
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

  final String tableSearchHistory = 'search_history';
  final String colHistoryId = 'id';
  final String colHistoryQuery = 'query';
  final String colHistoryTimestamp = 'timestamp';

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
      version: 3,
      onCreate: _onCreate,
      // onUpgrade: _onUpgrade,
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
        await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSearchHistory (
        $colHistoryId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colHistoryQuery TEXT NOT NULL,
        $colHistoryTimestamp INTEGER NOT NULL
      )
    ''');
  }

//   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {

  
//     // Create search_history table if it doesn't exist
    // await db.execute('''
    //   CREATE TABLE IF NOT EXISTS $tableSearchHistory (
    //     $colHistoryId INTEGER PRIMARY KEY AUTOINCREMENT,
    //     $colHistoryQuery TEXT NOT NULL,
    //     $colHistoryTimestamp INTEGER NOT NULL
    //   )
    // ''');
  
// }

  // CRUD Operations

  /// Insert a new trip, returns inserted row id
  Future<int> insertTrip(Trip trip) async {
    final db = await database;
    return await db.insert(
      tableTrips,
      trip.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
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
/// Returns a map of unique values for each SearchField, filtered by the query.
/// Example: {route: [23, 234M], busNumber: [KA01AB1234], date: [2024-06-01], busStop: [Majestic, Market]}
Future getFilteredSearchFieldValues(
  {
    String? query,
    SearchField? field,
    DateTime? date,
  }
) async {
  final db = await database;
  String q = '%${query!.toLowerCase()}%';
 var routes;
var busNumbers;
var dates;
var stops;

if(field==SearchField.route||field==SearchField.all){
 routes = await db.rawQuery(
    'SELECT DISTINCT $colRouteName FROM $tableTrips WHERE LOWER($colRouteName) LIKE ?',
    [q]
    );
    }

  // Filtered bus numbers
  if(field==SearchField.busNumber||field==SearchField.all){
      busNumbers = await db.rawQuery(
    'SELECT DISTINCT $colBusNumber FROM $tableTrips WHERE LOWER($colBusNumber) LIKE ?',
    [q],
  );
}
  // Filtered dates (only date part)
if(field==SearchField.date)
{   dates = await db.rawQuery(
    'SELECT DISTINCT date($colDateTime) as date_only FROM $tableTrips WHERE $colDateTime LIKE ?',
    [q],
  );}

  // Filtered bus stops (source and destination merged)
  if(field==SearchField.busStop||field==SearchField.all)
 {  
  stops = await db.rawQuery(
    '''
    SELECT DISTINCT $colSource as stop FROM $tableTrips  WHERE LOWER($colSource) LIKE ?
    UNION
    SELECT DISTINCT $colDestination as stop FROM $tableTrips WHERE LOWER($colDestination) LIKE ?
    ''',
    [q, q],
  );
  }

  return {

  'route': routes != null? routes.map((route)=>(route['$colRouteName'])):[],
    'busNumber':busNumbers != null ?  busNumbers.map((busNumbers)=>(busNumbers['$colBusNumber'])):[],
    'date':dates != null ? dates.map((date)=>(date['$colDateTime'])):[] ,
    'busStop':stops != null ? stops.map((route)=>(route['stop'])):[]
  };


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
      // columns: [colBusNumber, colDateTime,colId],
      where: '$colRouteName = ?',
      whereArgs: [routeName],
      orderBy: '$colDateTime DESC',
    );
    return maps.map((m) => Trip.fromMap(m)).toList();
  }


  /// Retrieve trips filtered by bus number
  Future<List<Trip>> getTripsById(int id) async {
    final db = await database;
    final maps = await db.query(
      tableTrips,
      where: '$colId = ?',
      whereArgs: [id],
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

  /// Search trips by query and filter
  Future <List<Trip>> searchBusData({
    String? query,
    SearchField? field,
    DateTime? date,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (field == SearchField.date && date != null) {
      // Search by date only (ignoring time)
      String dateStr = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      where = "date($colDateTime) = ?";
      whereArgs = [dateStr];
    } else if (query != null && query.isNotEmpty) {
      String q = '%${query.toLowerCase()}%';
      switch (field) {
        case SearchField.route:
          where = "LOWER($colRouteName) LIKE ?";
          whereArgs = [q];
          break;
        case SearchField.busNumber:
          where = "LOWER($colBusNumber) LIKE ?";
          whereArgs = [q];
          break;
        case SearchField.busStop:
          // Search in both source and destination
          where = "(LOWER($colSource) LIKE ? OR LOWER($colDestination) LIKE ?)";
          whereArgs = [q, q];
          break;
        case SearchField.all:
        default:
          where = "LOWER($colRouteName) LIKE ? OR LOWER($colBusNumber) LIKE ? OR LOWER($colSource) LIKE ? OR LOWER($colDestination) LIKE ?";
          whereArgs = [q, q, q, q];
          break;
      }
    }

    final result = await db.query(
      tableTrips,
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: '$colDateTime DESC',
    );
    return result.map((m)=>Trip.fromMap(m)).toList();
  }

  Future<void> addSearchHistory(String query) async {
    final db = await database;
    // Remove duplicate
    await db.delete(tableSearchHistory, where: '$colHistoryQuery = ?', whereArgs: [query]);
    await db.insert(tableSearchHistory, {
      colHistoryQuery: query,
      colHistoryTimestamp: DateTime.now().millisecondsSinceEpoch,
    });
    // Keep only latest 10
    await db.rawDelete('''
      DELETE FROM $tableSearchHistory WHERE $colHistoryId NOT IN (
        SELECT $colHistoryId FROM $tableSearchHistory ORDER BY $colHistoryTimestamp DESC LIMIT 10
      )
    ''');
  }

  Future<List<String>> getSearchHistory() async {
    final db = await database;
    final result = await db.query(
      tableSearchHistory,
      orderBy: '$colHistoryTimestamp DESC',
      limit: 10
    );
    return result.map((row) => row[colHistoryQuery] as String).toList();
  }

  Future<void> deleteSearchHistory(String query) async {
    final db = await database;
    await db.delete(tableSearchHistory, where: '$colHistoryQuery = ?', whereArgs: [query]);
  }

  Future<void> clearSearchHistory() async {
    final db = await database;
    await db.delete(tableSearchHistory);
  }

//   Future<void> ensureSearchHistoryTable() async {
//   final db = await database;
//   await db.execute('''
//     CREATE TABLE IF NOT EXISTS $tableSearchHistory (
//       $colHistoryId INTEGER PRIMARY KEY AUTOINCREMENT,
//       $colHistoryQuery TEXT NOT NULL,
//       $colHistoryTimestamp INTEGER NOT NULL
//     )
//   ''');
// }
}

