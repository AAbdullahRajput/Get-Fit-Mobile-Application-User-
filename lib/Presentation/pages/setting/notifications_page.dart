import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static bool _hasLoaded = false;
  bool _isLoading = true;

  final Map<String, bool> notificationSettings = {
    'General Notification': false,
    'Sound': false,
    'Don\'t Disturb Mode': false,
    'Vibrate': false,
    'Lock Screen': false,
    'Reminder': false,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_hasLoaded) {
      setState(() => _isLoading = false);
      return;
    }
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      _hasLoaded = true;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    _hasLoaded = false;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      _hasLoaded = true;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 10),
              child: RefreshIndicator(
                color: context.subtextColor,
                backgroundColor: context.cardBgColor,
                displacement: 100,
                onRefresh: _onRefresh,
                child: _isLoading
                    ? _buildSkeleton(context)
                    : _buildList(context),
              ),
            ),
          ),

          // Back button overlay
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(10),
                    backgroundColor: Colors.black54,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: notificationSettings.length,
      itemBuilder: (context, index) {
        String key = notificationSettings.keys.elementAt(index);
        return Card(
          color: context.cardBgColor,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              key,
              style: TextStyle(color: context.textColor, fontSize: 16),
            ),
            trailing: Switch(
              value: notificationSettings[key]!,
              onChanged: (bool value) {
                setState(() => notificationSettings[key] = value);
              },
              activeColor: themeColor,
              inactiveTrackColor:
                  context.isDark ? Colors.grey : Colors.grey.shade300,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: notificationSettings.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _ShimmerWidget(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: context.isDark
                    ? const Color(0xff3a3a3a)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
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