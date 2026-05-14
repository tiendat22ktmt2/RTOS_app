import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/sensor_data.dart';

enum ConnectionStatus { disconnected, connecting, connected, simulating }

class VehicleService extends ChangeNotifier {
  // ── MQTT ─────────────────────────────────────────────────────────────────
  MqttServerClient? _client;
  Timer? _reconnectTimer;

  //String _mqttHost = 'broker.hivemq.com';
  String _mqttHost = "18.185.216.165";
  final int _mqttPort = 1883;                          // WSS port
  final String _clientId = 'vehicle_ctrl_${DateTime.now().millisecondsSinceEpoch}';

  String _topicSensor  = 'vehicle/sensor';
  String _topicCommand = 'vehicle/command';

  // ── Chung ────────────────────────────────────────────────────────────────
  Timer? _simTimer;
  Timer? _historyTimer;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  SensorData _current = SensorData.mock();
  final List<HistoryEntry> _history = [];
  final List<String> _commandLog = [];

  int _simHr = 72;
  int _simDist = 120;
  int _motorSpeed = 0;
  String _direction = 'S';
  final Random _rng = Random();

  // ── Getters ──────────────────────────────────────────────────────────────
  ConnectionStatus get status => _status;
  SensorData get current => _current;
  List<HistoryEntry> get history => List.unmodifiable(_history);
  List<String> get commandLog => List.unmodifiable(_commandLog.reversed.toList());
  String get mqttHost => _mqttHost;
  String get topicSensor => _topicSensor;
  String get topicCommand => _topicCommand;

  String get wsUrl => 'wss://$_mqttHost:$_mqttPort/mqtt';
  void setWsUrl(String _) {}

  void setMqttHost(String host) { _mqttHost = host; notifyListeners(); }
  void setTopicSensor(String t) { _topicSensor = t; notifyListeners(); }
  void setTopicCommand(String t) { _topicCommand = t; notifyListeners(); }

  // ════════════════════════════════════════════════════════════════════════
  // Kết nối MQTT qua WSS
  // ════════════════════════════════════════════════════════════════════════

  Future<void> connect() async {
    if (_status == ConnectionStatus.connected) return;
    _stopAll();
    _status = ConnectionStatus.connecting;
    notifyListeners();

    _client = MqttServerClient.withPort(_mqttHost, _clientId, _mqttPort);
    _client!.useWebSocket = false;                      // bật WebSocket
    _client!.secure = false;                            // bật TLS/SSL (wss://)
    _client!.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
    _client!.keepAlivePeriod = 20;
    _client!.onDisconnected = _onDisconnected;
    _client!.onConnected = _onConnected;
    _client!.onSubscribed = (String topic) {
      _addLog('✓ Subscribed: $topic');
    };
    _client!.logging(on: false);

    _client!.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    try {
      await _client!.connect();
    } catch (e) {
      _addLog('✗ MQTT thất bại: ${e.toString().split('\n').first}');
      _client?.disconnect();
      _handleDisconnect();
    }
  }

  void _onConnected() {
    _status = ConnectionStatus.connected;
    _addLog('✓ MQTT (WSS): $_mqttHost');
    notifyListeners();

    _client!.subscribe(_topicSensor, MqttQos.atLeastOnce);

    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> msgs) {
      for (final msg in msgs) {
        if (msg.topic == _topicSensor) {
          final pub = msg.payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(
            pub.payload.message,
          );
          try {
            final json = jsonDecode(payload);
            _current = SensorData.fromJson(json);
            _addHistory(_current);
            notifyListeners();
          } catch (_) {}
        }
      }
    });

    _startHistoryTimer();
  }

  void _onDisconnected() {
    if (_status == ConnectionStatus.connected) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _status = ConnectionStatus.disconnected;
    _addLog('✗ Mất kết nối — thử lại sau 5s');
    notifyListeners();
    _reconnectTimer = Timer(const Duration(seconds: 5), connect);
  }

  // ════════════════════════════════════════════════════════════════════════
  // Ngắt kết nối & Simulation
  // ════════════════════════════════════════════════════════════════════════

  void disconnect() {
    _stopAll();
    _client?.disconnect();
    _client = null;
    _status = ConnectionStatus.disconnected;
    _addLog('— Đã ngắt kết nối');
    notifyListeners();
  }

  void startSimulation() {
    _stopAll();
    _status = ConnectionStatus.simulating;
    notifyListeners();
    _addLog('▶ Chế độ mô phỏng');

    _simTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      _simHr = (_simHr + (_rng.nextInt(5) - 2)).clamp(55, 115);
      _simDist = (_simDist + (_rng.nextInt(20) - 10)).clamp(10, 250);
      final obstacle = _simDist < 25;

      _current = SensorData(
        timestamp: DateTime.now(),
        heartRate: _simHr,
        distance: _simDist,
        motorSpeed: _motorSpeed,
        direction: _direction,
        obstacleDetected: obstacle,
        batteryLevel: (_current.batteryLevel - 0.01).clamp(0, 100),
      );
      _addHistory(_current);
      notifyListeners();
    });
  }

  void _stopAll() {
    _reconnectTimer?.cancel();
    _simTimer?.cancel();
    _historyTimer?.cancel();
  }

  // ════════════════════════════════════════════════════════════════════════
  // Gửi lệnh qua MQTT
  // ════════════════════════════════════════════════════════════════════════

  void sendCommand(VehicleCommand cmd) {
    _direction = cmd.direction ?? _direction;
    if (cmd.speed != null) _motorSpeed = cmd.speed!;

    _addLog('→ ${_commandLabel(cmd)}');

    if (_status == ConnectionStatus.connected && _client != null) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode(cmd.toJson()));
      _client!.publishMessage(
        _topicCommand,
        MqttQos.atLeastOnce,
        builder.payload!,
      );
    }

    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════
  // Helpers
  // ════════════════════════════════════════════════════════════════════════

  void _startHistoryTimer() {
    _historyTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _addHistory(_current);
    });
  }

  void _addHistory(SensorData data) {
    _history.add(HistoryEntry(
      time: data.timestamp,
      heartRate: data.heartRate.toDouble(),
      distance: data.distance.toDouble(),
      motorSpeed: data.motorSpeed.toDouble(),
    ));
    if (_history.length > 300) _history.removeAt(0);
  }

  String _commandLabel(VehicleCommand cmd) {
    const dirs = {'F': 'Tiến', 'B': 'Lùi', 'L': 'Rẽ trái', 'R': 'Rẽ phải', 'S': 'Dừng'};
    if (cmd.type == 'MOVE') return 'Di chuyển: ${dirs[cmd.direction] ?? cmd.direction}';
    if (cmd.type == 'SPEED') return 'Tốc độ: ${cmd.speed}%';
    return 'Dừng khẩn cấp';
  }

  void _addLog(String msg) {
    final ts = DateTime.now();
    final label =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}';
    _commandLog.add('[$label] $msg');
    if (_commandLog.length > 100) _commandLog.removeAt(0);
  }

  @override
  void dispose() {
    _stopAll();
    _client?.disconnect();
    super.dispose();
  }
}
