import 'package:flutter/material.dart';
import 'package:musict/main(1).dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/recommendations_screen.dart';
import 'screens/genre_screen.dart';
import 'screens/album_screen.dart';
import 'screens/playlist_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/add.dart';
import 'screens/notificate.dart';

void main() {
  runApp(MyApp1());
}

class MyApp1 extends StatelessWidget {
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
