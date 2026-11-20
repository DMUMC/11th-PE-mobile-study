import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _preferences = SharedPreferencesAsync();
  static const _savedEmailKey = 'movielog.saved_email';
  bool _rememberEmail = false;
  bool _preferenceBusy = true;
  late final AuthViewModel _auth;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthViewModel>();
    _auth.addListener(_showExpired);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showExpired());
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    try {
      final savedEmail = await _preferences.getString(_savedEmailKey);
      if (!mounted) return;
      if (savedEmail != null && savedEmail.isNotEmpty) {
        _email.text = savedEmail;
        _rememberEmail = true;
      }
    } catch (_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장된 이메일을 불러오지 못했어요.')),
        );
      });
    } finally {
      if (mounted) setState(() => _preferenceBusy = false);
    }
  }

  Future<void> _setRememberEmail(bool value) async {
    if (value) {
      setState(() => _rememberEmail = true);
      return;
    }
    setState(() {
      _rememberEmail = false;
      _preferenceBusy = true;
    });
    try {
      await _preferences.remove(_savedEmailKey);
    } catch (_) {
      if (!mounted) return;
      setState(() => _rememberEmail = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장된 이메일을 삭제하지 못했어요. 다시 시도해 주세요.')),
      );
    } finally {
      if (mounted) setState(() => _preferenceBusy = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _email.text.trim();
    final password = _password.text;
    final rememberEmail = _rememberEmail;
    final version = _auth.sessionVersion + 1;
    final messenger = ScaffoldMessenger.of(context);
    await _auth.login(email, password);
    if (!rememberEmail || _auth.status != AuthStatus.signedIn ||
        _auth.sessionVersion != version) return;
    try {
      await _preferences.setString(_savedEmailKey, email);
    } catch (_) {
      if (messenger.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('이메일을 저장하지 못했어요.')),
        );
      }
    }
  }

  void _showExpired() {
    if (!mounted || !_auth.sessionExpired) return;
    _auth.consumeSessionExpired();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')),
      );
  }

  @override
  void dispose() {
    _auth.removeListener(_showExpired);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final loading = auth.status == AuthStatus.authenticating;
    final enabled = !loading && !auth.storageCleanupInProgress && !_preferenceBusy;
    final invalidCredentials = auth.message == '이메일 또는 비밀번호를 확인해 주세요.';
    return Scaffold(
      backgroundColor: const Color(0xFFFEFCF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEFCF9),
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('로그인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 88),
                Center(
                  child: SvgPicture.asset(
                    'assets/logos/movielog_logo.svg',
                    width: 56,
                    height: 56,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'MovieLog에 로그인',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                Text('이메일', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _email,
                  enabled: enabled,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (_) => _auth.clearLoginError(),
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'movie@example.com',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? '이메일을 입력해 주세요.' : null,
                ),
                const SizedBox(height: 20),
                Text('비밀번호', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _password,
                  enabled: enabled,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (_) => _auth.clearLoginError(),
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(),
                    errorText: invalidCredentials ? auth.message : null,
                  ),
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? '비밀번호를 입력해 주세요.' : null,
                ),
                if (auth.message != null && !invalidCredentials)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      auth.message!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberEmail,
                      onChanged: enabled
                          ? (value) => _setRememberEmail(value ?? false)
                          : null,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    const Text('이메일 저장'),
                  ],
                ),
                const SizedBox(height: 32),
                MovieLogButton(
                  label: '로그인',
                  isLoading: loading,
                  onPressed: enabled
                      ? _submit
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('계정이 없나요?'),
                    TextButton(
                      onPressed: enabled
                          ? () => context.push('/register')
                          : null,
                      child: const Text('회원가입'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
