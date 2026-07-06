import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import '../models/note_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ecosave_notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // Version 3 pour inclure la Corbeille et les Catégories
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'Général',
        isArchived INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE notes ADD COLUMN userId INTEGER NOT NULL DEFAULT 1');
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE notes ADD COLUMN category TEXT NOT NULL DEFAULT 'Général'");
      await db.execute('ALTER TABLE notes ADD COLUMN isArchived INTEGER NOT NULL DEFAULT 0');
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ==================== FONCTIONNALITÉ INNOVANTE : ÉCO-IMPACT COMPATIBLE WEB ====================
  // Calcule la taille de la BDD et le CO2 économisé via des requêtes SQL SQLite pures
  Future<Map<String, double>> getEcoImpactMetrics() async {
    double fileSizeKB = 0;
    
    try {
      final db = await instance.database;
      // Récupère le nombre total de pages utilisées par la BDD et la taille d'une page
      final List<Map<String, dynamic>> pageCountResult = await db.rawQuery('PRAGMA page_count');
      final List<Map<String, dynamic>> pageSizeResult = await db.rawQuery('PRAGMA page_size');
      
      if (pageCountResult.isNotEmpty && pageSizeResult.isNotEmpty) {
        int pageCount = pageCountResult.first.values.first as int;
        int pageSize = pageSizeResult.first.values.first as int;
        
        // Calcul du poids total en Ko
        fileSizeKB = (pageCount * pageSize) / 1024;
      }
    } catch (e) {
      fileSizeKB = 0.0;
    }

    // Estimation théorique : Éviter le Cloud économise environ 0.02 mg de CO2 par Ko
    double co2SavedMg = fileSizeKB * 0.02;

    return {
      'size': fileSizeKB,
      'co2': co2SavedMg,
    };
  }

  // ==================== AUTHENTIFICATION ====================

  Future<int> registerUser(UserModel user) async {
    final db = await instance.database;
    try {
      final securedUser = UserModel(
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        username: user.username,
        password: _hashPassword(user.password),
      );
      return await db.insert('users', securedUser.toMap());
    } catch (e) {
      return -1;
    }
  }

  Future<UserModel?> loginUser(String username, String password) async {
    final db = await instance.database;
    final hashedPassword = _hashPassword(password);

    final maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, hashedPassword],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> updateUser(UserModel user) async {
    final db = await instance.database;
    try {
      final updatedPassword = user.password.length < 60 ? _hashPassword(user.password) : user.password;
      final securedUser = UserModel(
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        username: user.username,
        password: updatedPassword,
      );

      return await db.update(
        'users',
        securedUser.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
    } catch (e) {
      return -1;
    }
  }

  // ==================== GESTION DES NOTES ====================

  Future<int> createNote(NoteModel note, int userId) async {
    final db = await instance.database;
    final noteMap = note.toMap();
    noteMap['userId'] = userId;
    return await db.insert('notes', noteMap);
  }

  Future<List<NoteModel>> readUserNotes(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      where: 'userId = ? AND isArchived = 0',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return result.map((json) => NoteModel.fromMap(json)).toList();
  }

  Future<List<NoteModel>> readTrashNotes(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      where: 'userId = ? AND isArchived = 1',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return result.map((json) => NoteModel.fromMap(json)).toList();
  }

  Future<int> updateNote(NoteModel note) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> moveToTrash(int id) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      {'isArchived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> restoreFromTrash(int id) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      {'isArchived': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteNotePermanent(int id) async {
    final db = await instance.database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}