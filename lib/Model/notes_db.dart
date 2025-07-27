import 'dart:convert';
import 'package:noteapplication/Model/Model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class NotesDatabase{
  static final NotesDatabase instance = NotesDatabase.init();
  static Database? _database;
  NotesDatabase.init();

  Future<Database>get database async{
    _database ??= await _initDb("notes.db");
    return _database!;}
  
  Future<Database>_initDb(String Filepath)async{
    final dbpath =await getDatabasesPath();
    final path = join(dbpath,Filepath);
    return await openDatabase(path,version: 1,onCreate: _createdb);
  }

  Future _createdb (Database db ,int version )async{
    final idType="İNT PRİMARY KEY AUTOİNCREMENT ";
    final booltype="BOOL NOT NULL";
    final integerType="integer NOT NULL";
    final texttype="text NOT NULL";
   await db.execute('''
      CREATE TABLE $tablenotes (
        ${NoteFiels.id}$idType,
        ${NoteFiels.isImportant}$booltype,
        ${NoteFiels.number}$integerType
        ${NoteFiels.title}$texttype
        ${NoteFiels.description}$texttype
        ${NoteFiels.time}$texttype
      )
    ''');}
  
  Future <Note>create(Note note )async{
    final db=await instance.database;

   /* final json =note.toJson();
    final columns = '${NoteFiels.title},${NoteFiels.description},${NoteFiels.time}';
    final values = '${json[NoteFiels.title]},${json[NoteFiels.description]},${json[NoteFiels.time]}';
    final id =await db.rawInsert("INSERT İNTO table_name($columns)values($values)");*/
    
    //Same expression as above 
    final id =await db.insert(tablenotes,note.toJson());

    return note.copy(id:id);
  }
   
   Future<Note>readNote(int id )async{
    final db=await instance.database;

    final maps=await db.query(
      tablenotes,
      columns: NoteFiels.values,
      /* not secure
      where: '${NoteFiels.id}= $id'
      */
      //more secured sql injection attacks
      where: '${NoteFiels.id}= ?',
      whereArgs:[id,],
    );
      if (maps.isNotEmpty)
      {
        return Note.fromJson(maps.first);
      }else {
        throw Exception("id$id not found");
      }
   }

   Future<List<Note>> readallnotes()async{
    final db=await instance.database;
    final orderby ='${NoteFiels.time}ASC';
    // final result = db.rawInsert("INSERT İNTO table_name($columns)values($values)");
    //doing same things
    final result = await db.query(tablenotes,orderBy: orderby);

    return result.map((json) =>Note.fromJson(json)).toList();
   }
  
Future <int>update(Note note) async{
  final db=await instance.database;
  return db.update(
    tablenotes,
    note.toJson(),
     where: '${NoteFiels.id}= ?',
     whereArgs:[note.id],
  );
}

Future<int>delete (int id )async{
  final db=await instance.database;
  return db.delete(
     where: '${NoteFiels.id}= ?',
     whereArgs:[id],
    tablenotes
  );
}

  Future close()async{
    final db=await instance.database;
    await db.close;
  }
  
}