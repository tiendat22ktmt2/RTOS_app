import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/vehicle_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    final svc = context.read<VehicleService>();
    _urlCtrl = TextEditingController(text: svc.wsUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<VehicleService>();

    return Scaffold(
      appBar: AppBar(title: const Text('CÀI ĐẶT')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'KẾT NỐI WEBSOCKET',
            children: [
              const Text(
                'Nhập địa chỉ WebSocket của ESP32/Arduino.\nVí dụ: ws://192.168.1.100:81',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'ws://192.168.1.100:81',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.bgSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.borderColor, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.borderColor, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.accent, width: 1),
                  ),
                  prefixIcon: const Icon(Icons.wifi, color: AppTheme.textSecondary, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    svc.setWsUrl(_urlCtrl.text.trim());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã lưu địa chỉ WebSocket')),
                    );
                  },
                  child: const Text('LƯU & KẾT NỐI', style: TextStyle(letterSpacing: 1, fontSize: 13)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'HƯỚNG DẪN KẾT NỐI ESP32',
            children: [
              _CodeBlock(code: '''
// Arduino / ESP32 WebSocket Server
#include <WebSocketsServer.h>

WebSocketsServer ws = WebSocketsServer(81);

void setup() {
  WiFi.begin("SSID", "password");
  ws.begin();
  ws.onEvent(onWsEvent);
}

void loop() {
  ws.loop();
  // Gửi sensor data mỗi 500ms
  String data = buildSensorJson();
  ws.broadcastTXT(data);
  delay(500);
}

// JSON format cần gửi:
// {"hr":72,"dist":120,"spd":0,
//  "dir":"S","obstacle":false,
//  "bat":87,"ts":"2024-01-01T..."}
'''),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'TRẠNG THÁI',
            children: [
              _InfoRow(label: 'WebSocket URL', value: svc.wsUrl),
              _InfoRow(
                label: 'Trạng thái',
                value: svc.status.name.toUpperCase(),
                valueColor: svc.status == ConnectionStatus.connected
                    ? AppTheme.success
                    : svc.status == ConnectionStatus.simulating
                        ? AppTheme.accent
                        : AppTheme.textSecondary,
              ),
              _InfoRow(label: 'Dữ liệu lịch sử', value: '${svc.history.length} điểm'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
              )),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  const _CodeBlock({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
      ),
      child: Text(
        code.trim(),
        style: const TextStyle(
          fontSize: 11,
          color: AppTheme.textSecondary,
          fontFamily: 'monospace',
          height: 1.6,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: valueColor ?? AppTheme.textPrimary, fontFamily: 'monospace'),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
