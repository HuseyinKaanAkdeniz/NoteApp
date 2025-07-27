final String tablenotes="notes";

class NoteFiels{
  static final List<String>values =[
    id,isImportant,number,title,description,time
  ];

  static final String id="_id";
  static final String isImportant="_isImportant";
  static final String number="_number";
  static final String title="_title";
  static final String description="_description";
  static final String time="_time";
}

class Note {
  final int? id;
  final bool isImportant;
  final int? number;
  final String title;
  final String description;
  final DateTime createdTime;

Note copy({
  int? id,
  bool? isImportant,
  int? number,
  String? title,
  String? description,
  DateTime? createdTime,
})
=>Note
(
  id: id?? this.id,
  isImportant: isImportant ??this.isImportant,
  number: number ??this.number,
  title: title ?? this.title,
  description: description?? this.description,
  createdTime: createdTime??this.createdTime,
  );

static Note fromJson(Map<String,Object?>json)=>Note
(
  id:json[NoteFiels.id]as int?,
  isImportant: json[NoteFiels.isImportant] == 1,
  number: json[NoteFiels.number]as int?,
  title: json[NoteFiels.title]as String,
  description: json[NoteFiels.description]as String,
  createdTime:DateTime.parse(json[NoteFiels.time]as String),

  );

  Note({
    this.id, 
    required this.isImportant,
    this.number, 
    required this.title,
    required this.description,
    required this.createdTime,
  });

  Map<String,Object?>toJson()=>{
    NoteFiels.id:id,
    NoteFiels.title:title,
    NoteFiels.isImportant:isImportant?1:0,
    NoteFiels.number:number,
    NoteFiels.description:description,
    NoteFiels.time:createdTime.toIso8601String(),
  };
}
