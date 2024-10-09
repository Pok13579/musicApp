import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlbumScreen extends StatefulWidget {
  @override
  _ArtistScreenState createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<AlbumScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _profilePictureUrl = '';
  List<String> _artists = []; // List to hold artists

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadArtists(); // Load artists from Firestore
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

  Future<void> _loadArtists() async {
    try {
      final songsCollection = _firestore.collection('Song');
      final querySnapshot = await songsCollection.get();

      final artists = <String>{}; // Using a Set to avoid duplicates

      for (var doc in querySnapshot.docs) {
        final artist = doc.data()['artist'] as String?;
        if (artist != null) {
          artists.add(artist);
        }
      }

      setState(() {
        _artists = artists.toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading artists: $e')),
      );
    }
  }

  Future<void> _showSongsByArtist(String artist) async {
    try {
      final songsCollection = _firestore.collection('Song');
      final querySnapshot = await songsCollection.where('artist', isEqualTo: artist).get();

      final songs = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'songName': data['song_name'] ?? 'Unnamed Song',
          'album': data['album'] ?? 'Unknown Album',
          'genre': data['genre'] ?? 'Unknown Genre',
          'coverLocation': data['cover_location'] ?? '',
          'songLocation': data['song_location'] ?? '',
          'uploadDate': data['upload_date'] ?? '',
        };
      }).toList();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Songs by $artist'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return SongDetailCard(
                    songName: song['songName']!,
                    album: song['album']!,
                    artist: artist,
                    coverLocation: song['coverLocation']!,
                    songLocation: song['songLocation']!,
                    uploadDate: song['uploadDate']!,
                  );
                },
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching songs: $e')),
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
              'ศิลปิน',
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
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _artists.length,
          itemBuilder: (context, index) {
            final artist = _artists[index];
            return GestureDetector(
              onTap: () => _showSongsByArtist(artist),
              child: ArtistCard(artist),
            );
          },
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
              Navigator.pushNamed(context, '/recommendations');
              break;
            case 3:
              Navigator.pushNamed(context, '/genres');
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

class ArtistCard extends StatelessWidget {
  final String name;

  ArtistCard(this.name);

 @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Color(0xFFE7D1BB),
        ),
        child: Center(
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class SongDetailCard extends StatelessWidget {
  final String songName;
  final String album;
  final String artist;
  final String coverLocation;
  final String songLocation;
  final String uploadDate;

  SongDetailCard({
    required this.songName,
    required this.album,
    required this.artist,
    required this.coverLocation,
    required this.songLocation,
    required this.uploadDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(songName),
        subtitle: Text('Album: $album\nArtist: $artist\nUploaded: $uploadDate'),
      ),
    );
  }
}
