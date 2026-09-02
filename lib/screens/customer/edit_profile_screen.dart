import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _client = Supabase.instance.client;
  final _uuid = const Uuid();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  XFile? _newAvatar;
  Uint8List? _newAvatarBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().profile;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 512);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _newAvatar = picked;
        _newAvatarBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    String? avatarUrl;
    if (_newAvatar != null && _newAvatarBytes != null) {
      try {
        final profileId = context.read<AuthProvider>().profile?.id;
        final fileName = '${_uuid.v4()}.jpg';
        final path = '$profileId/$fileName'; // أول جزء لازم يكون الـ user id بالظبط عشان الـ RLS تسمح بالرفع
        await _client.storage.from('avatars').uploadBinary(
              path,
              _newAvatarBytes!,
              fileOptions: FileOptions(upsert: true, contentType: _newAvatar!.mimeType ?? 'image/jpeg'),
            );
        avatarUrl = _client.storage.from('avatars').getPublicUrl(path);
      } catch (e) {
        if (mounted) {
          final isArabic = context.read<LocaleProvider>().isArabic;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isArabic ? 'فشل رفع الصورة: $e' : 'Failed to upload image: $e')),
          );
          setState(() => _isSaving = false);
        }
        return;
      }
    }

    try {
      await _authService.updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        avatarUrl: avatarUrl,
      );

      if (mounted) {
        await context.read<AuthProvider>().refreshProfile();
        setState(() => _isSaving = false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final isArabic = context.read<LocaleProvider>().isArabic;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isArabic ? 'فشل حفظ البيانات: $e' : 'Failed to save: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final profile = context.watch<AuthProvider>().profile;

    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'تعديل البروفايل' : 'Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFFF2F2F3),
                      backgroundImage: _newAvatarBytes != null
                          ? MemoryImage(_newAvatarBytes!) as ImageProvider
                          : (profile?.avatarUrl != null ? CachedNetworkImageProvider(profile!.avatarUrl!) : null),
                      child: (_newAvatarBytes == null && profile?.avatarUrl == null)
                          ? const Icon(Icons.person, size: 44, color: Colors.black38)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: const Color(0xFF1A1A1A),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _pickAvatar,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: isArabic ? 'الاسم بالكامل' : 'Full Name'),
                validator: (v) => (v == null || v.isEmpty) ? (isArabic ? 'مطلوب' : 'Required') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: isArabic ? 'رقم الهاتف' : 'Phone Number'),
                validator: (v) => (v == null || v.length < 8) ? (isArabic ? 'رقم غير صحيح' : 'Invalid phone') : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isArabic ? 'حفظ' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}