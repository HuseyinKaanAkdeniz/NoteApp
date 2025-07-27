import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:noteapplication/Model/notes_db.dart';
import 'package:noteapplication/Model/Model.dart';
import 'package:noteapplication/View/note_detail_page.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late List<Note> notes;
  bool isloading = false;
  @override
  void initState() {
    super.initState();
    refreshnotes();
  }

  Future refreshnotes() async {
    setState(() {
      isloading = true;
    });
    this.notes = await NotesDatabase.instance.readallnotes();
    setState(() {
      isloading = false;
    });
  }

  void dispose() {
    NotesDatabase.instance.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Notes",style: TextStyle(fontSize: 24,fontWeight: FontWeight.w500),)),
    body: Center(
      child: isloading ? CircularProgressIndicator()
      :notes.isEmpty
      ?Text("no notes",style: TextStyle(color: Colors.white)):cardview()
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: Icon(Icons.add),
        onPressed: ()async {
          // await navigator.of(context).push(MaterialPageRoute(builder:(context)=>))
          refreshnotes();
        },
      ),
    );
  }

  Widget cardview() => AlignedGridView.count(
    crossAxisCount: 3,
    mainAxisSpacing: 3,
    crossAxisSpacing: 3,
    itemCount: notes.length,
    itemBuilder: (context, index) {
      final note = notes[index];

      return GestureDetector(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NoteDetailPage(noteid: note.id!),
            ),
          );
          refreshnotes();
        },
        child: Notecardview(note: note), // NoteCard senin liste elemanı widget'ın olmalı
      );
    },
  );


  
}
