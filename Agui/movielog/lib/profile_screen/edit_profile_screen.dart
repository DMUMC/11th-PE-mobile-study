import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../widgets/movielog_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nickname;
  late final String _initialNickname;
  bool _allowPop = false;
  bool _dialogOpen = false;

  bool get _hasChanges => _nickname.text != _initialNickname;

  @override
  void initState() {
    super.initState();
    _initialNickname = context.read<AuthViewModel>().member?.nickname ?? '';
    _nickname = TextEditingController(text: _initialNickname);
  }

  Future<void> _popWithoutConfirmation() async {
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) context.pop();
  }

  Future<void> _requestBack() async {
    if (_dialogOpen || context.read<EditProfileViewModel>().status == EditProfileStatus.saving) return;
    if (!_hasChanges) {
      context.pop();
      return;
    }

    _dialogOpen = true;
    final discard = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('변경 내용을 버릴까요?',
                  textAlign: TextAlign.center,
                  style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('저장하지 않은 내용은 사라집니다.', textAlign: TextAlign.center),
              const SizedBox(height: 48),
              Row(
                children: [
                  Expanded(
                    child: MovieLogButton(
                      label: '계속 수정',
                      backgroundColor: AppColors.primary100,
                      foregroundColor: AppColors.primary600,
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MovieLogButton(
                      label: '나가기',
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    _dialogOpen = false;
    if (mounted && discard == true) await _popWithoutConfirmation();
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final viewModel = context.read<EditProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await viewModel.save(_nickname.text);
    if (!mounted) return;
    if (success) {
      messenger.showSnackBar(const SnackBar(content: Text('프로필을 수정했어요.')));
      await _popWithoutConfirmation();
    } else if (viewModel.message != null) {
      messenger.showSnackBar(SnackBar(content: Text(viewModel.message!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthViewModel, String?>(
      (auth) => auth.member?.email,
    );
    final viewModel = context.watch<EditProfileViewModel>();
    final saving = viewModel.status == EditProfileStatus.saving;
    final textTheme = Theme.of(context).textTheme;
    const background = Color(0xFFFEFCF9);

    return PopScope(
      canPop: !saving && (!_hasChanges || _allowPop),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !saving && !_allowPop && _hasChanges) _requestBack();
      },
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          centerTitle: true,
          leading: IconButton(
            tooltip: '뒤로 가기',
            onPressed: saving ? null : _requestBack,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            '프로필 수정',
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.primary600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 48),
                        Text('이메일 (변경할 수 없습니다)', style: textTheme.bodySmall),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: email,
                          enabled: false,
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: AppColors.secondary100,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text('닉네임', style: textTheme.bodySmall),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nickname,
                          enabled: !saving,
                          maxLength: 12,
                          onChanged: (_) {
                            setState(() {});
                            viewModel.onNicknameChanged();
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.white,
                            errorText: viewModel.nicknameError,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                MovieLogButton(
                  label: '저장',
                  width: double.infinity,
                  isLoading: saving,
                  onPressed: saving ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
