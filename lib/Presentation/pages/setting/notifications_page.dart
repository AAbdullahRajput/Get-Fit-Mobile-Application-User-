import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with WidgetsBindingObserver {
  bool _isLoading = true;

  bool _generalNotification = false;
  bool _sound = false;
  bool _dndMode = false;
  bool _vibrate = false;
  bool _lockScreen = false;
  bool _reminder = false;

  static const _kGeneral  = 'notif_general';
  static const _kSound    = 'notif_sound';
  static const _kDnd      = 'notif_dnd';
  static const _kVibrate  = 'notif_vibrate';
  static const _kLock     = 'notif_lock';
  static const _kReminder = 'notif_reminder';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPrefs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncGeneralWithPermission();
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final granted = await Permission.notification.isGranted;
    if (mounted) {
      setState(() {
        _generalNotification = granted && (prefs.getBool(_kGeneral) ?? false);
        _sound      = prefs.getBool(_kSound)    ?? false;
        _dndMode    = prefs.getBool(_kDnd)      ?? false;
        _vibrate    = prefs.getBool(_kVibrate)  ?? false;
        _lockScreen = prefs.getBool(_kLock)     ?? false;
        _reminder   = prefs.getBool(_kReminder) ?? false;
        _isLoading  = false;
      });
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kGeneral,  _generalNotification);
    await prefs.setBool(_kSound,    _sound);
    await prefs.setBool(_kDnd,      _dndMode);
    await prefs.setBool(_kVibrate,  _vibrate);
    await prefs.setBool(_kLock,     _lockScreen);
    await prefs.setBool(_kReminder, _reminder);
  }

  Future<void> _syncGeneralWithPermission() async {
    final granted = await Permission.notification.isGranted;
    if (!granted && _generalNotification) {
      setState(() {
        _generalNotification = false;
        _sound      = false;
        _dndMode    = false;
        _vibrate    = false;
        _lockScreen = false;
        _reminder   = false;
      });
      _savePrefs();
    }
  }

  Future<void> _toggleGeneral(bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        setState(() => _generalNotification = true);
        _savePrefs();
        _showSnack('Notifications enabled');
      } else if (status.isPermanentlyDenied) {
        _showPermissionDialog();
      } else {
        _showSnack('Notification permission denied');
      }
    } else {
      setState(() {
        _generalNotification = false;
        _sound      = false;
        _dndMode    = false;
        _vibrate    = false;
        _lockScreen = false;
        _reminder   = false;
      });
      _savePrefs();
      _showSnack('Notifications disabled');
    }
  }

  Future<void> _toggleSound(bool value) async {
    if (value && _dndMode) {
      _showSnack('Disable Do Not Disturb first');
      return;
    }
    setState(() => _sound = value);
    _savePrefs();
    _showSnack(value ? 'Notification sound on' : 'Notification sound off');
  }

  Future<void> _toggleDnd(bool value) async {
    setState(() {
      _dndMode = value;
      if (value) _sound = false;
    });
    _savePrefs();
    _showSnack(value
        ? 'Do Not Disturb enabled — sound muted'
        : 'Do Not Disturb disabled');
  }

  Future<void> _toggleVibrate(bool value) async {
    setState(() => _vibrate = value);
    _savePrefs();
    if (value) HapticFeedback.mediumImpact();
    _showSnack(value ? 'Vibration on' : 'Vibration off');
  }

  Future<void> _toggleLockScreen(bool value) async {
    setState(() => _lockScreen = value);
    _savePrefs();
    _showSnack(value
        ? 'Lock screen notifications on'
        : 'Lock screen notifications off');
  }

  Future<void> _toggleReminder(bool value) async {
    setState(() => _reminder = value);
    _savePrefs();
    _showSnack(value
        ? 'Reminders enabled — you\'ll be notified before classes'
        : 'Reminders disabled');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(
            color: isDark ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        backgroundColor: isDark ? themeColor : Colors.black,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  void _showPermissionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.cardBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Permission Required',
            style: TextStyle(
                color: context.textColor, fontWeight: FontWeight.bold)),
        content: Text(
          'Notifications are permanently blocked. Please enable them in your device settings.',
          style: TextStyle(color: context.subtextColor, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Open Settings',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 10),
              child: _isLoading
                  ? _buildSkeleton(context)
                  : _buildContent(context),
            ),
          ),

          // ── Back button ──
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2C)
                          : Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: isDark ? themeColor : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Title ──
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    color: isDark ? themeColor : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      _NotifItem(
        icon: Icons.notifications,
        iconColor: themeColor,
        title: 'General Notification',
        subtitle: 'Allow Get Fit to send you notifications',
        value: _generalNotification,
        onChanged: _toggleGeneral,
        enabled: true,
      ),
      _NotifItem(
        icon: Icons.volume_up,
        iconColor: Colors.blue,
        title: 'Sound',
        subtitle: _dndMode
            ? 'Disabled while Do Not Disturb is on'
            : 'Play sound when notifications arrive',
        value: _sound && !_dndMode,
        onChanged: _generalNotification ? _toggleSound : null,
        enabled: _generalNotification && !_dndMode,
      ),
      _NotifItem(
        icon: Icons.do_not_disturb_on,
        iconColor: Colors.orange,
        title: 'Do Not Disturb',
        subtitle: 'Silence all notifications temporarily',
        value: _dndMode,
        onChanged: _generalNotification ? _toggleDnd : null,
        enabled: _generalNotification,
      ),
      _NotifItem(
        icon: Icons.vibration,
        iconColor: Colors.purple,
        title: 'Vibrate',
        subtitle: 'Vibrate on incoming notifications',
        value: _vibrate,
        onChanged: _generalNotification ? _toggleVibrate : null,
        enabled: _generalNotification,
      ),
      _NotifItem(
        icon: Icons.lock,
        iconColor: Colors.teal,
        title: 'Lock Screen',
        subtitle: 'Show notifications on lock screen',
        value: _lockScreen,
        onChanged: _generalNotification ? _toggleLockScreen : null,
        enabled: _generalNotification,
      ),
      _NotifItem(
        icon: Icons.alarm,
        iconColor: Colors.red,
        title: 'Reminder',
        subtitle: 'Get reminded before upcoming yoga & trainer classes',
        value: _reminder,
        onChanged: _generalNotification ? _toggleReminder : null,
        enabled: _generalNotification,
      ),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // ── Warning banner ──
        if (!_generalNotification)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.info, color: Colors.orange, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Enable General Notification to unlock all settings.',
                  style: TextStyle(
                      color: isDark
                          ? Colors.orange.shade300
                          : Colors.orange.shade800,
                      fontSize: 13),
                ),
              ),
            ]),
          ),

        ...items.map((item) => _buildTile(context, item, isDark)),
      ],
    );
  }

  Widget _buildTile(BuildContext context, _NotifItem item, bool isDark) {
    final isActive = item.value && item.enabled;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? themeColor.withOpacity(isDark ? 0.4 : 0.3)
              : (isDark
                  ? Colors.grey.shade800.withOpacity(0.3)
                  : Colors.grey.shade200),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: item.enabled
                ? item.iconColor.withOpacity(isDark ? 0.18 : 0.12)
                : (isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            item.icon,
            color: item.enabled
                ? item.iconColor
                : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            size: 22,
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: item.enabled
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            item.subtitle,
            style: TextStyle(
              color: item.enabled
                  ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600)
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade400),
              fontSize: 12,
            ),
          ),
        ),
        trailing: Switch(
          value: item.value,
          onChanged: item.onChanged,
          activeColor: isDark ? Colors.black : Colors.white,
          activeTrackColor: themeColor,
          inactiveThumbColor:
              isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          inactiveTrackColor:
              isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _ShimmerWidget(
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xff2c2c2c)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotifItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool)? onChanged;
  final bool enabled;

  const _NotifItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.enabled,
  });
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
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _animation, child: widget.child);
}