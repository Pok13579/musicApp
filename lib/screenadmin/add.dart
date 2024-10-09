import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Add extends StatefulWidget {
  @override
  _AddScreenState createState() => _AddScreenState();
}

class _AddScreenState extends State<Add> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> availableSongs = [];
  List<Map<String, dynamic>> playlistSongs = [];
  final TextEditingController _playlistNameController = TextEditingController();
  List<Map<String, dynamic>> playlists = [];
  String? _selectedPlaylistID;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchAvailableSongs();
    fetchUserPlaylists(); // เปลี่ยนชื่อฟังก์ชันที่เรียกใช้เพื่อให้เหมาะสม
  }

  Future<void> fetchAvailableSongs() async {
    setState(() {
      _isLoading = true;
    });
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('Song').get();
      List<Map<String, dynamic>> songs = querySnapshot.docs.map((doc) {
        return {
          'Song_ID': doc.id,
          'cover_location': doc['cover_location'],
          'song_name': doc['song_name'],
        };
      }).toList();
      setState(() {
        availableSongs = songs;
      });
    } catch (e) {
      showToast('Error fetching songs: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchUserPlaylists() async {
    setState(() {
      _isLoading = true;
    });
    User? user = _auth.currentUser; // ตรวจสอบผู้ใช้ที่ลงชื่อเข้าใช้
    if (user == null) {
      showToast('Please log in to view playlists');
      return;
    }
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('Playlist')
          .where('createdBy', isEqualTo: user.uid) // ดึงเฉพาะเพลลิสต์ที่สร้างโดยผู้ใช้
          .get();
      List<Map<String, dynamic>> fetchedPlaylists = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'playlistID': doc.id,
          'playlistName': data['playlistName'] ?? 'Unknown',
        };
      }).toList();
      setState(() {
        playlists = fetchedPlaylists;
      });
    } catch (e) {
      showToast('Error fetching playlists: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchPlaylistSongs(String playlistID) async {
    setState(() {
      _isLoading = true;
    });
    try {
      DocumentSnapshot playlistSnapshot = await _firestore.collection('Playlist').doc(playlistID).get();
      if (playlistSnapshot.exists) {
        List<dynamic> songIDs = playlistSnapshot['songs'] ?? [];
        List<Map<String, dynamic>> songs = availableSongs.where((song) => songIDs.contains(song['Song_ID'])).toList();
        setState(() {
          playlistSongs = songs;
        });
      } else {
        showToast('Playlist not found');
      }
    } catch (e) {
      showToast('Error fetching playlist songs: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> addSongToPlaylist(String songID, String playlistID) async {
    try {
      DocumentReference playlistRef = _firestore.collection('Playlist').doc(playlistID);
      await playlistRef.update({
        'songs': FieldValue.arrayUnion([songID])
      });
      setState(() {
        playlistSongs.add(availableSongs.firstWhere((song) => song['Song_ID'] == songID));
      });
      showToast('Song added successfully');
    } catch (e) {
      showToast('Error adding song to playlist: $e');
    }
  }

  Future<void> removeSongFromPlaylist(String songID, String playlistID) async {
    try {
      DocumentReference playlistRef = _firestore.collection('Playlist').doc(playlistID);
      await playlistRef.update({
        'songs': FieldValue.arrayRemove([songID])
      });
      setState(() {
        playlistSongs.removeWhere((song) => song['Song_ID'] == songID);
      });
      showToast('Song removed successfully');
    } catch (e) {
      showToast('Error removing song from playlist: $e');
    }
  }

  Future<void> createPlaylist() async {
    User? user = _auth.currentUser;

    if (user == null) {
      showToast('Please log in to perform this action');
      return;
    }

    String playlistName = _playlistNameController.text.trim();
    if (playlistName.isEmpty) {
      showToast('Playlist name cannot be empty');
      return;
    }

    // Check for duplicate playlist names
    if (playlists.any((playlist) => playlist['playlistName'] == playlistName)) {
      showToast('A playlist with this name already exists');
      return;
    }

    try {
      DocumentReference newPlaylistRef = await _firestore.collection('Playlist').add({
        'playlistName': playlistName,
        'songs': [],
        'createdBy': user.uid, // บันทึก ID ของผู้ใช้ที่สร้างเพลลิสต์
      });
      setState(() {
        playlists.add({
          'playlistID': newPlaylistRef.id,
          'playlistName': playlistName,
        });
        _playlistNameController.clear();
        _selectedPlaylistID = newPlaylistRef.id; // Select the new playlist automatically
        fetchPlaylistSongs(_selectedPlaylistID!); // Fetch songs for the new playlist
      });
      showToast('Playlist created successfully');
    } catch (e) {
      showToast('Error creating playlist: $e');
    }
  }

  Future<void> deletePlaylist(String playlistID) async {
    try {
      await _firestore.collection('Playlist').doc(playlistID).delete();
      setState(() {
        playlists.removeWhere((playlist) => playlist['playlistID'] == playlistID);
        if (_selectedPlaylistID == playlistID) {
          _selectedPlaylistID = null;
          playlistSongs.clear();
        }
      });
      showToast('Playlist deleted successfully');
    } catch (e) {
      showToast('Error deleting playlist: $e');
    }
  }

  Future<void> confirmAndSavePlaylist() async {
    if (_selectedPlaylistID == null) {
      showToast('Select a playlist to save');
      return;
    }

    try {
      await _firestore.collection('Playlist').doc(_selectedPlaylistID).update({
        'songs': playlistSongs.map((song) => song['Song_ID']).toList(),
      });
      showToast('Playlist saved successfully');
    } catch (e) {
      showToast('Error saving playlist: $e');
    }
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF151931),
      appBar: AppBar(
        backgroundColor: Color(0xFF151931),
        elevation: 0,
        title: Text('Add Songs', style: TextStyle(color: Color(0xFFE7D1BB))),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFE7D1BB)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _playlistNameController,
              decoration: InputDecoration(
                labelText: 'Playlist Name',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE7D1BB)),
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: _isLoading ? null : createPlaylist,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.black)
                  : Text('Create Playlist', style: TextStyle(color: Colors.black)),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Color(0xFFE7D1BB)),
              ),
            ),
            SizedBox(height: 20),
            DropdownButton<String>(
              hint: Text('Select Playlist', style: TextStyle(color: Colors.white)),
              value: _selectedPlaylistID,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPlaylistID = newValue;
                  if (newValue != null) {
                    fetchPlaylistSongs(newValue);
                  } else {
                    playlistSongs.clear();
                  }
                });
              },
              items: playlists.map<DropdownMenuItem<String>>((Map<String, dynamic> playlist) {
                return DropdownMenuItem<String>(
                  value: playlist['playlistID'],
                  child: Text(playlist['playlistName'], style: TextStyle(color: Colors.white)),
                );
              }).toList(),
              dropdownColor: Color(0xFF151931),
              iconEnabledColor: Color(0xFFE7D1BB),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.black))
                  : ListView.builder(
                      itemCount: availableSongs.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(availableSongs[index]['song_name'], style: TextStyle(color: Colors.white)),
                          trailing: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              if (_selectedPlaylistID != null) {
                                addSongToPlaylist(availableSongs[index]['Song_ID'], _selectedPlaylistID!);
                              } else {
                                showToast('Please select a playlist first');
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: _isLoading ? null : confirmAndSavePlaylist,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.black)
                  : Text('Save Playlist', style: TextStyle(color: Colors.black)),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Color(0xFFE7D1BB)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
