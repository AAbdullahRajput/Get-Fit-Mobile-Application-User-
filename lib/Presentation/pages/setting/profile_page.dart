import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_fit/Presentation/widgets/validated_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

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

  // Track what's actually saved in the DB, to know if a field is "dirty"
  String _originalName = '';
  String _originalMobile = '';
  String _originalWeight = '';
  String _originalHeight = '';

  bool _savingName = false;
  bool _savingMobile = false;
  bool _savingWeight = false;
  bool _savingHeight = false;
  bool _savingPhoto = false;

  final _nameFieldKey = GlobalKey<ValidatedTextFieldState>();
  final _mobileFieldKey = GlobalKey<ValidatedTextFieldState>();
  final _weightFieldKey = GlobalKey<ValidatedTextFieldState>();
  final _heightFieldKey = GlobalKey<ValidatedTextFieldState>();

  String? _validateName(String v) {
    if (v.trim().isEmpty) return 'Name is required';
    if (v.trim().length < 3) return 'Name must be at least 3 characters';
    return null;
  }

  String? _validateMobile(String v) {
    if (v.isEmpty) return 'Mobile number is required';
    if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
      return 'Digits only — no letters or symbols';
    }
    if (v.length > 11) return 'Maximum 11 digits allowed';
    if (v.length < 10) return 'Enter a valid 10-11 digit number';
    return null;
  }

  String? _validateWeight(String v) {
    if (v.isEmpty) return null; // optional field
    final n = int.tryParse(v);
    if (n == null) return 'Numbers only';
    if (n < 20 || n > 300) return 'Enter a realistic weight (20-300 kg)';
    return null;
  }

  String? _validateHeight(String v) {
    if (v.isEmpty) return null; // optional field
    final n = int.tryParse(v);
    if (n == null) return 'Numbers only';
    if (n < 50 || n > 250) return 'Enter a realistic height (50-250 cm)';
    return null;
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _mobileController.addListener(() => setState(() {}));
    _weightController.addListener(() => setState(() {}));
    _heightController.addListener(() => setState(() {}));
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
      _originalName = _nameController.text;
      _originalMobile = _mobileController.text;
      _originalWeight = _weightController.text;
      _originalHeight = _heightController.text;
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

  Future<void> _savePhoto() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null || _pickedImageBytes == null) return;
    setState(() => _savingPhoto = true);
    try {
      final newAvatarUrl = await SupabaseService.uploadAvatar(
        userId,
        _pickedImageBytes!,
        'avatar.jpg',
      );
      await SupabaseService.updateUserProfile(
        userId: userId,
        data: {'avatar_url': newAvatarUrl},
      );
      if (!mounted) return;
      setState(() {
        _avatarUrl = newAvatarUrl;
        _pickedImageBytes = null;
        _savingPhoto = false;
      });
      imageCache.clear();
      imageCache.clearLiveImages();
      _showSuccessDialog('Photo Updated!', 'Your profile photo has been updated.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingPhoto = false);
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _saveName(String value) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;
    setState(() => _savingName = true);
    try {
      await SupabaseService.updateUserProfile(
        userId: userId,
        data: {'username': value},
      );
      if (!mounted) return;
      setState(() {
        _originalName = value;
        _savingName = false;
      });
      _showSuccessDialog('Name Updated!', 'Your name has been updated successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingName = false);
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _saveMobile(String value) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;
    setState(() => _savingMobile = true);
    try {
      await SupabaseService.updateUserProfile(
        userId: userId,
        data: {'mobile_no': value},
      );
      if (!mounted) return;
      setState(() {
        _originalMobile = value;
        _savingMobile = false;
      });
      _showSuccessDialog('Mobile Updated!', 'Your mobile number has been updated successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingMobile = false);
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _saveWeight(String value) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;
    setState(() => _savingWeight = true);
    try {
      await SupabaseService.saveUserSetup(
        userId: userId,
        data: {'weight': int.tryParse(value)},
      );
      if (!mounted) return;
      setState(() {
        _originalWeight = value;
        _savingWeight = false;
      });
      _showSuccessDialog('Weight Updated!', 'Your weight has been updated successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingWeight = false);
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _saveHeight(String value) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;
    setState(() => _savingHeight = true);
    try {
      await SupabaseService.saveUserSetup(
        userId: userId,
        data: {'height': int.tryParse(value)},
      );
      if (!mounted) return;
      setState(() {
        _originalHeight = value;
        _savingHeight = false;
      });
      _showSuccessDialog('Height Updated!', 'Your height has been updated successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingHeight = false);
      _showErrorDialog(e.toString());
    }
  }

  void _showSuccessDialog([String title = 'Profile Updated!', String message = 'Your profile has been updated successfully.']) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF4A5240),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle_outline,
            color: Color(0xFFDBF500), size: 48),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
                                    : (_avatarUrl != null &&
                                            _avatarUrl!.isNotEmpty &&
                                            !_avatarUrl!.contains('example.com')
                                        ? NetworkImage(_avatarUrl!)
                                        : null) as ImageProvider?,
                                onBackgroundImageError: (_pickedImageBytes == null &&
                                        _avatarUrl != null &&
                                        _avatarUrl!.isNotEmpty &&
                                        !_avatarUrl!.contains('example.com'))
                                    ? (exception, stackTrace) {
                                        debugPrint('[Avatar] Failed to load: $_avatarUrl');
                                      }
                                    : null,
                                child: (_pickedImageBytes == null &&
                                        (_avatarUrl == null ||
                                            _avatarUrl!.isEmpty ||
                                            _avatarUrl!.contains('example.com')))
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
        if (_pickedImageBytes != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _savingPhoto ? null : _savePhoto,
                icon: _savingPhoto
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.check, color: Colors.black),
                label: Text(_savingPhoto ? 'Saving...' : 'Save New Photo',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ),

        _buildEditableField(
          label: 'Full Name',
          icon: Icons.person_outline,
          controller: _nameController,
          fieldKey: _nameFieldKey,
          validator: _validateName,
          originalValue: _originalName,
          isSaving: _savingName,
          onSave: _saveName,
        ),

        // Email — read-only, no save button needed
        _buildField('Email', null, Icons.email_outlined,
            value: _email, enabled: false),

        _buildEditableField(
          label: 'Mobile Number',
          icon: Icons.phone_outlined,
          controller: _mobileController,
          fieldKey: _mobileFieldKey,
          validator: _validateMobile,
          originalValue: _originalMobile,
          isSaving: _savingMobile,
          onSave: _saveMobile,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 11,
        ),

        _buildEditableField(
          label: 'Weight (kg)',
          icon: Icons.monitor_weight_outlined,
          controller: _weightController,
          fieldKey: _weightFieldKey,
          validator: _validateWeight,
          originalValue: _originalWeight,
          isSaving: _savingWeight,
          onSave: _saveWeight,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),

        _buildEditableField(
          label: 'Height (cm)',
          icon: Icons.height_outlined,
          controller: _heightController,
          fieldKey: _heightFieldKey,
          validator: _validateHeight,
          originalValue: _originalHeight,
          isSaving: _savingHeight,
          onSave: _saveHeight,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),

        const SizedBox(height: 10),
      ],
    );
  }

  /// A field with its own Save button — enabled only when the value has
  /// actually changed from what's stored and passes validation. Tapping
  /// Save updates ONLY this field in the database, nothing else.
  Widget _buildEditableField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required GlobalKey<ValidatedTextFieldState> fieldKey,
    required String? Function(String) validator,
    required String originalValue,
    required bool isSaving,
    required Future<void> Function(String newValue) onSave,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    final isDirty = controller.text.trim() != originalValue.trim();
    final currentError = validator(controller.text);
    final canSave = isDirty && currentError == null && !isSaving;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ValidatedTextField(
              key: fieldKey,
              controller: controller,
              hint: label,
              icon: icon,
              validator: validator,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              maxLength: maxLength,
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: !canSave
                    ? null
                    : () async {
                        final err = fieldKey.currentState?.validateForSubmit();
                        if (err != null) return;
                        await onSave(controller.text.trim());
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  disabledBackgroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Icon(Icons.check,
                        color: canSave ? Colors.black : Colors.grey.shade400),
              ),
            ),
          ),
        ],
      ),
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