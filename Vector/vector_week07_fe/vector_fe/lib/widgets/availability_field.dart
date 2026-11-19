import 'package:flutter/material.dart';

import '../services/member_api.dart';
import 'movielog_button.dart';
import 'movielog_text_form_field.dart';

class AvailabilityField extends StatefulWidget {
  const AvailabilityField({
    super.key,
    required this.api,
    required this.field,
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
  });

  final MemberApi api;
  final MemberField field;
  final String label;
  final String hint;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  @override
  State<AvailabilityField> createState() => AvailabilityFieldState();
}

class AvailabilityFieldState extends State<AvailabilityField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  String? _lastDuplicate;
  String? _verified;
  String? _failure;
  bool _loading = false;
  int _revision = 0;

  bool get _duplicate => _lastDuplicate == widget.controller.text;
  bool get isVerified => _verified == widget.controller.text;

  Future<void> _check() async {
    if (_loading || _duplicate || !_fieldKey.currentState!.validate()) return;
    final value = widget.controller.text;
    final revision = ++_revision;
    setState(() {
      _loading = true;
      _failure = null;
      _verified = null;
    });
    try {
      final available = await widget.api.checkAvailability(widget.field, value);
      if (!mounted || revision != _revision) return;
      setState(() {
        if (available) {
          _verified = value;
        } else {
          _lastDuplicate = value;
        }
      });
    } on MemberApiException catch (error) {
      if (mounted && revision == _revision) {
        setState(() => _failure = error.message);
      }
    } finally {
      if (mounted && revision == _revision) {
        setState(() => _loading = false);
      }
    }
  }

  void invalidate() => _changed(widget.controller.text);

  void _changed(String _) {
    setState(() {
      _revision++;
      _verified = null;
      _failure = null;
      _loading = false;
    });
    _fieldKey.currentState?.clearError();
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: MovieLogTextFormField(
          fieldKey: _fieldKey,
          label: widget.label,
          hintText: widget.hint,
          controller: widget.controller,
          onChanged: _changed,
          keyboardType: widget.field == MemberField.email
              ? TextInputType.emailAddress
              : null,
          validator: widget.validator,
          errorText: _duplicate ? '이미 사용 중인 ${widget.label}입니다.' : null,
          helperText:
              _failure ??
              (isVerified ? '사용 가능한 ${widget.label}입니다.' : '중복 확인이 필요합니다.'),
        ),
      ),
      const SizedBox(width: 10),
      Padding(
        padding: const EdgeInsets.only(top: 29),
        child: MovieLogButton(
          label: '중복 확인',
          loading: _loading,
          onPressed: _duplicate ? null : _check,
        ),
      ),
    ],
  );
}
