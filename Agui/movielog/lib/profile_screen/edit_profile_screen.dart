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

  @override
  void initState() {
    super.initState();
    _nickname = TextEditingController(
      text: context.read<AuthViewModel>().member?.nickname ?? '',
    );
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final viewModel = context.read<EditProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final success = await viewModel.save(_nickname.text);
    if (!mounted) return;
    if (success) {
      messenger.showSnackBar(const SnackBar(content: Text('프로필을 수정했어요.')));
      router.pop();
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
      canPop: !saving,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          centerTitle: true,
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
                          onChanged: (_) => viewModel.onNicknameChanged(),
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
