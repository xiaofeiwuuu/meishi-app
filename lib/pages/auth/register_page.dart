import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nickname = TextEditingController();
  final _code = TextEditingController();

  bool _loading = false;
  bool _sent = false; // 是否已进入验证码步骤

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _nickname.dispose();
    _code.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    final pwd = _password.text;
    if (email.isEmpty || pwd.length < 6) {
      _toast('请输入邮箱和至少 6 位密码');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().register(email, pwd, _nickname.text.trim());
      setState(() => _sent = true);
      _toast('验证码已发送到邮箱');
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length != 6) {
      _toast('请输入 6 位验证码');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().verifyEmail(_email.text.trim(), code);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst); // 回到根,AuthGate 切主页
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await context.read<AuthService>().resendCode(_email.text.trim());
      _toast('验证码已重新发送');
    } catch (e) {
      _toast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_sent ? '验证邮箱' : '注册')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: _sent ? _buildVerifyStep() : _buildFormStep(),
        ),
      ),
    );
  }

  Widget _buildFormStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: _dec('邮箱', Icons.email_outlined)),
        const SizedBox(height: 16),
        TextField(
            controller: _password,
            obscureText: true,
            decoration: _dec('密码(至少 6 位)', Icons.lock_outline)),
        const SizedBox(height: 16),
        TextField(
            controller: _nickname,
            decoration: _dec('昵称(可选)', Icons.person_outline)),
        const SizedBox(height: 24),
        _primaryButton('发送验证码', _loading ? null : _sendCode),
      ],
    );
  }

  Widget _buildVerifyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('验证码已发送至 ${_email.text.trim()}',
            style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 24),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: _dec('6 位验证码', Icons.pin_outlined),
        ),
        const SizedBox(height: 8),
        _primaryButton('验证并登录', _loading ? null : _verify),
        const SizedBox(height: 8),
        TextButton(onPressed: _resend, child: const Text('没收到?重新发送')),
      ],
    );
  }

  Widget _primaryButton(String text, VoidCallback? onPressed) => FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFFD93D),
          foregroundColor: const Color(0xFF5D4E37),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: onPressed,
        child: _loading
            ? const SizedBox(
                height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(text, style: const TextStyle(fontSize: 16)),
      );

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );
}
