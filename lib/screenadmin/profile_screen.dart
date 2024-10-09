import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'UploadScreen.dart';  // Import the UploadScreen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _fullNameController;
  late TextEditingController _pictureController;
  late TextEditingController _currentPasswordController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _pictureController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _fullNameController.text = userDoc.data()?['full_name'] ?? '';
            _pictureController.text = userDoc.data()?['picture'] ?? '';
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user data found.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  Future<void> _updateUserData() async {
    final user = _auth.currentUser;

    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'full_name': _fullNameController.text.trim(),
        'picture': _pictureController.text.trim(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    try {
      final userCollection = await _firestore.collection('users').get();
      return userCollection.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e')),
      );
      return [];
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _pictureController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Color(0xFF151931),
        foregroundColor: Color(0xFFE7D1BB),
      ),
      body: Container(
        color: Color(0xFF151931),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (_pictureController.text.isNotEmpty)
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(_pictureController.text),
                      backgroundColor: Color(0xFF151931),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
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
                  controller: _pictureController,
                  decoration: const InputDecoration(
                    labelText: 'Picture URL',
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
                  controller: _currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _updateUserData,
                  child: const Text(
                    'Update Profile',
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
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UploadScreen()),
                    );
                  },
                  child: const Text(
                    'Upload Song',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      SongItem('Song', 'Go to edit'),
                      // Add other SongItem widgets here
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Edit Users',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No users found.'));
                    }
                    return SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final userData = snapshot.data![index];
                          return UserItem(
                            userData['full_name'] ?? 'Unknown',
                            userData['email'] ?? 'No email',
                            userData['picture'] ?? '',
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SongItem extends StatelessWidget {
  final String songName;
  final String artistName;

  SongItem(this.songName, this.artistName);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFFE7D1BB), // Color cream
            child: Icon(Icons.music_note, size: 40.0, color: Color(0xFF84725E)),
          ),
          SizedBox(height: 8),
          Text(songName, style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
          Text(artistName, style: TextStyle(color: Color(0xFFA096A5)), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class UserItem extends StatelessWidget {
  final String fullName;
  final String email;
  final String picture;

  UserItem(this.fullName, this.email, this.picture);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: picture.isNotEmpty ? NetworkImage(picture) : null,
            backgroundColor: Color(0xFFE7D1BB), // Color cream
            child: picture.isEmpty ? Icon(Icons.person, size: 40.0, color: Color(0xFF84725E)) : null,
          ),
          SizedBox(height: 8),
          Text(fullName, style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
          Text(email, style: TextStyle(color: Color(0xFFA096A5)), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
