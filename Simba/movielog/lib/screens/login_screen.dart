import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/storage/email_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';

/// 로그인 화면. login()만 호출하고 화면 이동은 하지 않는다.
/// (status가 signedIn이 되면 Router가 /home으로 보낸다)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialEmail});

  /// 회원가입 직후 넘어온 이메일
  final String? initialEmail;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _password = TextEditingController();
  late final AuthViewModel _auth;
  late final EmailPreferences _emailPrefs;

  bool _rememberEmail = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail ?? '');
    _auth = context.read<AuthViewModel>();
    _emailPrefs = context.read<EmailPreferences>();
    // 화면이 열려 있는 동안 만료되는 경우 + 이미 만료된 상태로 열리는 경우를 모두 처리
    _auth.addListener(_showSessionExpired);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSessionExpired());
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final saved = await _emailPrefs.readSavedEmail();
    if (!mounted || saved == null || saved.isEmpty) return;
    setState(() {
      _rememberEmail = true;
      if (_email.text.isEmpty) _email.text = saved;
    });
  }

  /// 만료로 쫓겨난 경우에만 한 번 안내한다. (직접 로그아웃·로그인 실패는 제외)
  void _showSessionExpired() {
    if (!mounted || !_auth.sessionExpired) return;
    _auth.consumeSessionExpired(); // 먼저 꺼서 반복 표시를 막는다.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    // (Challenge) 이메일만 저장한다. 비밀번호·토큰은 저장하지 않는다.
    if (_rememberEmail) {
      await _emailPrefs.saveEmail(email);
    } else {
      await _emailPrefs.clear();
    }
    if (!mounted) return;
    await _auth.login(email, _password.text);
  }

  @override
  void dispose() {
    _auth.removeListener(_showSessionExpired);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final loading = auth.status == AuthStatus.authenticating;
    final enabled = !loading && !auth.storageCleanupInProgress;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('로그인', style: AppTextStyles.appBarTitle),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    SvgPicture.asset(
                      'assets/logos/movielog_logo.svg',
                      width: 72,
                      height: 72,
                      colorFilter: const ColorFilter.mode(
                        AppColors.violet,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'MovieLog에 로그인',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _email,
                      enabled: enabled,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: '이메일',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? '이메일을 입력해 주세요.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      enabled: enabled,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => enabled ? _submit() : null,
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          (value?.isEmpty ?? true) ? '비밀번호를 입력해 주세요.' : null,
                    ),
                    // (Challenge) 이메일 저장
                    CheckboxListTile(
                      value: _rememberEmail,
                      onChanged: enabled
                          ? (value) =>
                                setState(() => _rememberEmail = value ?? false)
                          : null,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.violet,
                      title: const Text('이메일 저장'),
                    ),
                    // 로그인 실패(AUTH401_1)·저장 실패 등은 Form 아래 문구로 보여준다.
                    if (auth.message != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          auth.message!,
                          style: const TextStyle(color: Color(0xFFD32F2F)),
                        ),
                      ),
                    const SizedBox(height: 16),
                    MovieLogButton(
                      label: '로그인',
                      width: double.infinity,
                      isLoading: loading,
                      onPressed: enabled ? _submit : null,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: enabled
                          ? () => context.push('/register')
                          : null,
                      child: const Text('아직 계정이 없나요? 회원가입'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
