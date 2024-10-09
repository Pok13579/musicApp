import 'package:flutter/material.dart';
import 'screenadmin/home_screen.dart';
import 'screenadmin/search_screen.dart';
import 'screenadmin/recommendations_screen.dart';
import 'screenadmin/genre_screen.dart';
import 'screenadmin/album_screen.dart';
import 'screenadmin/playlist_screen.dart';
import 'screenadmin/profile_screen.dart';
import 'screenadmin/add.dart';
import 'screenadmin/notificate.dart';

void main() {
  runApp(Adminhome());
}

class Adminhome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
      theme: ThemeData.dark(),
      home: HomeScreen(), // HomeScreen as default
      routes: {
        '/home': (context) => HomeScreen(),
        '/Setting': (context) => ProfileScreen(),
        '/search': (context) => SearchScreen(),
        '/recommendations': (context) => RecommendationsScreen(),
        '/genres': (context) => GenreScreen(),
        '/albums': (context) => AlbumScreen(),
        '/playlists': (context) => PlaylistScreen(),
        '/Addsongs': (context) => Add(),
        '/notificate': (context) => NotificationScreen(), 
      },
    );
  }
}
