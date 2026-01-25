/// Buddy FAB Widget
///
/// A floating paw button that triggers the Buddy popup.
/// The avatar emerges from this sphere with a scale animation.
library;

import 'package:flutter/material.dart';
import 'buddy_popup.dart';

/// Floating Paw Button for Buddy
class BuddyFab extends StatefulWidget {
  const BuddyFab({super.key});

  @override
  State<BuddyFab> createState() => _BuddyFabState();
}

class _BuddyFabState extends State<BuddyFab> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showBuddyPopup() {
    // Get the position of this FAB for the popup to emerge from
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final position = renderBox?.localToGlobal(Offset.zero);
    final size = renderBox?.size;

    showBuddyPopupFromFab(
      context,
      fabPosition: position,
      fabSize: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect background
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          // The main FAB button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showBuddyPopup,
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFDBEAFE),
                      Color(0xFFBFDBFE),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cat ears represented as small shapes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Paw icon
                    const Icon(
                      Icons.pets,
                      size: 32,
                      color: Color(0xFF3B82F6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
