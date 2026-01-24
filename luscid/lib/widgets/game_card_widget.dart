/// Game card widget with flip animation
///
/// Stitch Design: Gradient back, rounded-2xl, psychology icon, smooth 500ms flip.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_card_model.dart';
import '../core/constants/colors.dart';

class GameCardWidget extends StatefulWidget {
  final GameCard card;
  final VoidCallback? onTap;
  final double size;
  final bool disabled;

  const GameCardWidget({
    super.key,
    required this.card,
    this.onTap,
    this.size = 80,
    this.disabled = false,
  });

  @override
  State<GameCardWidget> createState() => _GameCardWidgetState();
}

class _GameCardWidgetState extends State<GameCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _showFront = widget.card.isFlipped || widget.card.isMatched;
    if (_showFront) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(GameCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldShowFront = widget.card.isFlipped || widget.card.isMatched;
    if (shouldShowFront != _showFront) {
      _showFront = shouldShowFront;
      if (_showFront) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canTap =
        !widget.disabled &&
        !widget.card.isMatched &&
        !widget.card.isFlipped &&
        widget.onTap != null;

    return GestureDetector(
      onTap: canTap ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final showFrontSide = angle > math.pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showFrontSide
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _buildFrontSide(),
                  )
                : _buildBackSide(),
          );
        },
      ),
    );
  }

  /// Stitch: Revealed card - white bg, blue border, light overlay
  Widget _buildFrontSide() {
    final isMatched = widget.card.isMatched;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: isMatched ? AppColors.accentGreen.withOpacity(0.15) : AppColors.cardFront,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMatched ? AppColors.accentGreen : AppColors.cardBorder,
          width: 2,
        ),
        boxShadow: [
          if (isMatched)
            BoxShadow(
              color: AppColors.accentGreen.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Stack(
        children: [
          // Light blue overlay (Stitch: bg-blue-50/50)
          if (!isMatched)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardRevealedBg.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          // Symbol
          Center(
            child: Text(
              widget.card.symbol,
              style: TextStyle(fontSize: widget.size * 0.45),
            ),
          ),
        ],
      ),
    );
  }

  /// Stitch: Card back - gradient blue, psychology icon
  Widget _buildBackSide() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.cardBackGradientStart, AppColors.cardBackGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Hover overlay effect
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: null, // Parent handles tap
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Psychology icon (Stitch style)
          Center(
            child: Icon(
              Icons.psychology_rounded,
              size: widget.size * 0.35,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
