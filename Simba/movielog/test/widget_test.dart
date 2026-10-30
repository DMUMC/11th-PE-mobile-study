import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/widgets/tmdb_poster_image.dart';

void main() {
  testWidgets('poster_path가 null이면 placeholder를 보여준다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TmdbPosterImage(posterPath: null, width: 100, height: 150),
      ),
    );

    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
