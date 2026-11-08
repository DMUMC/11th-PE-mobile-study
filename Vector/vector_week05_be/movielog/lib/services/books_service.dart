import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.isAvailable,
  });

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'] as int,
    title: json['title'] as String,
    description: json['description'] as String,
    category: (json['category'] as Map<String, dynamic>?)?['name'] as String?,
    isAvailable: json['isAvailable'] as bool,
  );

  final int id;
  final String title;
  final String description;
  final String? category;
  final bool isAvailable;
}

class BooksService {
  BooksService()
    : _client = http.Client(),
      _url = Uri.parse(
        '${const String.fromEnvironment('BOOK_API_URL', defaultValue: 'http://127.0.0.1:3000')}/books',
      );

  final http.Client _client;
  final Uri _url;
  static const _timeout = Duration(seconds: 10);

  Future<List<Book>> findAll() async {
    final response = await _client.get(_url).timeout(_timeout);
    final books = _decode(response, 200) as List<dynamic>;
    return books
        .map((item) => Book.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Book> create(String title, String description, int categoryId) async {
    final response = await _client
        .post(
          _url,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({
            'title': title,
            'description': description,
            'categoryId': categoryId,
          }),
        )
        .timeout(_timeout);
    return Book.fromJson(_decode(response, 201) as Map<String, dynamic>);
  }

  dynamic _decode(http.Response response, int expectedStatus) {
    if (response.statusCode == expectedStatus) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    String? detail;
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) {
        final message = body['message'];
        if (message is String) detail = message;
        if (message is List) detail = message.join(', ');
      }
    } on FormatException {
      // An upstream error page may contain HTML instead of JSON.
    }
    throw BooksApiException(
      'HTTP ${response.statusCode}${detail == null ? '' : ' · $detail'}',
    );
  }

  void close() => _client.close();
}

class BooksApiException implements Exception {
  const BooksApiException(this.message);

  final String message;
}
