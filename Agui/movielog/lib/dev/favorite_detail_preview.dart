// Controlled HTTP responses for Device Hub checks. No real account is modified.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/auth_interceptor.dart';
import '../core/storage/token_storage.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/favorite_api_service.dart';
import '../movie/movie_detail_loader.dart';

class FavoriteDetailPreview extends StatefulWidget {
  const FavoriteDetailPreview({super.key, required this.scenario});
  final String scenario;

  @override
  State<FavoriteDetailPreview> createState() => _FavoriteDetailPreviewState();
}

class _FavoriteDetailPreviewState extends State<FavoriteDetailPreview> {
  late final Dio dio;

  @override
  void initState() {
    super.initState();
    dio = Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
      ..interceptors.add(AuthInterceptor(_PreviewStorage()))
      ..httpClientAdapter = _Responses(widget.scenario);
  }

  @override
  void dispose() {
    dio.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Provider<FavoriteApiService>(
    create: (_) => FavoriteApiService(dio),
    child: const MovieDetailLoader(
      movieId: 10,
      imageAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
      initialMovie: TmdbMovieDto(
        id: 10,
        title: '별빛 아래 우리',
        posterPath: null,
        releaseDate: '2025-01-01',
        genreNames: ['로맨스', '드라마'],
        overview: '서로의 일상에 스며든 두 사람의 이야기.\n별빛 아래에서 시작되는 따뜻한 로맨스.',
      ),
    ),
  );
}

class _PreviewStorage implements TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'preview-token';
  @override
  Future<void> saveAccessToken(String token) async {}
  @override
  Future<void> deleteAccessToken() async {}
}

class _Responses implements HttpClientAdapter {
  _Responses(this.scenario);
  final String scenario;
  bool favorite = false;
  int checks = 0;

  ResponseBody response(Object? result, {int status = 200, String? code}) =>
      ResponseBody.fromString(
        jsonEncode({
          'isSuccess': status < 400,
          'code': code ?? 'COMMON$status',
          'message': 'preview',
          'result': result,
        }),
        status,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    debugPrint('[Favorite preview] ${options.method} ${options.path}');
    await Future<void>.delayed(const Duration(seconds: 2));
    if (options.method == 'GET') {
      if (scenario == 'statusError' && ++checks == 1) {
        return response(null, status: 500);
      }
      return response({'isFavorite': favorite});
    }
    if (options.method == 'POST') {
      if (scenario == 'saveError') return response(null, status: 500);
      favorite = true;
      if (scenario == 'conflict') {
        return response(null, status: 409, code: 'FAVORITE409_1');
      }
      if (scenario == 'timeout') {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        );
      }
      return response({
        'favoriteId': 1,
        'movieId': 10,
        'createdAt': '2026-11-26T00:00:00Z',
      }, status: 201);
    }
    favorite = false;
    return response(null);
  }

  @override
  void close({bool force = false}) {}
}
