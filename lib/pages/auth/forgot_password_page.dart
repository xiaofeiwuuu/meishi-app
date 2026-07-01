import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _send() async {
    if (_email.text.trim().isEmpty) {
      _toast('请输入邮箱');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().forgotPassword(_email.text.trim());
      setState(() => _sent = true);
      _toast('若邮箱已注册,验证码已发送');
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    if (_code.text.trim().length != 6 || _password.text.length < 6) {
      _toast('请输入 6 位验证码和至少 6 位新密码');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().resetPassword(
          _email.text.trim(), _code.text.trim(), _password.text);
      _toast('密码已重置,请用新密码登录');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('找回密码')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _email,
                enabled: !_sent,
                keyboardType: TextInputType.emailAddress,
                decoration: _dec('邮箱', Icons.email_outlined),
              ),
              if (_sent) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: _dec('6 位验证码', Icons.pin_outlined),
                ),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: _dec('新密码(至少 6 位)', Icons.lock_outline),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD93D),
                  foregroundColor: const Color(0xFF5D4E37),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed:
                    _loading ? null : (_sent ? _reset : _send),
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_sent ? '重置密码' : '发送验证码',
                        style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
