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
      version: 2, // INCREMENTED TO VERSION 2
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // ADDED UPGRADE PATH
    );
  }

  // Creates the tables when the app is installed for the very first time
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE daily_hydration(
        dateId TEXT PRIMARY KEY,
        goalOz REAL,
        bottleSize REAL,
        firstDrinkEpoch INTEGER,
        bedtimeEpoch INTEGER,
        totalDrankOz REAL,
        refillCount INTEGER,
        electrolytePills INTEGER,
        notificationIntervalMinutes INTEGER,
        notificationType TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_symptoms(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dateId TEXT NOT NULL,
        symptomName TEXT NOT NULL,
        timestampEpoch INTEGER NOT NULL
      )
    ''');
  }

  // Safely updates the database for existing users (like your daughter)
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add the new notification columns without destroying existing data
      await db.execute("ALTER TABLE daily_hydration ADD COLUMN notificationIntervalMinutes INTEGER DEFAULT 60");
      await db.execute("ALTER TABLE daily_hydration ADD COLUMN notificationType TEXT DEFAULT 'standard'");
    }
  }

  // --- Hydration Methods ---

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

  Future<int> insertOrUpdateHydration(DailyHydration hydration) async {
    Database db = await instance.database;
    return await db.insert(
      'daily_hydration',
      hydration.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Symptom Methods ---

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

  Future<int> insertSymptom(DailySymptom symptom) async {
    Database db = await instance.database;
    return await db.insert('daily_symptoms', symptom.toMap());
  }

  // --- NEW HISTORY METHODS ---

  Future<List<DailyHydration>> getAllHydration() async {
    final db = await instance.database;
    final result = await db.query(
      'daily_hydration',
      orderBy: 'dateId DESC',
    );
    return result.map((json) => DailyHydration.fromMap(json)).toList();
  }

  Future<List<DailySymptom>> getAllSymptoms() async {
    final db = await instance.database;
    final result = await db.query('daily_symptoms');
    return result.map((json) => DailySymptom.fromMap(json)).toList();
  }
}