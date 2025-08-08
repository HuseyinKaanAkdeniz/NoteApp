import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:noteapplication/Model/Model.dart';
import 'package:noteapplication/Model/ScheduleNotification.dart';
import 'package:noteapplication/Model/notes_db.dart';
import 'package:noteapplication/View/AddEditNotePage.dart';

class NoteDetailPage extends StatefulWidget {
  final int noteid;
  const NoteDetailPage({super.key, required this.noteid});
  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late Note notes;
  bool isloading = false;
  @override
  void initState() {
    super.initState();
    initializeNotifications();
    refreshnotes();
  }

  Future refreshnotes() async {
    setState(() {
      isloading = true;
    });
    notes = await NotesDatabase.instance.readNote(widget.noteid);
    // Check if widget is still mounted before updating state
    if (!mounted) return;
    setState(() {
      isloading = false;
    });
  }

  @override
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
                      notes.title,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          TimeOfDay? selectedTime;
          String repeatType = "once";

          await showDialog(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder:
                    (context, setState) => AlertDialog(
                      title: Text("Bildirim Ayarları"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  selectedTime = picked;
                                });
                              }
                            },
                            child: Text(
                              selectedTime == null
                                  ? "Zaman Seç"
                                  : selectedTime!.format(context),
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Radio<String>(
                                value: "once",
                                groupValue: repeatType,
                                onChanged: (value) {
                                  setState(() {
                                    repeatType = value!;
                                  });
                                },
                              ),
                              Text("Tek Seferlik"),
                              Radio<String>(
                                value: "daily",
                                groupValue: repeatType,
                                onChanged: (value) {
                                  setState(() {
                                    repeatType = value!;
                                  });
                                },
                              ),
                              Text("Her Gün"),
                            ],
                          ),
                        ],
                      ),
                      actions: [
                        // Örnek: Test amaçlı TextButton widget’ı ve hata/success Snackbar yapısı
                                                 TextButton(
                           onPressed: () async {
                             final success = await safeNotificationOperation(() async {
                               await showTestNotification();
                             }, context);
                             
                             if (success && mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                   content: Text(
                                     'Test bildirimi başarıyla gönderildi',
                                   ),
                                 ),
                               );
                             }
                           },
                          child: Text('Test Bildirim Gönder'),
                        ),

                                                 TextButton(
                           onPressed: () async {
                             Navigator.of(context).pop(); // Önce dialogu kapat

                             if (!mounted) return;

                             if (selectedTime != null) {
                               final success = await safeNotificationOperation(() async {
                                 if (repeatType == "daily") {
                                   await scheduleDailyNotification(selectedTime!, notes.title);
                                 } else {
                                   await scheduleOnceNotification(selectedTime!, notes.title);
                                 }
                               }, context);

                               if (success && mounted) {
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(
                                     content: Text(
                                       "Bildirim ayarlandı: Zaman ${selectedTime!.format(context)}, Tip: $repeatType",
                                     ),
                                     backgroundColor: Colors.green,
                                   ),
                                 );
                               }
                             } else {
                               if (!mounted) return;

                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(
                                   content: Text("Lütfen önce zamanı seçiniz!"),
                                   backgroundColor: Colors.orange,
                                 ),
                               );
                             }
                           },
                          child: Text("Onayla"),
                        ),
                      ],
                    ),
              );
            },
          );
        },
        child: Icon(Icons.notification_add_outlined, color: Colors.black),
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Not güncellendi"),
          backgroundColor: Colors.green,
        ),
      );
    },
    icon: Icon(Icons.edit_outlined, color: Colors.white70),
  );

  Widget deletebutton() => IconButton(
    icon: Icon(Icons.delete, color: Colors.white70),
    onPressed: () async {
      await NotesDatabase.instance.delete(widget.noteid);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Not silindi"), backgroundColor: Colors.red),
      );
    },
  );
}
