// lib/screens/login_screen.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focusbridge_app/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = false;
  bool _obscure = true;

  // Timer for auto-hiding error message
  Timer? _errorTimer;

  // Tap recognizer for privacy link (must dispose)
  late final TapGestureRecognizer _privacyTap;

  // 隱私權政策連結（改成你的真實網址）
  static const String _privacyUrl = 'https://example.com/privacy';

  @override
  void initState() {
    super.initState();
    // ← 在 initState 初始化 recognizer，訂閱 onTap
    _privacyTap = TapGestureRecognizer()
      ..onTap = () {
        _openPrivacyPolicy();
      };
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('saved_username') ?? '';
    final savedPass = prefs.getString('saved_password') ?? '';

    if (savedUser.isNotEmpty && savedPass.isNotEmpty) {
      setState(() {
        _usernameController.text = savedUser;
        _passwordController.text = savedPass;
        _rememberMe = true;
      });
    }
  }

  Future<void> _attemptLogin() async {
    final authProvider = context.read<AuthProvider>();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    // local validation
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_username', username);
        await prefs.setString('saved_password', password);
      } else {
        await prefs.remove('saved_username');
        await prefs.remove('saved_password');
      }

      await authProvider.login(username, password);

      // 登入成功，取消任何錯誤顯示 timer
      _errorTimer?.cancel();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (err) {
      // 固定顯示「帳號或密碼錯誤」，並顯示 5 秒後自動消失
      setState(() {
        _errorMessage = '帳號或密碼錯誤';
        _isLoading = false;
      });

      // 取消舊的 timer（若存在），然後重新啟動 5 秒倒數
      _errorTimer?.cancel();
      _errorTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(_privacyUrl);
    // 使用外部瀏覽器開啟
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
    _passwordController.dispose();
    _errorTimer?.cancel();
    // ← 在 dispose 裡釋放 recognizer，避免 memory leak 或下次使用出錯
    _privacyTap.dispose();
    super.dispose();
  }

  // 主色（你原本用的綠色）
  static const Color primaryGreen = Color.fromARGB(255, 152, 214, 87);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // 漸層背景
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
          bottom: true,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: [
                // 中央內容
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      const SizedBox(height: 18),
                      // 標題
                      const Text(
                        '歡迎回來',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '輸入帳號密碼以登入',
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
                                // 這裡使用帶綠的半透明漸層
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color.fromARGB(146, 146, 255, 30).withOpacity(0.16),
                                    primaryGreen.withOpacity(0.06),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                // subtle border to enhance softness (almost invisible)
                                border: Border.all(color: Colors.white.withOpacity(0.06)),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // 錯誤訊息（動畫顯示）——固定文字並會自動在 5 秒後隱藏
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
                                                      '帳號或密碼錯誤',
                                                      style: TextStyle(color: Colors.redAccent),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),

                                    // username
                                    _buildTextField(
                                      controller: _usernameController,
                                      label: '帳號',
                                      hint: '請輸入帳號或 Email',
                                      icon: Icons.person_outline,
                                      validator: (v) => (v == null || v.trim().isEmpty) ? '請輸入使用者名稱' : null,
                                    ),
                                    const SizedBox(height: 12),

                                    // password
                                    _buildTextField(
                                      controller: _passwordController,
                                      label: '密碼',
                                      hint: '請輸入密碼',
                                      icon: Icons.lock_outline,
                                      obscure: _obscure,
                                      suffix: IconButton(
                                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                        color: Colors.black54,
                                        onPressed: () => setState(() => _obscure = !_obscure),
                                      ),
                                      validator: (v) => (v == null || v.isEmpty) ? '請輸入密碼' : null,
                                    ),

                                    const SizedBox(height: 6),

                                    // 記住我 + 忘記密碼（左右排）
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Transform.scale(
                                              scale: 0.9,
                                              child: Switch.adaptive(
                                                value: _rememberMe,
                                                onChanged: (val) => setState(() => _rememberMe = val),
                                                activeColor: const Color.fromARGB(255, 152, 214, 87),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Text('記住我'),
                                          ],
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
                                          child: const Text('忘記密碼？'),
                                          style: TextButton.styleFrom(
                                          //foregroundColor: Colors.black54,
                                          textStyle: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    // 登入按鈕（圓角）——在 loading 時顯示按鈕內 spinner 並禁用按鈕
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _attemptLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryGreen,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          elevation: 6,
                                          shadowColor: Colors.black26,
                                        ),
                                        child: _isLoading
                                            ? Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: const [
                                                  SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.2,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text('登入中...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                                ],
                                              )
                                            : const Text(
                                                '登入',
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                              ),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // OR divider
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(color: Colors.black.withOpacity(0.06)),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 10),
                                          child: Text(
                                            '或',
                                            style: TextStyle(color: Colors.black54),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(color: Colors.black.withOpacity(0.06)),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    // 註冊鏈結
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('還沒有帳號？', style: TextStyle(color: Colors.black54)),
                                        TextButton(
                                          onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                                          child: const Text('註冊'),
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

                      const SizedBox(height: 24),

                      // 底部的小提示（可刪或保留）
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          'All Day HD 幫您記錄每日心情，讓您更了解自己的情緒。',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),

                // —— 已移除全螢幕黑色 loading overlay —— 
              ],
            ),
          ),
        ),
      ),
    );
  }

  // helper: text field with icon and optional suffix widget
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
