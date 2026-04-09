import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/vehicle_service.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_card.dart';
import '../widgets/dpad_controller.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VehicleService>(
      builder: (context, svc, _) {
        final data = svc.current;
        final isObstacle = data.obstacleDetected || data.distance < 25;
        final screen = MediaQuery.of(context);
        final w = screen.size.width;
        final h = screen.size.height;

        // Scale dựa trên chiều rộng màn hình (base: 390px)
        final scale = (w / 390).clamp(0.75, 1.3);
        final gap = (w * 0.02).clamp(6.0, 14.0);
        final pad = (w * 0.025).clamp(8.0, 16.0);

        return Scaffold(
          appBar: AppBar(
            title: Text('VEHICLE CONTROL', style: TextStyle(fontSize: 14 * scale)),
            actions: [
              _ConnectionBadge(status: svc.status, scale: scale),
              SizedBox(width: gap / 2),
              IconButton(
                icon: Icon(Icons.show_chart_rounded, size: 20 * scale),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
              IconButton(
                icon: Icon(Icons.settings_rounded, size: 20 * scale),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(pad),
              child: Column(
                children: [
                  // Alert Banner
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isObstacle
                        ? _AlertBanner(
                            key: const ValueKey('alert'),
                            message: '⚠  VẬT CẢN PHÁT HIỆN — ${data.distance}cm',
                            color: AppTheme.danger,
                            scale: scale,
                          )
                        : _AlertBanner(
                            key: const ValueKey('clear'),
                            message: '✓  Đường thông thoáng',
                            color: AppTheme.success,
                            scale: scale,
                          ),
                  ),
                  SizedBox(height: gap),

                  // Metrics Row
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            label: 'NHỊP TIM',
                            value: '${data.heartRate}',
                            unit: 'bpm',
                            valueColor: AppTheme.danger,
                            trailing: const PulsingDot(color: AppTheme.danger),
                            scale: scale,
                            pad: pad,
                          ),
                        ),
                        SizedBox(width: gap),
                        Expanded(
                          child: _MetricTile(
                            label: 'KHOẢNG CÁCH',
                            value: '${data.distance}',
                            unit: 'cm',
                            valueColor: isObstacle ? AppTheme.danger : AppTheme.textPrimary,
                            scale: scale,
                            pad: pad,
                          ),
                        ),
                        SizedBox(width: gap),
                        Expanded(
                          child: _MetricTile(
                            label: 'PIN',
                            value: data.batteryLevel.toStringAsFixed(0),
                            unit: '%',
                            valueColor: data.batteryLevel < 20
                                ? AppTheme.danger
                                : data.batteryLevel < 50
                                    ? AppTheme.warning
                                    : AppTheme.success,
                            bottom: _BatteryBar(level: data.batteryLevel),
                            scale: scale,
                            pad: pad,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: gap),

                  // Control + Motor Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: EdgeInsets.all(pad),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderColor, width: 0.5),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'ĐIỀU HƯỚNG',
                                style: TextStyle(
                                  fontSize: (9 * scale).clamp(7.0, 12.0),
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: gap),
                              DPadController(
                                onMove: (dir) => svc.sendCommand(VehicleCommand.move(dir)),
                                onStop: () => svc.sendCommand(VehicleCommand.stop()),
                              ),
                              SizedBox(height: gap),
                              _DirectionLabel(direction: data.direction, scale: scale),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: gap),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: EdgeInsets.all(pad),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderColor, width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TỐC ĐỘ\nĐỘNG CƠ',
                                style: TextStyle(
                                  fontSize: (9 * scale).clamp(7.0, 12.0),
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 1.2,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: gap),
                              _MotorSpeedSlider(
                                value: data.motorSpeed.toDouble(),
                                scale: scale,
                                onChanged: (v) => svc.sendCommand(
                                  VehicleCommand.setSpeed(v.round()),
                                ),
                              ),
                              SizedBox(height: gap),
                              _MotorBars(
                                speed: data.motorSpeed,
                                direction: data.direction,
                                scale: scale,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: gap),

                  // Connection Controls
                  _ConnectionControls(svc: svc, scale: scale, gap: gap),
                  SizedBox(height: gap),

                  // Command Log
                  _CommandLog(
                    logs: svc.commandLog,
                    scale: scale,
                    height: (h * 0.14).clamp(90.0, 140.0),
                  ),
                  SizedBox(height: gap),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Metric Tile ─────────────────────────────────────────────────────────────
class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color valueColor;
  final Widget? trailing;
  final Widget? bottom;
  final double scale;
  final double pad;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.valueColor,
    required this.scale,
    required this.pad,
    this.trailing,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(pad * 0.8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: (8 * scale).clamp(7.0, 11.0),
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing!,
              ],
            ],
          ),
          SizedBox(height: 4 * scale),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: (26 * scale).clamp(18.0, 34.0),
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: (10 * scale).clamp(8.0, 13.0),
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (bottom != null) ...[
            SizedBox(height: 5 * scale),
            bottom!,
          ],
        ],
      ),
    );
  }
}

