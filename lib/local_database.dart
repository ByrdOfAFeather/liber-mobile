import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<Database> database;

class PreBookData {
  final String name;
  final String url;
  final String ISBN;
  final String olID;
  final int found;
  final int id;

  PreBookData(this.name, this.url, this.ISBN, this.olID, this.found, {this.id});

  Map<String, dynamic> toMap() {
    return {"name": name, "url": url, "isbn": ISBN, "olID": olID, "found": found};
  }
}

Future<Database> getOrCreateDatabaseFactory() async {
  if (database == null) {
    database = openDatabase(
      join(await getDatabasesPath(), 'prebook_database.db'),
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE prebooks(id INTEGER PRIMARY KEY, name TEXT, url TEXT, isbn TEXT, olID TEXT, found INTEGER)",
        );
      },
      version: 1,
    );
  }
  return database;
}

Future<void> insertPreBook(PreBookData data) async {
  final Database db = await getOrCreateDatabaseFactory();
  await db.insert(
    'prebooks',
    data.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

// A method that retrieves all the dogs from the dogs table.
Future<List<PreBookData>> getPreBooks() async {
  final Database db = await getOrCreateDatabaseFactory();
  final List<Map<String, dynamic>> maps = await db.query('prebooks');

  return List.generate(maps.length, (i) {
    return PreBookData(
        maps[i]["name"], maps[i]["url"], maps[i]["isbn"], maps[i]["olID"], maps[i]["found"], id: maps[i]["id"]);
  });
}

Future<void> deletePreBook(int id) async {
  final Database db = await getOrCreateDatabaseFactory();

  await db.delete(
    'prebooks',
    where: "id = ?",
    whereArgs: [id],
  );
}
