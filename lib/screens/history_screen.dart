import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/vehicle_service.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LỊCH SỬ DỮ LIỆU'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontSize: 11, letterSpacing: 1),
          tabs: const [
            Tab(text: 'NHỊP TIM'),
            Tab(text: 'KHOẢNG CÁCH'),
            Tab(text: 'TỐC ĐỘ'),
          ],
        ),
      ),
      body: Consumer<VehicleService>(
        builder: (context, svc, _) {
          final history = svc.history;
          if (history.isEmpty) {
            return const Center(
              child: Text('Chưa có dữ liệu.\nBắt đầu kết nối hoặc chế độ Sim.',
                  style: TextStyle(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center),
            );
          }

          return TabBarView(
            controller: _tabs,
            children: [
              _ChartView(
                history: history,
                getValue: (e) => e.heartRate,
                label: 'BPM',
                color: AppTheme.danger,
                minY: 40,
                maxY: 130,
              ),
              _ChartView(
                history: history,
                getValue: (e) => e.distance,
                label: 'cm',
                color: AppTheme.warning,
                minY: 0,
                maxY: 260,
                dangerThreshold: 25,
              ),
              _ChartView(
                history: history,
                getValue: (e) => e.motorSpeed,
                label: '%',
                color: AppTheme.accent,
                minY: 0,
                maxY: 100,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChartView extends StatelessWidget {
  final List<HistoryEntry> history;
  final double Function(HistoryEntry) getValue;
  final String label;
  final Color color;
  final double minY;
  final double maxY;
  final double? dangerThreshold;

  const _ChartView({
    required this.history,
    required this.getValue,
    required this.label,
    required this.color,
    required this.minY,
    required this.maxY,
    this.dangerThreshold,
  });

  @override
  Widget build(BuildContext context) {
    final display = history.length > 60 ? history.sublist(history.length - 60) : history;
    final spots = display.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), getValue(e.value)))
        .toList();

    final current = getValue(display.last);
    final avg = display.map(getValue).reduce((a, b) => a + b) / display.length;
    final max = display.map(getValue).reduce((a, b) => a > b ? a : b);
    final min = display.map(getValue).reduce((a, b) => a < b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats row
          Row(
            children: [
              _StatPill(label: 'HIỆN TẠI', value: '${current.round()} $label', color: color),
              const SizedBox(width: 8),
              _StatPill(label: 'TB', value: '${avg.round()} $label', color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              _StatPill(label: 'MAX', value: '${max.round()} $label', color: AppTheme.warning),
              const SizedBox(width: 8),
              _StatPill(label: 'MIN', value: '${min.round()} $label', color: AppTheme.success),
            ],
          ),
          const SizedBox(height: 20),

          // Chart
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                clipData: const FlClipData.all(),
                backgroundColor: AppTheme.bgSecondary,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppTheme.borderColor,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppTheme.borderColor, width: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: (maxY - minY) / 4,
                      getTitlesWidget: (v, _) => Text(
                        v.round().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  if (dangerThreshold != null)
                    LineChartBarData(
                      spots: [
                        FlSpot(0, dangerThreshold!),
                        FlSpot(display.length - 1.0, dangerThreshold!),
                      ],
                      color: AppTheme.danger.withOpacity(0.4),
                      barWidth: 1,
                      dotData: const FlDotData(show: false),
                      dashArray: [4, 4],
                    ),
                  LineChartBarData(
                    spots: spots,
                    color: color,
                    barWidth: 2,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [color.withOpacity(0.2), color.withOpacity(0)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${display.length} điểm dữ liệu — 60 điểm gần nhất',
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2), width: 0.5),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary, letterSpacing: 0.8)),
            const SizedBox(height: 3),
            Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
