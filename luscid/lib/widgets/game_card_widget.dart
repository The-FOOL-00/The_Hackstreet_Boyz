/// Game card widget with flip animation
///
/// Animated card for memory match game with smooth 500ms rotation.
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
      duration: const Duration(milliseconds: 500),
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

  Widget _buildFrontSide() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.card.isMatched
            ? AppColors.accentGreen.withOpacity(0.2)
            : AppColors.cardFront,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.card.isMatched
              ? AppColors.accentGreen
              : AppColors.borderMedium,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.card.symbol,
          style: TextStyle(fontSize: widget.size * 0.5),
        ),
      ),
    );
  }

  Widget _buildBackSide() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlueDark, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.psychology,
          size: widget.size * 0.4,
          color: AppColors.textOnPrimary.withOpacity(0.8),
        ),
      ),
    );
  }
}
