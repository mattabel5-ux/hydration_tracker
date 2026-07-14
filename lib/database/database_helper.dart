import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/daily_hydration.dart';
import '../models/daily_symptom.dart';

class DatabaseHelper {
  // Singleton pattern to ensure only one instance of the database exists
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Finds the correct local storage folder for both iOS and Android
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = "${documentsDirectory.path}/hydration_tracker.db";

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Creates the tables when the app is installed for the first time
  Future _onCreate(Database db, int version) async {
    // Standardized to match the exact keys in DailyHydration.toMap()
    await db.execute('''
      CREATE TABLE daily_hydration(
        dateId TEXT PRIMARY KEY,
        goalOz REAL,
        bottleSize REAL,
        firstDrinkEpoch INTEGER,
        bedtimeEpoch INTEGER,
        totalDrankOz REAL,
        refillCount INTEGER,
        electrolytePills INTEGER
      )
    ''');

    // Updated to include the new timestamp tracking
    await db.execute('''
      CREATE TABLE daily_symptoms(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dateId TEXT NOT NULL,
        symptomName TEXT NOT NULL,
        timestampEpoch INTEGER NOT NULL
      )
    ''');
  }

  // --- Hydration Methods ---

  // Fetches a specific day's data
  Future<DailyHydration?> getHydration(String dateId) async {
    Database db = await instance.database;
    var res = await db.query(
        'daily_hydration',
        where: 'dateId = ?',
        whereArgs: [dateId]
    );

    if (res.isNotEmpty) {
      return DailyHydration.fromMap(res.first);
    }
    return null;
  }

  // Inserts new data, or overwrites it if the dateId already exists
  Future<int> insertOrUpdateHydration(DailyHydration hydration) async {
    Database db = await instance.database;
    return await db.insert(
      'daily_hydration',
      hydration.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Symptom Methods ---

  // Fetches all symptoms logged on a specific day
  Future<List<DailySymptom>> getSymptoms(String dateId) async {
    Database db = await instance.database;
    var res = await db.query(
        'daily_symptoms',
        where: 'dateId = ?',
        whereArgs: [dateId]
    );

    return res.isNotEmpty
        ? res.map((c) => DailySymptom.fromMap(c)).toList()
        : [];
  }

  // Logs a new symptom
  Future<int> insertSymptom(DailySymptom symptom) async {
    Database db = await instance.database;
    return await db.insert('daily_symptoms', symptom.toMap());
  }

  // --- NEW HISTORY METHODS ---

  // Fetches all hydration records, sorted by date (newest first)
  Future<List<DailyHydration>> getAllHydration() async {
    final db = await instance.database;
    final result = await db.query(
      'daily_hydration',
      orderBy: 'dateId DESC',
    );
    return result.map((json) => DailyHydration.fromMap(json)).toList();
  }

  // Fetches all symptom records
  Future<List<DailySymptom>> getAllSymptoms() async {
    final db = await instance.database;
    final result = await db.query('daily_symptoms');
    return result.map((json) => DailySymptom.fromMap(json)).toList();
  }
}