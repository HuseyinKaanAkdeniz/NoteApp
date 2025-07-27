import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:noteapplication/Model/Model.dart';
import 'package:noteapplication/Model/notes_db.dart';
import 'package:noteapplication/View/AddEditNotePage.dart';
import 'package:noteapplication/View/notes_page.dart';

class NoteDetailPage extends StatefulWidget {
  final int noteid;
  const NoteDetailPage({Key? key, required this.noteid}) : super(key: key);

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late Note notes;
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
    this.notes = await NotesDatabase.instance.readNote(widget.noteid);
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
    return Scaffold(
      appBar: AppBar(actions: [editingbutton(), deletebutton()]),
      body:
          isloading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: EdgeInsets.all(12),
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  children: [
                    Text(
                      Note as String,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      DateFormat.yMMMd().format(notes.createdTime),
                      style: TextStyle(color: Colors.white38),
                    ),
                    SizedBox(height: 8),
                    Text(
                      notes.description,
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget editingbutton() => IconButton(
    onPressed: () async {
      if (isloading) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => AddEditNotePage(note: notes)),
      );
      refreshnotes();
    },
    icon: Icon(Icons.edit_outlined),
  );

  Widget deletebutton() => IconButton(
    icon: Icon(Icons.remove),
    onPressed: () async {
      await NotesDatabase.instance.delete(widget.noteid);
      Navigator.of(context).pop();
    },
  );
}
