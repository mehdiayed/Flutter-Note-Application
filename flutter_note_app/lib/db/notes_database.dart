import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_note_app/model/note.dart';

class NoteDatabase {
  static final NoteDatabase instance = NoteDatabase._init();

  //creating new field from the sqflite package 'Database'
  static Database? _database;

  // private constructor
  NoteDatabase._init();

  // open a Database connection
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('notes.db');
    return _database!;
  }

  //initilize our database
  Future<Database> _initDB(String filePath) async {
    // sotre our database in our storage file system
    // On Android, it is typically data/data//databases
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // _createDB is the scheema
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // create a database table the scheema
  Future _createDB(Database db, int version) async {
    final idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    final textType = 'TEXT NOT NULL';
    final boolType = 'BOOLEAN NOT NULL';
    final integerType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE $tableNotes ( 
        ${NoteFields.id} $idType, 
        ${NoteFields.isImportant} $boolType,
        ${NoteFields.number} $integerType,
        ${NoteFields.title} $textType,
        ${NoteFields.description} $textType,
        ${NoteFields.time} $textType
        )
    ''');
  }

  //  --- Create note

  Future<Note> create(Note note) async {
    final db = await instance.database;

    final id = await db.insert(tableNotes, note.toJson());
    return note.copy(id: id);
  }

  //  --- Read one specific note

  Future<Note> readNote(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      tableNotes,
      columns: NoteFields.values,
      where: '${NoteFields.id} = ?', // this syntax is more secure cuz its
      whereArgs: [id], // its provents SQL injection attacks
    );
    // convert our maps into a note object
    if (maps.isNotEmpty) {
      return Note.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found :( ');
    }
  }

  //  --- Read all notes

  Future<List<Note>> readAllNotes() async {
    final db = await instance.database;

    final orderBy = '${NoteFields.time} ASC';

    final result = await db.query(tableNotes, orderBy: orderBy);
    //db.rawQuery() to creat your oun personnal sql query statement
    return result.map((json) => Note.fromJson(json)).toList();
  }

  //  --- update note

  Future<int> update(Note note) async {
    final db = await instance.database;

    return db.update(
      tableNotes,
      note.toJson(),
      where: '${NoteFields.id} = ?',
      whereArgs: [note.id],
    );
  }

  //  --- delete note

  Future<int> delete(int id) async {
    final db = await instance.database;

    return await db.delete(
      tableNotes,
      where: '${NoteFields.id} = ?',
      whereArgs: [id],
    );
  }

  // close our database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
