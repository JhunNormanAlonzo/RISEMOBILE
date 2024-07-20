import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class RiseDatabase{

  static final RiseDatabase _instance = RiseDatabase._internal();
  factory RiseDatabase() => _instance;

  RiseDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final path = join(directory.path, 'rise.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    debugPrint("creating table");

    await db.execute('''
      CREATE TABLE IF NOT EXISTS call_statuses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        stats BOOLEAN
      )
    ''');
    debugPrint("inserting to table");
    await db.insert(
      'call_statuses',
      {'name': 'outgoing', 'stats': 1},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.insert(
      'call_statuses',
      {'name': 'incoming', 'stats': 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.insert(
      'call_statuses',
      {'name': 'accepted', 'stats': 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertCallStatus(String name, bool stats) async {

  }

  Future<void> setActive(String name) async{
    final db = await database;
    debugPrint("setting call status to 0");
    await db.update(
      'call_statuses',
      {'stats': 0},
    );
    debugPrint("setting $name to 1");
    await db.update(
      'call_statuses',
      {'stats': 1},
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  Future<void> setAccepted(int status) async{
    final db = await database;
    debugPrint("setting call status to accepted");
    await db.update(
      'call_statuses',
      {'stats': status},
      where: 'name = ?',
      whereArgs: ['accepted'],
    );
  }



  Future<int> getStatus(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'call_statuses',
      columns: ['stats'],
      where: 'name = ?',
      whereArgs: [name],
    );
    return (results.first['stats']);
  }


}

final riseDatabase = RiseDatabase();