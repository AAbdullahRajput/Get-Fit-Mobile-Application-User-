import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  Uint8List? _pickedImageBytes;
  String? _avatarUrl;

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.getUserProfile();
    if (mounted && data != null) {
      _nameController.text = data['username'] ?? '';
      _email = data['email'] ?? '';
      _mobileController.text = data['mobile_no'] ?? '';
      _dobController.text = data['age']?.toString() ?? '';
      _weightController.text = data['weight']?.toString() ?? '';
      _heightController.text = data['height']?.toString() ?? '';
      _avatarUrl = data['avatar_url'];
      setState(() => _isLoading = false);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _pickedImageBytes = bytes);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return;

      String? newAvatarUrl = _avatarUrl;

      if (_pickedImageBytes != null) {
        newAvatarUrl = await SupabaseService.uploadAvatar(
          userId,
          _pickedImageBytes!,
          'avatar.jpg',
        );
      }

      await SupabaseService.updateUserProfile(
  userId: userId,
  data: {
    'username': _nameController.text.trim(),
    'mobile_no': _mobileController.text.trim(),
    'avatar_url': newAvatarUrl,
  },
);

await SupabaseService.saveUserSetup(
  userId: userId,
  data: {
    'weight': int.tryParse(_weightController.text.trim()),
    'height': int.tryParse(_heightController.text.trim()),
  },
);

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _avatarUrl = newAvatarUrl;
        _isSaving = false;
      });

      if (newAvatarUrl != null) {
  imageCache.clear();
  imageCache.clearLiveImages();
}

      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showErrorDialog(e.toString());
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF4A5240),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle_outline,
            color: Color(0xFFDBF500), size: 48),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Profile Updated!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Your profile has been updated successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFDBF500),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('OK',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF4A5240),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.error_outline,
            color: Colors.redAccent, size: 48),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Update Failed',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message.replaceAll('PostgrestException: ', ''),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFDBF500),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('OK',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.bgColor,
      child: Stack(
        children: [
          RefreshIndicator(
            color: themeColor,
            backgroundColor: context.cardBgColor,
            displacement: 100,
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 20,
                      bottom: 40,
                    ),
                    decoration: const BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isEditing ? _pickImage : null,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.white,
                                backgroundImage: _pickedImageBytes != null
                                    ? MemoryImage(_pickedImageBytes!)
                                    : (_avatarUrl != null
                                        ? NetworkImage(_avatarUrl!)
                                        : null) as ImageProvider?,
                                child: (_pickedImageBytes == null &&
                                        _avatarUrl == null)
                                    ? Icon(Icons.person,
                                        size: 80, color: context.textColor)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    if (_isEditing) {
                                      _pickImage();
                                    } else {
                                      setState(() => _isEditing = true);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: themeColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/icons/pencil_icon.svg',
                                      width: 18,
                                      height: 18,
                                      colorFilter: const ColorFilter.mode(
                                          Colors.black, BlendMode.srcIn),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _nameController.text.isEmpty
                              ? 'Your Name'
                              : _nameController.text,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                      height: MediaQuery.of(context).padding.top + 60),

                  // Form
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _isLoading
                        ? _buildSkeleton(context)
                        : _buildForm(context),
                  ),
                ],
              ),
            ),
          ),

          // Stats bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 220,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? const Color(0xff414141)
                      : const Color(0xff1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _weightController.text.isEmpty
                                ? '--'
                                : '${_weightController.text} kg',
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text('Weight',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                        width: 1, height: 40, color: Colors.white54),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _dobController.text.isEmpty
                                ? '--'
                                : _dobController.text,
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text('Age',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                        width: 1, height: 40, color: Colors.white54),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _heightController.text.isEmpty
                                ? '--'
                                : '${_heightController.text} cm',
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text('Height',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Back + Edit buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(10),
                      backgroundColor: Colors.black54,
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      children: [
        _buildField('Full Name', _nameController,
            Icons.person_outline, enabled: _isEditing),
        _buildField('Email', null, Icons.email_outlined,
            value: _email, enabled: false),
        _buildField('Mobile Number', _mobileController,
            Icons.phone_outlined,
            enabled: _isEditing,
            keyboardType: TextInputType.phone),
        _buildField('Weight (kg)', _weightController,
            Icons.monitor_weight_outlined,
            enabled: _isEditing,
            keyboardType: TextInputType.number),
        _buildField('Height (cm)', _heightController,
            Icons.height_outlined,
            enabled: _isEditing,
            keyboardType: TextInputType.number),
        const SizedBox(height: 10),
        if (_isEditing)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.black),
                    )
                  : const Text(
                      'Update Profile',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController? controller,
    IconData icon, {
    bool enabled = true,
    String? value,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(12),
          border: enabled
              ? Border.all(color: themeColor, width: 1.5)
              : null,
        ),
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          initialValue: controller == null ? value : null,
          style: TextStyle(color: context.textColor),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: context.subtextColor),
            prefixIcon: Icon(icon, color: context.subtextColor),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                vertical: 14, horizontal: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Column(
      children: [
        ...List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ShimmerWidget(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: context.isDark
                      ? const Color(0xff3a3a3a)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

class _ShimmerWidget extends StatefulWidget {
  final Widget child;
  const _ShimmerWidget({required this.child});

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}