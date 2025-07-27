import 'package:flutter/material.dart';
import 'package:noteapplication/Model/Model.dart';
import 'package:noteapplication/Model/notes_db.dart';

class AddEditNotePage extends StatefulWidget {
  final Note? note;
  const AddEditNotePage({Key? key ,this.note,}):super(key: key);

  @override
  State<AddEditNotePage> createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage> {
  final _formkey=GlobalKey<FormState>();
  late bool isImportant;
  late int number;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }

  void AddorUpdateNote()async{
    final isvalid=_formkey.currentState!.validate();
    if (isvalid){
      final isUpdating=widget.note!=null;
    }
    if(isUpdating){
      await updatenote();
    }else{
      await addnote();
    }
    Navigator.of(context).pop();
  }

  Future updatenote()async{
    final note= widget.note!.copy(
      isImportant: isImportant,
      number: number,
      title: title,
      description: desciption,
    );
    await NotesDatabase.instance.update(note);
  }

  Future addnote()async{
    final note= Note(
      isImportant: isImportant,
      number: number,
      title: title,
      description: desciption,
      createdTime: DateTime.now()
    );
    await NotesDatabase.instance.create(note);
  }
}