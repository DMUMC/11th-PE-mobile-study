import 'package:flutter/material.dart';

void main() {
  List<Movie> movies = [
    Movie('오디세이', '크리스토퍼 놀란'),
    Movie('인생은 아름다워', '로베르토 베니니'),
    Movie('포레스트 검프', '로버트 저메키스')
  ];

  for(Movie movie in movies){
    print(movie.title);
  }

  String? nickname = null;

  String safeNickname = nickname ?? 'Guest';

  print(safeNickname);

  runApp(const Example());
}

class Example extends StatelessWidget {
  const Example({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: Text('Hello MovieLog!')),
      ),
    );
  }
}

class Movie {
  String title;
  String director;

  Movie(this.title, this.director);
}