import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UI Notes App',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF2F5F9),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const HomeScreen(),
    );
  }
}

class Note {
  String id;
  String title;
  String content;
  String category;
  DateTime date;
  List<String> checklist;
  bool isChecklist;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.date,
    this.checklist = const [],
    this.isChecklist = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'date': Timestamp.fromDate(date),
      'checklist': checklist,
      'isChecklist': isChecklist,
    };
  }

  factory Note.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? 'General',
      date: (data['date'] as Timestamp).toDate(),
      checklist: List<String>.from(data['checklist'] ?? []),
      isChecklist: data['isChecklist'] ?? false,
    );
  }
}

class NoteService {
  final CollectionReference notesCollection =
  FirebaseFirestore.instance.collection('notes');

  Stream<List<Note>> getNotesStream() {
    return notesCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
    });
  }

  Future<void> saveNote(Note note) async {
    if (note.id.isEmpty) {
      await notesCollection.add(note.toMap());
    } else {
      await notesCollection.doc(note.id).set(note.toMap());
    }
  }

  Future<void> deleteNote(String id) async {
    await notesCollection.doc(id).delete();
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Welcome, User!", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      const SizedBox(height: 4),
                      const Text("Note-Taking App", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                    ],
                  ),
                  const CircleAvatar(
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                    radius: 22,
                  )
                ],
              ),
              const SizedBox(height: 25),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B5BF2), Color(0xFF8B7EF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF6B5BF2).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))
                    ]
                ),
                child: Row(
                  children: [
                    Container(
                      height: 50, width: 50,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.cloud_done, color: Colors.orangeAccent),
                    ),
                    const SizedBox(width: 15),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Firebase Sync", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text("Data stored in Firestore", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 0.9,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  children: [
                    _buildCategoryCard(context, "Personal", Icons.description_outlined, Colors.purpleAccent),
                    _buildCategoryCard(context, "Academic", Icons.school_outlined, Colors.blueAccent),
                    _buildCategoryCard(context, "Work", Icons.work_outline, Colors.orangeAccent),
                    _buildCategoryCard(context, "Others", Icons.folder_open_outlined, Colors.pinkAccent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.note_alt_outlined), onPressed: () {}),
            IconButton(icon: const Icon(Icons.check_box_outlined), onPressed: () {}),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                height: 60, width: 60,
                decoration: BoxDecoration(
                    color: const Color(0xFF6B5BF2),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF6B5BF2).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))]
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
            ),
            IconButton(icon: const Icon(Icons.lightbulb_outline), onPressed: () {}),
            IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => NotesListScreen(category: title)));
      },
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text("View Notes", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class NotesListScreen extends StatefulWidget {
  final String category;
  const NotesListScreen({super.key, required this.category});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF6B5BF2)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.category, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Note>>(
        stream: NoteService().getNotesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final notes = snapshot.data?.where((n) => n.category == widget.category).toList() ?? [];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemCount: notes.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildAddNoteCard();
                }
                return _buildNoteCard(notes[index - 1]);
              },
            ),
          );
        },
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF6B5BF2),
          onPressed: () {
            final newNote = Note(
              id: '',
              title: 'New ${widget.category} Idea',
              content: 'This is saved directly to Firestore',
              category: widget.category,
              date: DateTime.now(),
            );
            NoteService().saveNote(newNote);
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Add Note", style: TextStyle(color: Colors.white)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAddNoteCard() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEBFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6B5BF2).withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6B5BF2), style: BorderStyle.solid),
              ),
              child: const Icon(Icons.add, color: Color(0xFF6B5BF2)),
            ),
            const SizedBox(height: 8),
            const Text("New note", style: TextStyle(color: Color(0xFF6B5BF2), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return GestureDetector(
      onLongPress: () {
        NoteService().deleteNote(note.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Note Deleted")));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D2D2D)),
            ),
            const SizedBox(height: 8),
            Text(
              note.content,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat('dd.MM.yyyy').format(note.date),
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}