import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const QuickNoteApp());
}

class QuickNoteApp extends StatelessWidget {
  const QuickNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Hier speichern wir alle erstellten Notizen.
  final List<Note> _notes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quick Notes',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: () async {
              // Wir zeigen in einer Snackbar an, dass etwas passiert.
              // Es ist wichtig, dem Nutzer nach einem Klick auf einen Button
              // zu zeigen, dass seine Aktion wirklich etwas ausgelöst hat.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Uploading your notes...'),
                  backgroundColor: Colors.green,
                ),
              );

              // Hier wandeln wir die Notizenliste von oben um in eine Liste an Maps.
              final notesList = _notes.map((note) => note.toMap()).toList();

              // Die Liste an Maps können wir jetzt in korrektes JSON umwandeln.
              final content = jsonEncode(notesList);
              // content ist jetzt der Inhalt einer JSON Datei.

              // Jetzt stellen wir eine Anfrage an den Server, damit er unsere
              // JSON Datei auf dem Server überschreibt mit dem neuen Inhalt
              // in der Variable content.
              // Dazu müssen wir auch noch einige Formalitäten, wie die richtigen
              // Header, einbauen.
              await http.put(
                Uri.parse(
                    'https://api.jsonbin.io/v3/b/HIER KOMMT DIE ID VON DEINEM BIN'),
                headers: {
                  'X-Access-Key': r'HIER DEINEN ACCESS KEY EINTRAGEN',
                  'Content-Type': 'application/json',
                },
                body: content,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              // Wir zeigen in einer Snackbar an, dass etwas passiert.
              // Es ist wichtig, dem Nutzer nach einem Klick auf einen Button
              // zu zeigen, dass seine Aktion wirklich etwas ausgelöst hat.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Downloading your notes...'),
                  backgroundColor: Colors.green,
                ),
              );

              // Wir fragen beim Server an, damit er uns die JSON Datei schickt.
              final response = await http.get(
                  Uri.parse(
                      'https://api.jsonbin.io/v3/b/HIER KOMMT DIE ID VON DEINEM BIN/latest'),
                  headers: {
                    'X-Access-Key': r'HIER DEINEN ACCESS KEY EINTRAGEN'
                  });

              // Wir können jetzt die Antowort vom Server (auch wieder JSON) in
              // eine Dart Map umwandeln. Damit haben wir Zugriff auf all die
              // Felder und können sie auslesen.
              final responseMap = jsonDecode(response.body);

              // Mit print(responseMap) sieht man, dass unsere Notizenliste
              // über den Schlüssel mit dem Namen 'records' erreichbar ist.
              // Deswegen holen wir uns jetzt diese Liste.
              final noteMapsList = responseMap['records'];
              // Die Liste besteht allerdings (und logischerweise) wieder nur aus Maps.

              // Im nächsten Schritt wandeln wir jede der einzelnen Notiz-Maps
              // um in eine richtige Notiz. Die speichern wir dann immer gleich
              // ab in der Liste _notes und aktualisieren die UI.
              for (var noteMap in noteMapsList) {
                final newNote = Note.fromMap(noteMap);
                setState(() {
                  _notes.add(newNote);
                });
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteScreen(
                    callback: (updatedNote) {
                      setState(() {
                        _notes[index] = updatedNote;
                      });
                    },
                    note: _notes[index],
                  ),
                ),
              );
            },
            child: NoteWidget(
              note: _notes[index],
            ),
          );
        },
      ),
    );
  }
}

// Die Darstellung einer einzelnen Notiz.
class NoteWidget extends StatelessWidget {
  final Note note;

  const NoteWidget({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title),
      subtitle: Text(note.text),
    );
  }
}

// Eine Datenklasse, die eine Notiz repräsentiert.
class Note {
  String title;
  String text;

  Note({required this.title, required this.text});

  // Dieser factory-Konstruktor erstellt uns aus einer Map
  // ein wirkliches Notizobjekt.
  factory Note.fromMap(Map<String, dynamic> json) {
    return Note(
      title: json['title'],
      text: json['text'],
    );
  }

  // Diese Methode erzeugt aus dem Objekt eine Map.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'text': text,
    };
  }
}

class NoteScreen extends StatefulWidget {
  final Note note;
  final void Function(Note) callback;

  const NoteScreen({super.key, required this.note, required this.callback});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _titleController.text = widget.note.title;
    _textController.text = widget.note.text;
  }

  @override
  void dispose() {
    super.dispose();

    _titleController.dispose();
    _textController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
            widget.callback(
              Note(
                title: _titleController.text,
                text: _textController.text,
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: "Title"),
          ),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(labelText: "Text"),
          ),
        ],
      ),
    );
  }
}
