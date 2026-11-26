import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_text_styles.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../widgets/movielog_button.dart';

/// 프로필 수정 (/my/profile/edit). 이메일은 읽기 전용, 닉네임만 수정한다.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final member = context.read<AuthViewModel>().member;
    _controller = TextEditingController(text: member?.nickname ?? '');
    _controller.addListener(() => setState(() {})); // dirty 여부 갱신
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final viewModel = context.read<EditProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await viewModel.save(_controller.text);
    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(const SnackBar(content: Text('프로필을 수정했어요.')));
      navigator.pop(); // 마이페이지에는 새 닉네임이 이미 반영돼 있다.
    } else if (viewModel.message != null) {
      messenger.showSnackBar(SnackBar(content: Text(viewModel.message!)));
    }
  }

  /// (Challenge) 변경 내용이 있을 때 뒤로가기 확인
  Future<void> _confirmLeave() async {
    final navigator = Navigator.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('수정을 그만둘까요?'),
        content: const Text('저장하지 않은 변경 내용은 사라집니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('계속 수정'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthViewModel, String?>(
      (auth) => auth.member?.email,
    );

    return Consumer<EditProfileViewModel>(
      builder: (context, viewModel, child) {
        final saving = viewModel.isSaving;
        final dirty = viewModel.isDirty(_controller.text);
        return PopScope(
          // 저장 중이거나 변경 내용이 있으면 바로 나가지 않는다.
          canPop: !saving && !dirty,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop || saving) return;
            _confirmLeave();
          },
          child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: const Text('프로필 수정', style: AppTextStyles.appBarTitle),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: email,
                      enabled: false, // 이메일은 읽기 전용
                      decoration: const InputDecoration(
                        labelText: '이메일',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      enabled: !saving,
                      maxLength: 12,
                      onChanged: (_) => viewModel.onNicknameChanged(),
                      onSubmitted: (_) => saving ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: '닉네임',
                        border: const OutlineInputBorder(),
                        // 길이·중복(MEMBER409_1) 오류는 필드 아래에, 입력값은 유지
                        errorText: viewModel.nicknameError,
                      ),
                    ),
                    const Spacer(),
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
      },
    );
  }
}
