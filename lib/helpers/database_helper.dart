import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user.dart';
import '../models/location_note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('remember_locations.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE location_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        imagePath TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');
  }

  // User operations
  Future<int> createUser(User user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUser(int id) async {
    final db = await instance.database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByCredentials(String name, String password) async {
    final db = await instance.database;
    final maps = await db.query('users',
        where: 'name = ? AND password = ?', whereArgs: [name, password]);

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Location note operations
  Future<int> createLocationNote(LocationNote note) async {
    final db = await instance.database;
    return await db.insert('location_notes', note.toMap());
  }

  Future<int> updateLocationNote(LocationNote note) async {
    final db = await instance.database;
    return await db.update(
      'location_notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteLocationNote(int id) async {
    final db = await instance.database;
    return await db.delete(
      'location_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<LocationNote>> getLocationNotes(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'location_notes',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    return result.map((json) => LocationNote.fromMap(json)).toList();
  }

  Future<LocationNote?> getLocationNote(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'location_notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return LocationNote.fromMap(maps.first);
    }
    return null;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
