import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:noteapplication/Model/notes_db.dart';
import 'package:noteapplication/Model/Model.dart';
import 'package:noteapplication/View/AddEditNotePage.dart';
import 'package:noteapplication/View/note_detail_page.dart';
import 'package:noteapplication/View/permission_management_page.dart';
import 'package:noteapplication/View/notification_management_page.dart';
import 'package:noteapplication/Widget/note_card_widget.dart';

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

  void dispose() {
    NotesDatabase.instance.close();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Notes",
          style: TextStyle(fontSize: 24, color: Colors.white70),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.admin_panel_settings, color: Colors.white70),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PermissionManagementPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white70),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => NotificationManagementPage(),
                ),
              );
            },
          ),
          SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await refreshnotes();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Notlar yenilendi"),
              backgroundColor: Colors.green,
            ),
          );
        },
        child: Center(
          child: isloading
              ? CircularProgressIndicator()
              : notes.isEmpty
                  ? Text("no notes", style: TextStyle(color: Colors.white))
                  : cardview(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black54,
        child: Icon(Icons.add, color: Colors.white70),
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => AddEditNotePage()));
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
            child: NoteCardWidget(note: note, index: note.id!),
          );
        },
      );
}