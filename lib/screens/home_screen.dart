import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart'; // ใช้ just_audio แทน audioplayers

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();

  String _profilePictureUrl = '';
  String _fullName = '';
  List<Map<String, dynamic>> _songs = [];
  int _currentSongIndex = 0;
  String _currentSongName = '';
  String _currentSongArtist = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadSongs();
    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _playNextSong();
      }
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _profilePictureUrl = userDoc.data()?['picture'] ?? '';
            _fullName = userDoc.data()?['full_name'] ?? '';
          });
        } else {
          setState(() {
            _profilePictureUrl = '';
            _fullName = '';
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

  void _shuffleAndPlaySong() async {
    if (_songs.isNotEmpty) {
      setState(() {
        _songs.shuffle();
        _currentSongIndex = 0; // Start with the first song after shuffling
      });
      _playCurrentSong();
    }
  }

  void _playCurrentSong() async {
    if (_songs.isNotEmpty) {
      final song = _songs[_currentSongIndex];
      try {
        await _audioPlayer.setUrl(song['song_location']);
        await _audioPlayer.play();
        setState(() {
          _currentSongName = song['song_name'];
          _currentSongArtist = song['artist'];
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing song: $e')),
        );
      }
    }
  }

  void _playNextSong() {
    if (_songs.isNotEmpty) {
      setState(() {
        _currentSongIndex = (_currentSongIndex + 1) % _songs.length;
      });
      _playCurrentSong();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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
                Navigator.pushNamed(context, '/Setting');
              },
              child: CircleAvatar(
                backgroundImage: _profilePictureUrl.isNotEmpty
                    ? NetworkImage(_profilePictureUrl)
                    : AssetImage('assets/profile.jpg') as ImageProvider,
              ),
            ),
            SizedBox(width: 5),
            Text(
              _fullName.isNotEmpty ? _fullName : 'ชื่อผู้ใช้',
              style: TextStyle(color: Color(0xFFA096A5), fontSize: 16),
            ),
          ],
        ),
        actions: [
          Stack(
            children: <Widget>[
              IconButton(
                icon: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color(0xFF252841),
                      width: 2.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(Icons.notifications, color: Color(0xFFA096A5)),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/notificate');
                },
              ),
              Positioned(
                right: 11,
                top: 11,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF3D3D),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'รายการเพลงแนะนำ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.shuffle, color: Color(0xFFE7D1BB)),
                      onPressed: _shuffleAndPlaySong,
                    ),
                    SizedBox(width: 16),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(0xFFE7D1BB),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: IconButton(
                          icon: Icon(Icons.skip_next, color: Color(0xFF84725E)),
                          onPressed: _playNextSong,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 5),
            // Display currently playing song
            if (_currentSongName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'กำลังเล่น: $_currentSongName - $_currentSongArtist',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            Expanded(
              child: ListView(
                children: _songs.map((song) {
                  return SongItem(
                    song['song_name'],
                    song['artist'],
                    song['cover_location'],
                    song['song_location'],
                    _audioPlayer,
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
            icon: Icon(Icons.search),
            label: '',
            tooltip: 'ค้นหา',
            backgroundColor: Color(0xFFE7D1BB),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.recommend),
            label: '',
            tooltip: 'แนะนำ',
            backgroundColor: Color(0xFFE7D1BB),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: '',
            tooltip: 'ประเภท',
            backgroundColor: Color(0xFFE7D1BB),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.album),
            label: '',
            tooltip: 'อัลบั้ม',
            backgroundColor: Color(0xFFE7D1BB),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_play),
            label: '',
            tooltip: 'เพลลิสต์',
            backgroundColor: Color(0xFFE7D1BB),
          ),
        ],
     selectedItemColor: Color(0xFF84725E),
        unselectedItemColor: Color(0xFF84725E),
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/search');
              break;
            case 1:
              Navigator.pushNamed(context, '/recommendations');
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
  final String artist;
  final String coverLocation;
  final String songLocation;
  final AudioPlayer mainPlayer;

  SongItem(this.songName, this.artist, this.coverLocation, this.songLocation, this.mainPlayer);

  @override
  _SongItemState createState() => _SongItemState();
}

class _SongItemState extends State<SongItem> {
  bool _isPlaying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.mainPlayer.playerStateStream.listen((playerState) {
      setState(() {
        _isPlaying = playerState.playing;
      });
    });
  }

  void _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await widget.mainPlayer.pause();
      } else {
        await widget.mainPlayer.setUrl(widget.songLocation);
        await widget.mainPlayer.play();
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error playing song: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.all(8.0),
      leading: CircleAvatar(
        backgroundImage: NetworkImage(widget.coverLocation),
      ),
      title: Text(widget.songName, style: TextStyle(color: Colors.white)),
      subtitle: Text(widget.artist, style: TextStyle(color: Colors.white54)),
      onTap: _togglePlayPause,
    );
  }
}
