import 'dart:ui';
import 'package:flutter/material.dart';

class BlurOnBackground extends StatefulWidget {
  final Widget child;
  const BlurOnBackground({super.key, required this.child});

  @override
  State<BlurOnBackground> createState() => _BlurOnBackgroundState();
}

class _BlurOnBackgroundState extends State<BlurOnBackground>
    with WidgetsBindingObserver {
  bool _isBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isBackgrounded =
          state == AppLifecycleState.inactive ||
          state == AppLifecycleState.paused;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isBackgrounded)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(color: Colors.black.withAlpha(150)),
            ),
          ),
      ],
    );
  }
}
