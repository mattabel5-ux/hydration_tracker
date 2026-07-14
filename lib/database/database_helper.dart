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
    await db.execute('''
      CREATE TABLE daily_hydration(
        date_id TEXT PRIMARY KEY,
        goal_oz REAL,
        bottle_size REAL,
        first_drink_epoch INTEGER,
        bedtime_epoch INTEGER,
        total_drank_oz REAL,
        refill_count INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_symptoms(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date_id TEXT,
        symptom_name TEXT
      )
    ''');
  }

  // --- Hydration Methods ---

  // Fetches a specific day's data
  Future<DailyHydration?> getHydration(String dateId) async {
    Database db = await instance.database;
    var res = await db.query(
        'daily_hydration',
        where: 'date_id = ?',
        whereArgs: [dateId]
    );

    if (res.isNotEmpty) {
      return DailyHydration.fromMap(res.first);
    }
    return null;
  }

  // Inserts new data, or overwrites it if the date_id already exists
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
        where: 'date_id = ?',
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

  // Removes a symptom if she accidentally checks the wrong box
  Future<int> deleteSymptom(String dateId, String symptomName) async {
    Database db = await instance.database;
    return await db.delete(
      'daily_symptoms',
      where: 'date_id = ? AND symptom_name = ?',
      whereArgs: [dateId, symptomName],
    );
  }
}