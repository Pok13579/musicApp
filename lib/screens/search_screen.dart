import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart'; // ใช้ just_audio แทน audioplayers

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer(); // เพิ่ม AudioPlayer

  String _profilePictureUrl = '';
  List<Map<String, dynamic>> _songs = [];
  List<Map<String, dynamic>> _filteredSongs = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadSongs();
    _searchController.addListener(() {
      _filterSongs();
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
      final songs = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      setState(() {
        _songs = songs;
        _filteredSongs = songs; // Initially, show all songs
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading songs: $e')),
      );
    }
  }

  void _filterSongs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSongs = _songs.where((song) {
        final songName = song['song_name'].toLowerCase();
        return songName.contains(query);
      }).toList();
    });
  }

  void _playSong(String songUrl) async {
    try {
      await _audioPlayer.setUrl(songUrl);
      _audioPlayer.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing song: $e')),
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Dispose the player when not in use
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
            CircleAvatar(
              backgroundImage: _profilePictureUrl.isNotEmpty
                  ? NetworkImage(_profilePictureUrl)
                  : AssetImage('assets/profile.jpg') as ImageProvider,
            ),
            SizedBox(width: 10),
            Text(
              'ค้นหา',
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
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFF252841),
                hintText: 'คุณต้องการฟังเพลงอะไร',
                hintStyle: TextStyle(color: Color(0xFF847A86)),
                prefixIcon: Icon(Icons.search, color: Color(0xFF84725E)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
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
                    Icon(Icons.shuffle, color: Color(0xFFE7D1BB)),
                    SizedBox(width: 16),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(0xFFE7D1BB),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(Icons.play_arrow, color: Color(0xFF84725E)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 5),
            Expanded(
              child: ListView(
                children: _filteredSongs.map((song) {
                  return SongItem(
                    song['song_name'],
                    song['artist'],
                    song['cover_location'],
                    song['song_location'],
                    _playSong, // Pass the play function
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
            icon: Icon(Icons.recommend),
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

class SongItem extends StatelessWidget {
  final String songName;
  final String artistName;
  final String coverUrl;
  final String songUrl;
  final Function(String) onPlay; // เพิ่ม parameter สำหรับฟังก์ชันเล่นเพลง

  SongItem(this.songName, this.artistName, this.coverUrl, this.songUrl, this.onPlay);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFF252841),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: coverUrl.isNotEmpty
              ? NetworkImage(coverUrl)
              : AssetImage('assets/default_cover.jpg') as ImageProvider,
        ),
        title: Text(
          songName,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          artistName,
          style: TextStyle(color: Color(0xFF847A86)),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.play_arrow,
            color: Colors.white,
          ),
          onPressed: () => onPlay(songUrl), // เรียกฟังก์ชันเล่นเพลงเมื่อกดปุ่ม
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String imagePath;
  final String title;

  CategoryCard(this.imagePath, this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              imagePath,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  final String imagePath;
  final String title;

  CategoryTile(this.imagePath, this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              imagePath,
              width: double.infinity,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
