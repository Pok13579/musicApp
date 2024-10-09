import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late TextEditingController _genreController;
  File? _songFile;
  File? _coverFile;
  String? _songFileName;
  String? _coverFileName;

  @override
  void initState() {
    super.initState();
    _artistController = TextEditingController();
    _albumController = TextEditingController();
    _genreController = TextEditingController();
  }

  @override
  void dispose() {
    _artistController.dispose();
    _albumController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(bool isCover) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: isCover ? FileType.custom : FileType.custom,
      allowedExtensions: isCover ? ['jpg', 'jpeg', 'png'] : ['mp3'],
    );

    if (result != null) {
      setState(() {
        if (isCover) {
          _coverFile = File(result.files.single.path!);
          _coverFileName = result.files.single.name;
        } else {
          _songFile = File(result.files.single.path!);
          _songFileName = result.files.single.name;
        }
      });
    }
  }

  Future<void> _uploadSong() async {
    final artist = _artistController.text.trim();
    final album = _albumController.text.trim();
    final genre = _genreController.text.trim();
    final uploadDate = DateTime.now().toUtc().add(Duration(hours: 7)).toIso8601String(); // Thailand timezone

    if (artist.isEmpty || album.isEmpty || genre.isEmpty || _songFile == null || _coverFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields and upload files.')),
      );
      return;
    }

    try {
      final songFileName = _songFileName ?? '${DateTime.now().millisecondsSinceEpoch}_song.mp3';
      final coverFileName = _coverFileName ?? '${DateTime.now().millisecondsSinceEpoch}_cover.jpg';

      final songRef = _storage.ref().child('music_list/$songFileName');
      final coverRef = _storage.ref().child('cover_music/$coverFileName');

      await songRef.putFile(_songFile!);
      await coverRef.putFile(_coverFile!);

      final songUrl = await songRef.getDownloadURL();
      final coverUrl = await coverRef.getDownloadURL();

      await _firestore.collection('Song').add({
        'artist': artist,
        'album': album,
        'genre': genre,
        'song_location': songUrl,
        'cover_location': coverUrl,
        'song_name': songFileName,
        'upload_date': uploadDate,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song uploaded successfully')),
      );

      Navigator.pop(context);  // Navigate back to the previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading song: $e')),
      );
    }
  }

  Future<void> _deleteSong(String songId, String songUrl, String coverUrl) async {
    try {
      // Delete the song and cover image from Firebase Storage
      await _storage.refFromURL(songUrl).delete();
      await _storage.refFromURL(coverUrl).delete();

      // Delete the song document from Firestore
      await _firestore.collection('Song').doc(songId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting song: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Song'),
        backgroundColor: Color(0xFF151931),
        foregroundColor: Color(0xFFE7D1BB),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: _artistController,
                decoration: const InputDecoration(
                  labelText: 'Artist Name',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _albumController,
                decoration: const InputDecoration(
                  labelText: 'Album Name',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _genreController,
                decoration: const InputDecoration(
                  labelText: 'Type of Music',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _pickFile(false),
                child: const Text('Select Song File (MP3)'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _pickFile(true),
                child: const Text('Select Cover Image (JPG, PNG)'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _uploadSong,
                child: const Text(
                  'Upload Song',
                  style: TextStyle(color: Color(0xFF84725E)),
                ),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Color(0xFFE7D1BB)),
                  padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.symmetric(vertical: 16.0)),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SongListScreen()),
                  );
                },
                child: const Text(
                  'View Song List',
                  style: TextStyle(color: Color(0xFF84725E)),
                ),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Color(0xFFE7D1BB)),
                  padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.symmetric(vertical: 16.0)),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SongListScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> _deleteSong(BuildContext context, String songId, String songUrl, String coverUrl) async {
    try {
      // Delete the song and cover image from Firebase Storage
      await _storage.refFromURL(songUrl).delete();
      await _storage.refFromURL(coverUrl).delete();

      // Delete the song document from Firestore
      await _firestore.collection('Song').doc(songId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting song: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Song List'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('Song').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No songs found'));
          }

          final songs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              final songId = song.id;
              final songData = song.data() as Map<String, dynamic>;
              final songUrl = songData['song_location'] as String;
              final coverUrl = songData['cover_location'] as String;

              return ListTile(
                title: Text(songData['song_name'] as String),
                subtitle: Text('Artist: ${songData['artist']}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSong(context, songId, songUrl, coverUrl),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
