import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
  late final AuthViewModel _auth;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthViewModel>();
    _auth.addListener(_showExpired);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showExpired());
  }

  void _showExpired() {
    if (!mounted || !_auth.sessionExpired) return;
    _auth.consumeSessionExpired();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')));
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
    final enabled = !loading && !auth.storageCleanupInProgress;
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
                const SizedBox(height: 100),
                MovieLogButton(
                  label: '로그인',
                  isLoading: loading,
                  onPressed: enabled
                      ? () {
                          if (_formKey.currentState!.validate()) {
                            _auth.login(_email.text, _password.text);
                          }
                        }
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
