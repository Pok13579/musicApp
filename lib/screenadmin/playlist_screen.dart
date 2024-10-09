import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add.dart'; // Import the AddSongScreen

class PlaylistScreen extends StatefulWidget {
  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _profilePictureUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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

  Future<void> _showPlaylistSongs(String playlistId) async {
    try {
      final playlistDoc = await _firestore.collection('Playlist').doc(playlistId).get();
      if (!playlistDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playlist not found')),
        );
        return;
      }

      final playlistData = playlistDoc.data() as Map<String, dynamic>?;

      if (playlistData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playlist data is null')),
        );
        return;
      }

      final songIds = List<String>.from(playlistData['songs'] ?? []);
      if (songIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No songs found in playlist')),
        );
        return;
      }

      List<Map<String, dynamic>> songs = [];
      for (String songId in songIds) {
        final songDoc = await _firestore.collection('Song').doc(songId).get();
        final songData = songDoc.data() as Map<String, dynamic>?;

        if (songData != null) {
          songs.add({
            'songName': songData['song_name'] ?? 'Unnamed Song',
            'album': songData['album'] ?? 'Unknown Album',
            'artist': songData['artist'] ?? 'Unknown Artist',
            'coverLocation': songData['cover_location'] ?? '',
            'songLocation': songData['song_location'] ?? '',
            'uploadDate': songData['upload_date'] ?? '',
          });
        } else {
          songs.add({
            'songName': 'Unknown Song',
            'album': 'Unknown Album',
            'artist': 'Unknown Artist',
            'coverLocation': '',
            'songLocation': '',
            'uploadDate': '',
          });
        }
      }

      if (songs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No valid songs found in playlist')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Songs in Playlist'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return SongDetailCard(
                    songName: song['songName']!,
                    album: song['album']!,
                    artist: song['artist']!,
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
                  Navigator.of(context).pop();
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
              'เพลลิสต์',
              style: TextStyle(
                color: Color(0xFFA096A5),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF151931),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Add()),
          );
        },
        child: Icon(Icons.add, color: Color(0xFFE7D1BB)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('Playlist')
              .where('createdBy', isEqualTo: _auth.currentUser?.uid) // เปลี่ยนจาก userId เป็น createdBy
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No playlists available'));
            }

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
              ),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var doc = snapshot.data!.docs[index];
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                String playlistName = data['playlistName'] ?? 'Unnamed Playlist';
                String playlistId = doc.id;

                return GestureDetector(
                  onTap: () {
                    _showPlaylistSongs(playlistId);
                  },
                  child: PlaylistCard(playlistName),
                );
              },
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
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.recommend),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.album),
            label: '',
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
              Navigator.pushNamed(context, '/albums');
              break;
          }
        },
      ),
    );
  }
}

class PlaylistCard extends StatelessWidget {
  final String playlistName;

  const PlaylistCard(this.playlistName, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFF222A36),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            playlistName,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
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

  const SongDetailCard({
    required this.songName,
    required this.album,
    required this.artist,
    required this.coverLocation,
    required this.songLocation,
    required this.uploadDate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: coverLocation.isNotEmpty
          ? Image.network(coverLocation, width: 50, height: 50, fit: BoxFit.cover)
          : Container(width: 50, height: 50, color: Colors.grey),
      title: Text(songName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Album: $album'),
          Text('Artist: $artist'),
          Text('Uploaded on: $uploadDate'),
        ],
      ),
    );
  }
}
