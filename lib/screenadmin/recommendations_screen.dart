import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart'; // Added import for audio playback

class RecommendationsScreen extends StatefulWidget {
  @override
  _RecommendationsScreenState createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _songs = [];
  String _profilePictureUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadSongs();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _profilePictureUrl = userDoc.data()?['picture'] ?? '';
          });
        } else {
          setState(() {
            _profilePictureUrl = '';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user profile: $e')),
      );
    }
  }

  Future<void> _loadSongs() async {
    try {
      final snapshot = await _firestore.collection('Song').get();
      final songs = snapshot.docs.map((doc) => doc.data()).toList();
      setState(() {
        _songs = songs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading songs: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF151931),
      appBar: AppBar(
        backgroundColor: Color(0xFF151931),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: CircleAvatar(
                backgroundImage: _profilePictureUrl.isNotEmpty
                    ? NetworkImage(_profilePictureUrl)
                    : AssetImage('assets/profile.jpg') as ImageProvider,
              ),
            ),
            SizedBox(width: 5),
            Text(
              'เพลงแนะนำ',
              style: TextStyle(
                color: Color(0xFFA096A5),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                image: DecorationImage(
                  image: AssetImage('assets/kpop.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'เพลงแนะนำ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 5),
            Expanded(
              child: ListView(
                children: _songs.map((song) {
                  return SongItem(
                    song['song_name'],
                    song['artist'],
                    song['cover_location'],
                    song['song_location'],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFFE7D1BB),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
            backgroundColor: Color(0xFFE7D1BB),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '',
            backgroundColor: Color(0xFFE7D1BB),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: '',
            backgroundColor: Color(0xFFE7D1BB),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.album),
            label: '',
            backgroundColor: Color(0xFFE7D1BB),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_play),
            label: '',
            backgroundColor: Color(0xFFE7D1BB),
          ),
        ],
        selectedItemColor: Color(0xFF84725E),
        unselectedItemColor: Color(0xFF84725E),
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/');
              break;
            case 1:
              Navigator.pushNamed(context, '/search');
              break;
            case 2:
              Navigator.pushNamed(context, '/genres');
              break;
            case 3:
              Navigator.pushNamed(context, '/albums');
              break;
            case 4:
              Navigator.pushNamed(context, '/playlists');
              break;
          }
        },
      ),
    );
  }
}

class SongItem extends StatefulWidget {
  final String songName;
  final String artistName;
  final String coverUrl;
  final String songLocation;

  SongItem(this.songName, this.artistName, this.coverUrl, this.songLocation);

  @override
  _SongItemState createState() => _SongItemState();
}

class _SongItemState extends State<SongItem> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.setUrl(widget.songLocation);
        await _audioPlayer.play();
      }
      setState(() {
        _isPlaying = !_isPlaying;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading or playing audio: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.all(8.0),
      tileColor: Color(0xFF252841),
      leading: widget.coverUrl.isNotEmpty
          ? CircleAvatar(
              backgroundImage: NetworkImage(widget.coverUrl),
            )
          : null,
      title: Text(widget.songName, style: TextStyle(color: Colors.white)),
      subtitle: Text(widget.artistName, style: TextStyle(color: Colors.white70)),
      trailing: IconButton(
        icon: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
        ),
        onPressed: _togglePlayPause,
      ),
    );
  }
}
