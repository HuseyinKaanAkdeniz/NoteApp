import 'package:flutter/material.dart';
import 'package:noteapplication/Model/Model.dart';
import 'package:noteapplication/Model/notes_db.dart';
import 'package:noteapplication/Model/ScheduleNotification.dart';
import '../widget/note_form_widget.dart';

class AddEditNotePage extends StatefulWidget {
  final Note? note;

  const AddEditNotePage({Key? key, this.note}) : super(key: key);

  @override
  State<AddEditNotePage> createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage> {
  final _formKey = GlobalKey<FormState>();
  late bool isImportant;
  late int number;
  late String title;
  late String description;
  DateTime? _reminderDateTime;

  @override
  void initState() {
    super.initState();

    isImportant = widget.note?.isImportant ?? false;
    number = widget.note?.number ?? 0;
    title = widget.note?.title ?? '';
    description = widget.note?.description ?? '';
    initializeNotifications(); // Initialize notifications when page loads
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      actions: [
        IconButton(
          icon: Icon(
            _reminderDateTime != null 
              ? Icons.notifications_active 
              : Icons.notifications_none,
            color: _reminderDateTime != null ? Colors.amber : null,
          ),
          onPressed: _pickReminderDate,
        ),
        buildButton(),
      ],
    ),
    body: Form(
      key: _formKey,
      child: Column(
        children: [
          if (_reminderDateTime != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                   const Icon(Icons.alarm, size: 16, color: Colors.amber),
                   const SizedBox(width: 8),
                   Text(
                     'Reminder: ${_reminderDateTime.toString().split('.')[0]}',
                     style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                   ),
                   const Spacer(),
                   IconButton(
                     icon: const Icon(Icons.close, size: 16),
                     onPressed: () => setState(() => _reminderDateTime = null),
                   )
                ],
              ),
            ),
          Expanded(
            child: NoteFormWidget(
              isImportant: isImportant,
              number: number,
              title: title,
              description: description,
              onChangedImportant:
                  (isImportant) => setState(() => this.isImportant = isImportant),
              onChangedNumber: (number) => setState(() => this.number = number),
              onChangedTitle: (title) => setState(() => this.title = title),
              onChangedDescription:
                  (description) => setState(() => this.description = description),
            ),
          ),
        ],
      ),
    ),
  );

  Widget buildButton() {
    final isFormValid = title.isNotEmpty && description.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: isFormValid ? null : Colors.grey.shade700,
        ),
        onPressed: addOrUpdateNote,
        child: const Text('Save'),
      ),
    );
  }

  Future<void> _pickReminderDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderDateTime ?? now,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderDateTime ?? now),
    );

    if (time == null) return;

    setState(() {
      _reminderDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });

    // Check/Request permission immediately when user tries to set a reminder
    await ensureNotificationPermission(context);
  }

  void addOrUpdateNote() async {
    final isValid = _formKey.currentState!.validate();

    if (isValid) {
      final isUpdating = widget.note != null;
      
      if (_reminderDateTime != null) {
        // Schedule the notification
        await scheduleSpecificDateNotification(
          _reminderDateTime!,
          title,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hatırlatıcı ${_reminderDateTime.toString().split('.')[0]} için ayarlandı')),
          );
        }
      }

      if (isUpdating) {
        await updateNote();
      } else {
        await addNote();
      }

      Navigator.of(context).pop();
    }
  }

  Future updateNote() async {
    final note = widget.note!.copy(
      isImportant: isImportant,
      number: number,
      title: title,
      description: description,
    );

    await NotesDatabase.instance.update(note);
  }

  Future addNote() async {
    final note = Note(
      title: title,
      isImportant: true,
      number: number,
      description: description,
      createdTime: DateTime.now(),
    );

    await NotesDatabase.instance.create(note);
  }
}
