import 'package:flutter/material.dart';

import '../services/books_service.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final _api = BooksService();
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _category = TextEditingController();
  List<Book> _books = [];
  bool _loading = false;
  bool _saving = false;
  String? _listStatus;
  String? _createStatus;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _api.close();
    _title.dispose();
    _description.dispose();
    _category.dispose();
    super.dispose();
  }

  String _errorMessage(Object error) => error is BooksApiException
      ? error.message
      : '도서 API에 연결할 수 없습니다. NestJS 서버 상태를 확인해 주세요.';

  Future<void> _loadBooks() async {
    setState(() {
      _loading = true;
      _listStatus = null;
    });
    try {
      final books = await _api.findAll();
      if (!mounted) return;
      setState(() {
        _books = books;
        _listStatus = 'GET /books · 200 OK · ${books.length}권';
      });
    } catch (error) {
      if (mounted) setState(() => _listStatus = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createBook() async {
    if (_loading || _saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _createStatus = null;
    });
    try {
      final book = await _api.create(
        _title.text.trim(),
        _description.text.trim(),
        int.parse(_category.text.trim()),
      );
      if (!mounted) return;
      _title.clear();
      _description.clear();
      _category.clear();
      setState(() {
        _books = [book, ..._books];
        _createStatus = 'POST /books · 201 Created · #${book.id} ${book.title}';
      });
      await _loadBooks();
    } catch (error) {
      if (mounted) setState(() => _createStatus = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _requiredText(String? value) =>
      (value ?? '').trim().isEmpty ? '값을 입력해 주세요.' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('도서 관리')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('도서 등록', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _title,
                    enabled: !_saving,
                    decoration: const InputDecoration(labelText: '제목'),
                    validator: _requiredText,
                  ),
                  TextFormField(
                    controller: _description,
                    enabled: !_saving,
                    decoration: const InputDecoration(labelText: '설명'),
                    validator: _requiredText,
                  ),
                  TextFormField(
                    controller: _category,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: '카테고리 ID',
                      helperText: 'MySQL에 등록된 카테고리 번호를 입력하세요.',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        (int.tryParse((value ?? '').trim()) ?? 0) < 1
                        ? '1 이상의 정수를 입력해 주세요.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loading || _saving ? null : _createBook,
                    child: Text(_saving ? '등록 중…' : '도서 등록'),
                  ),
                  if (_createStatus case final status?) Text(status),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '도서 목록',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              trailing: IconButton(
                tooltip: '도서 목록 새로고침',
                onPressed: _loading || _saving ? null : _loadBooks,
                icon: const Icon(Icons.refresh),
              ),
            ),
            if (_loading) const LinearProgressIndicator(),
            if (_listStatus case final status?) Text(status),
            for (final book in _books)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.menu_book),
                title: Text('#${book.id} ${book.title}'),
                subtitle: Text(
                  '${book.description}\n${book.category ?? '카테고리 미지정'} · ${book.isAvailable ? '이용 가능' : '이용 불가'}',
                ),
                isThreeLine: true,
              ),
          ],
        ),
      ),
    ),
  );
}
