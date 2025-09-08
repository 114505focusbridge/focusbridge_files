import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusbridge_app/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _password2Controller = TextEditingController();

  bool _isLoading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _errorMessage;

  // Tap recognizer for privacy link
  late final TapGestureRecognizer _privacyTap;
  static const String _privacyUrl = 'https://example.com/privacy';

  static const Color primaryGreen = Color.fromARGB(255, 152, 214, 87);

  @override
  void initState() {
    super.initState();
    _privacyTap = TapGestureRecognizer()
      ..onTap = () {
        _openPrivacyPolicy();
      };
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(_privacyUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無法開啟隱私權政策連結')),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEEF7ED),
              Color(0xFFDAF0D9),
            ],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 28),
                  const Text(
                    '建立新帳號',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '請填寫以下資料完成註冊',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 28),

                  // 毛玻璃卡片
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          width: size.width > 560 ? 520 : double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color.fromARGB(146, 146, 255, 30).withOpacity(0.16),
                                primaryGreen.withOpacity(0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 200),
                                  child: _errorMessage == null
                                      ? const SizedBox.shrink()
                                      : Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          margin: const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: const [
                                              Icon(Icons.error_outline, color: Colors.redAccent),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '註冊失敗',
                                                  style: TextStyle(color: Colors.redAccent),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 6),
                                _buildTextField(
                                  controller: _usernameController,
                                  label: '使用者名稱',
                                  hint: '請輸入帳號',
                                  icon: Icons.person_outline,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? '請輸入使用者名稱' : null,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  controller: _emailController,
                                  label: '電子郵件 (可選)',
                                  hint: '請輸入電子郵件',
                                  icon: Icons.email_outlined,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  controller: _passwordController,
                                  label: '密碼',
                                  hint: '請輸入密碼',
                                  icon: Icons.lock_outline,
                                  obscure: _obscure1,
                                  suffix: IconButton(
                                    icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility),
                                    color: Colors.black54,
                                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return '請輸入密碼';
                                    if (v.length < 6) return '密碼至少 6 位';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  controller: _password2Controller,
                                  label: '確認密碼',
                                  hint: '請再次輸入密碼',
                                  icon: Icons.lock_outline,
                                  obscure: _obscure2,
                                  suffix: IconButton(
                                    icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility),
                                    color: Colors.black54,
                                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                                  ),
                                  validator: (v) => (v == null || v.isEmpty) ? '請再次輸入密碼' : null,
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                            setState(() => _errorMessage = null);
                                            if (_formKey.currentState!.validate()) {
                                              final pw1 = _passwordController.text;
                                              final pw2 = _password2Controller.text;
                                              if (pw1 != pw2) {
                                                setState(() => _errorMessage = '兩次密碼輸入不一致');
                                                return;
                                              }
                                              setState(() => _isLoading = true);
                                              try {
                                                await authProvider.register(
                                                  _usernameController.text.trim(),
                                                  _emailController.text.trim(),
                                                  pw1,
                                                  pw2,
                                                );
                                                if (mounted) Navigator.pushReplacementNamed(context, '/home');
                                              } catch (err) {
                                                setState(() {
                                                  _errorMessage = err.toString();
                                                  _isLoading = false;
                                                });
                                              }
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryGreen,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      elevation: 6,
                                      shadowColor: Colors.black26,
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : const Text(
                                            '註冊',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('已有帳號？', style: TextStyle(color: Colors.black54)),
                                    TextButton(
                                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                                      child: const Text('登入'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 隱私權政策提示移到這裡
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                        children: [
                          const TextSpan(text: '註冊即表示你同意本服務的 '),
                          TextSpan(
                            text: '隱私權政策',
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: _privacyTap,
                          ),
                          const TextSpan(text: '。'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }
}
