import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/movie/data/movie_sort_preference.dart';
import 'package:movielog/movie/movie_list_screen.dart';
import 'package:movielog/movie/widgets/movie_grid.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

final class _DelayedSortPreferences extends InMemorySharedPreferencesAsync {
  _DelayedSortPreferences()
    : super.withData({'selected_sort_order': MovieSortOrder.newest.name});

  final readGate = Completer<void>();

  @override
  Future<String?> getString(
    String key,
    SharedPreferencesOptions options,
  ) async {
    final value = await super.getString(key, options);
    if (key == 'selected_sort_order') await readGate.future;
    return value;
  }
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('sort menu opens before preference restore finishes', (
    tester,
  ) async {
    final preferences = _DelayedSortPreferences();
    SharedPreferencesAsyncPlatform.instance = preferences;
    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));

    await tester.tap(find.byTooltip('영화 정렬'));
    await tester.pumpAndSettle();
    expect(find.text('최신순'), findsOneWidget);

    await tester.tap(find.text('평점 높은순').last);
    await tester.pumpAndSettle();
    preferences.readGate.complete();
    await tester.pump();

    expect(find.text('평점 높은순'), findsOneWidget);
    expect(
      tester.widget<MovieGrid>(find.byType(MovieGrid)).movies.first.id,
      12,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected sort order is saved and restored on reopening', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('영화 정렬'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('평점 높은순').last);
    await tester.pumpAndSettle();

    expect(await MovieSortPreference().read(), MovieSortOrder.highestRated);
    expect(
      tester.widget<MovieGrid>(find.byType(MovieGrid)).movies.first.id,
      12,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('평점 높은순'), findsOneWidget);
    expect(
      tester.widget<MovieGrid>(find.byType(MovieGrid)).movies.first.id,
      12,
    );
    expect(tester.takeException(), isNull);
  });
}