// ─── Alert Banner ─────────────────────────────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final String message;
  final Color color;
  final double scale;

  const _AlertBanner({
    super.key,
    required this.message,
    required this.color,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: color,
          fontSize: (12 * scale).clamp(10.0, 15.0),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Connection Badge ─────────────────────────────────────────────────────────
class _ConnectionBadge extends StatelessWidget {
  final ConnectionStatus status;
  final double scale;
  const _ConnectionBadge({required this.status, required this.scale});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case ConnectionStatus.connected:
        color = AppTheme.success;
        label = 'LIVE';
        break;
      case ConnectionStatus.connecting:
        color = AppTheme.warning;
        label = 'CONNECT...';
        break;
      case ConnectionStatus.simulating:
        color = AppTheme.accent;
        label = 'SIM';
        break;
      default:
        color = AppTheme.textSecondary;
        label = 'OFFLINE';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulsingDot(color: color, size: 6 * scale),
          SizedBox(width: 5 * scale),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: (10 * scale).clamp(8.0, 13.0),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Battery Bar ──────────────────────────────────────────────────────────────
class _BatteryBar extends StatelessWidget {
  final double level;
  const _BatteryBar({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = level < 20
        ? AppTheme.danger
        : level < 50
            ? AppTheme.warning
            : AppTheme.success;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: level / 100,
        backgroundColor: AppTheme.bgSecondary,
        valueColor: AlwaysStoppedAnimation<Color>(color),
        minHeight: 4,
      ),
    );
  }
}

// ─── Direction Label ──────────────────────────────────────────────────────────
class _DirectionLabel extends StatelessWidget {
  final String direction;
  final double scale;
  const _DirectionLabel({required this.direction, required this.scale});

  static const _names = {
    'F': 'TIẾN',
    'B': 'LÙI',
    'L': 'RẼ TRÁI',
    'R': 'RẼ PHẢI',
    'S': 'DỪNG',
  };

  @override
  Widget build(BuildContext context) {
    return Text(
      _names[direction] ?? direction,
      style: TextStyle(
        fontSize: (11 * scale).clamp(9.0, 14.0),
        color: AppTheme.textSecondary,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ─── Motor Speed Slider ───────────────────────────────────────────────────────
class _MotorSpeedSlider extends StatelessWidget {
  final double value;
  final double scale;
  final ValueChanged<double> onChanged;

  const _MotorSpeedSlider({
    required this.value,
    required this.scale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${value.round()}%',
              style: TextStyle(
                fontSize: (22 * scale).clamp(16.0, 28.0),
                fontWeight: FontWeight.bold,
                color: AppTheme.accent,
              ),
            ),
            Text(
              'PWM',
              style: TextStyle(
                fontSize: (9 * scale).clamp(7.0, 12.0),
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 6 * scale),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7 * scale),
            activeTrackColor: AppTheme.accent,
            inactiveTrackColor: AppTheme.bgSecondary,
            thumbColor: AppTheme.accent,
            overlayColor: AppTheme.accentGlow,
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ─── Motor Bars ───────────────────────────────────────────────────────────────
class _MotorBars extends StatelessWidget {
  final int speed;
  final String direction;
  final double scale;
  const _MotorBars({
    required this.speed,
    required this.direction,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final factors = _getFactors(direction);
    final labels = ['LF', 'RF', 'LB', 'RB'];
    return Column(
      children: List.generate(4, (i) {
        final pct = (factors[i] * speed).clamp(0, 100).toInt();
        return Padding(
          padding: EdgeInsets.only(bottom: 5 * scale),
          child: Row(
            children: [
              SizedBox(
                width: 22 * scale,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: (9 * scale).clamp(7.0, 12.0),
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor: AppTheme.bgSecondary,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                    minHeight: 4,
                  ),
                ),
              ),
              SizedBox(width: 4 * scale),
              SizedBox(
                width: 26 * scale,
                child: Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: (9 * scale).clamp(7.0, 12.0),
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  List<double> _getFactors(String dir) {
    switch (dir) {
      case 'F': return [1, 1, 1, 1];
      case 'B': return [1, 1, 1, 1];
      case 'L': return [0.3, 1, 0.3, 1];
      case 'R': return [1, 0.3, 1, 0.3];
      default:  return [0, 0, 0, 0];
    }
  }
}

// ─── Connection Controls ──────────────────────────────────────────────────────
class _ConnectionControls extends StatelessWidget {
  final VehicleService svc;
  final double scale;
  final double gap;
  const _ConnectionControls({
    required this.svc,
    required this.scale,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CtrlBtn(
            label: 'Kết nối\nWebSocket',
            icon: Icons.wifi_rounded,
            color: AppTheme.success,
            onTap: svc.connect,
            enabled: svc.status == ConnectionStatus.disconnected,
            scale: scale,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _CtrlBtn(
            label: 'Chế độ\nSim',
            icon: Icons.play_circle_outline_rounded,
            color: AppTheme.accent,
            onTap: svc.startSimulation,
            enabled: svc.status != ConnectionStatus.simulating,
            scale: scale,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _CtrlBtn(
            label: 'Ngắt kết\nnối',
            icon: Icons.wifi_off_rounded,
            color: AppTheme.danger,
            onTap: svc.disconnect,
            enabled: svc.status != ConnectionStatus.disconnected,
            scale: scale,
          ),
        ),
      ],
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
  final double scale;

  const _CtrlBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.enabled,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10 * scale),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3), width: 0.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: (18 * scale).clamp(14.0, 24.0)),
              SizedBox(height: 4 * scale),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: (10 * scale).clamp(8.0, 13.0),
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Command Log ──────────────────────────────────────────────────────────────
class _CommandLog extends StatelessWidget {
  final List<String> logs;
  final double scale;
  final double height;
  const _CommandLog({
    required this.logs,
    required this.scale,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.all(10 * scale),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMMAND LOG',
            style: TextStyle(
              fontSize: (9 * scale).clamp(7.0, 12.0),
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 6 * scale),
          Expanded(
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (_, i) => Text(
                logs[i],
                style: TextStyle(
                  fontSize: (11 * scale).clamp(9.0, 14.0),
                  color: logs[i].contains('✗')
                      ? AppTheme.danger
                      : logs[i].contains('✓')
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                  height: 1.6,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
