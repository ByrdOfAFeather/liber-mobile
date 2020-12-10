import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<Database> database;

class PreBookData {
  final String title;
  final String url;
  final String ISBN;
  final int found;

  PreBookData(this.title, this.url, this.ISBN, this.found);

  Map<String, dynamic> toMap() {
    return {"title": title, "url": url, "isbn": ISBN, "found": found};
  }
}

Future<Database> getOrCreateDatabaseFactory() async {
  if (database == null) {
    database = openDatabase(
      join(await getDatabasesPath(), 'prebook_database.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE prebooks(id INTEGER PRIMARY KEY, title TEXT, url TEXT, isbn TEXT, found INTEGER)",
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
      maps[i]["title"],
      maps[i]["url"],
      maps[i]["isbn"],
      maps[i]["found"]
    );
  });
}


