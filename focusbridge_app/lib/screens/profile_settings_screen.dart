import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:focusbridge_app/widgets/app_bottom_nav.dart';
import 'package:focusbridge_app/services/auth_service.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _birthCtrl = TextEditingController();
  DateTime? _birthDate;
  File? _avatarFile;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  Future<void> _initProfile() async {
    final token = await AuthService.getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('尚未登入，無法載入個人資料')),
        );
      }
      return;
    }

    try {
      // 取得使用者ID
      final userIdFromToken = await AuthService.getCurrentUserId();
      if (userIdFromToken != null) {
        _userId = userIdFromToken;
        debugPrint('Current userId: $_userId');

        // 有了 userId，現在可以安全地載入個人資料
        await _loadSavedProfile();
        await _loadProfileFromBackend();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('使用者資訊無效，請重新登入')),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ 獲取使用者資訊時發生錯誤: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無法取得使用者資訊，請重新登入')),
        );
      }
    }
  }

  Future<void> _loadSavedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _nameCtrl.text = prefs.getString('profile_name_$_userId') ?? '';
    _genderCtrl.text = prefs.getString('profile_gender_$_userId') ?? '';
    final birthString = prefs.getString('profile_birth_$_userId') ?? '';
    if (birthString.isNotEmpty) {
      _birthDate = DateTime.tryParse(birthString);
      if (_birthDate != null) {
        _birthCtrl.text = '${_birthDate!.year}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.day.toString().padLeft(2, '0')}';
      }
    }
    final avatarPath = prefs.getString('profile_avatar_$_userId') ?? '';
    if (avatarPath.isNotEmpty && File(avatarPath).existsSync()) {
      _avatarFile = File(avatarPath);
    }
    setState(() {});
  }

  Future<void> _loadProfileFromBackend() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || _userId == null) return;

      final url = Uri.parse('http://140.131.115.111:8000/api/moodlogs/$_userId/');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final prefs = await SharedPreferences.getInstance();
        
        // 更新 UI
        _nameCtrl.text = data['name'] ?? '';
        _genderCtrl.text = data['gender'] ?? '';
        final birthString = data['birth'] ?? '';
        if (birthString.isNotEmpty) {
          _birthDate = DateTime.tryParse(birthString);
          if (_birthDate != null) {
            _birthCtrl.text = '${_birthDate!.year}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.day.toString().padLeft(2, '0')}';
            await prefs.setString('profile_birth_$_userId', _birthDate!.toIso8601String());
          }
        }
        
        // 儲存到本地
        await prefs.setString('profile_name_$_userId', _nameCtrl.text);
        await prefs.setString('profile_gender_$_userId', _genderCtrl.text);
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ 從後端獲取個人資料失敗: $e');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _genderCtrl.dispose();
    _birthCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _avatarFile = File(file.path));
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthCtrl.text = '${_birthDate!.year}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('尚未取得使用者資訊，請重新登入')),
        );
      }
      return;
    }

    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('尚未登入');

      final url = Uri.parse('http://140.131.115.111:8000/api/moodlogs/$_userId/');
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': _nameCtrl.text.trim(),
          'gender': _genderCtrl.text.isNotEmpty ? _genderCtrl.text : null,
          'birth': _birthDate?.toIso8601String().split('T')[0], // 確保是 YYYY-MM-DD 格式
        }),
      );

      if (response.statusCode == 200) {
        // 同步成功，儲存到本地
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_name_$_userId', _nameCtrl.text.trim());
        await prefs.setString('profile_gender_$_userId', _genderCtrl.text);
        if (_birthDate != null) {
          await prefs.setString('profile_birth_$_userId', _birthDate!.toIso8601String());
        }
        if (_avatarFile != null && _avatarFile!.existsSync()) {
          await prefs.setString('profile_avatar_$_userId', _avatarFile!.path);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('個人資料已同步至後端')),
          );
        }
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        String errorMsg = '同步失敗';
        if (errorBody is Map && errorBody.containsKey('detail')) {
          errorMsg = errorBody['detail'];
        } else {
          errorMsg = errorBody.toString();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('同步失敗：$errorMsg')),
          );
        }
        debugPrint('❌ 上傳後端失敗：${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發送請求錯誤：$e')),
        );
      }
      debugPrint('❌ 發送請求錯誤：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('個人資料設定'),
        backgroundColor: const Color(0xFF9CAF88),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                  child: _avatarFile == null
                      ? const Icon(Icons.camera_alt, size: 32)
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: '姓名',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? '請輸入姓名' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _genderCtrl,
                decoration: const InputDecoration(
                  labelText: '性別',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _birthCtrl,
                decoration: const InputDecoration(
                  labelText: '生日',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _pickBirthDate,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9CAF88),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    '儲存變更',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}