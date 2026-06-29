import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _db;

  factory AppDatabase() => _instance;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'hotel_database.db');

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {

    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY
      )
    ''');

    await db.execute('''
      CREATE TABLE funcionarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL,
        nome TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        telefone TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE quartos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numero INTEGER NOT NULL UNIQUE,
        tipo TEXT NOT NULL,
        status TEXT NOT NULL,
        diaria REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE hospedes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        telefone TEXT NOT NULL,
        cpf TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE reservas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        checkIn TEXT NOT NULL,
        checkOut TEXT NOT NULL,
        valorTotal REAL NOT NULL,
        status TEXT NOT NULL,
        usuario_id INTEGER NOT NULL,
        quarto_id INTEGER NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id),
        FOREIGN KEY (quarto_id) REFERENCES quartos (id)
      )
    ''');

    // Tabela Associativa (Hóspedes da Reserva)
    await db.execute('''
      CREATE TABLE reserva_hospede (
        reserva_id INTEGER NOT NULL,
        hospede_id INTEGER NOT NULL,
        PRIMARY KEY (reserva_id, hospede_id),
        FOREIGN KEY (reserva_id) REFERENCES reservas (id) ON DELETE CASCADE,
        FOREIGN KEY (hospede_id) REFERENCES hospedes (id) ON DELETE RESTRICT 
      )
    ''');

    print('Banco de dados SQLite inicializado localmente em sincronia com a API.');
  }
}