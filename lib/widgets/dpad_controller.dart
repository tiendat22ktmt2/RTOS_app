import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class DPadController extends StatelessWidget {
  final void Function(String direction) onMove;
  final void Function() onStop;

  const DPadController({
    super.key,
    required this.onMove,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DPadButton(
          icon: Icons.keyboard_arrow_up_rounded,
          onPress: () => onMove('F'),
          label: 'Tiến',
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DPadButton(
              icon: Icons.keyboard_arrow_left_rounded,
              onPress: () => onMove('L'),
              label: 'Trái',
            ),
            const SizedBox(width: 8),
            _StopButton(onPress: onStop),
            const SizedBox(width: 8),
            _DPadButton(
              icon: Icons.keyboard_arrow_right_rounded,
              onPress: () => onMove('R'),
              label: 'Phải',
            ),
          ],
        ),
        const SizedBox(height: 8),
        _DPadButton(
          icon: Icons.keyboard_arrow_down_rounded,
          onPress: () => onMove('B'),
          label: 'Lùi',
        ),
      ],
    );
  }
}

class _DPadButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPress;
  final String label;

  const _DPadButton({
    required this.icon,
    required this.onPress,
    required this.label,
  });

  @override
  State<_DPadButton> createState() => _DPadButtonState();
}

class _DPadButtonState extends State<_DPadButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        HapticFeedback.lightImpact();
        widget.onPress();
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: _pressed ? AppTheme.accent : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _pressed ? AppTheme.accent : AppTheme.borderColor,
            width: _pressed ? 1.5 : 0.5,
          ),
          boxShadow: _pressed
              ? [BoxShadow(color: AppTheme.accentGlow, blurRadius: 12, spreadRadius: 2)]
              : null,
        ),
        child: Icon(
          widget.icon,
          color: _pressed ? Colors.white : AppTheme.textSecondary,
          size: 32,
        ),
      ),
    );
  }
}

class _StopButton extends StatefulWidget {
  final VoidCallback onPress;
  const _StopButton({required this.onPress});

  @override
  State<_StopButton> createState() => _StopButtonState();
}

class _StopButtonState extends State<_StopButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        HapticFeedback.heavyImpact();
        widget.onPress();
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: _pressed ? AppTheme.danger : AppTheme.dangerGlow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.danger,
            width: _pressed ? 1.5 : 0.5,
          ),
          boxShadow: _pressed
              ? [BoxShadow(color: AppTheme.dangerGlow, blurRadius: 16, spreadRadius: 4)]
              : null,
        ),
        child: Icon(
          Icons.stop_rounded,
          color: _pressed ? Colors.white : AppTheme.danger,
          size: 28,
        ),
      ),
    );
  }
}
