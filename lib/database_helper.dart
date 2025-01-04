import 'package:apps_todolist/todo.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper.internal();
  DatabaseHelper.internal();

  factory DatabaseHelper() => _instance;
  static Database? _db;

  Future<Database?> get db async {
    if (_db != null) return _db;

    _db = await initDb();
    return _db;
  }

  Future<Database> initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "todolist.db");
    var localDb = await openDatabase(
      path,
      version: 2, // Tingkatkan versi
      onCreate: _onCreate,
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          // Lakukan migrasi: Ubah nama kolom 'description' menjadi 'deskripsi'
          await db.execute(
              "ALTER TABLE todos RENAME COLUMN description TO deskripsi");
        }
      },
    );
    return localDb;
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE if not exists todos(
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        nama TEXT NOT NULL, 
        deskripsi TEXT NOT NULL, 
        done INTEGER NOT NULL DEFAULT 0
        )
        ''');
  }

  Future<List<Todo>> getAllTodos() async {
    var dbClient = await db;
    var todos = await dbClient!.query('todos');
    return todos.map((todo) => Todo.fromMap(todo)).toList();
  }

  Future<List<Todo>> searchTodo(String keyword) async {
    var dbClient = await db;
    var todos = await dbClient!
        .query('todos', where: 'nama like ?', whereArgs: ['%$keyword%']);
    return todos.map((todo) => Todo.fromMap(todo)).toList();
  }

  Future<int> addTodo(Todo todo) async {
    var dbClient = await db;
    return await dbClient!.insert('todos', todo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateTodo(Todo todo) async {
    var dbClient = await db;
    return await dbClient!
        .update('todos', todo.toMap(), where: "id = ?", whereArgs: [todo.id]);
  }

  Future<int> deleteTodo(int id) async {
    var dbClient = await db;
    return await dbClient!.delete('todos', where: "id = ?", whereArgs: [id]);
  }
}
