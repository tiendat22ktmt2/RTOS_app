class SensorData {
  final DateTime timestamp;
  final int heartRate;
  final int distance;
  final int motorSpeed;
  final String direction;
  final bool obstacleDetected;
  final double batteryLevel;

  SensorData({
    required this.timestamp,
    required this.heartRate,
    required this.distance,
    required this.motorSpeed,
    required this.direction,
    required this.obstacleDetected,
    required this.batteryLevel,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      timestamp: DateTime.tryParse(json['ts'] ?? '') ?? DateTime.now(),
      heartRate: (json['hr'] ?? 72) as int,
      distance: (json['dist'] ?? 100) as int,
      motorSpeed: (json['spd'] ?? 0) as int,
      direction: json['dir'] ?? 'S',
      obstacleDetected: (json['obstacle'] ?? false) as bool,
      batteryLevel: ((json['bat'] ?? 100) as num).toDouble(),
    );
  }

  factory SensorData.mock() {
    return SensorData(
      timestamp: DateTime.now(),
      heartRate: 72,
      distance: 120,
      motorSpeed: 0,
      direction: 'S',
      obstacleDetected: false,
      batteryLevel: 87.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'ts': timestamp.toIso8601String(),
        'hr': heartRate,
        'dist': distance,
        'spd': motorSpeed,
        'dir': direction,
        'obstacle': obstacleDetected,
        'bat': batteryLevel,
      };
}

class HistoryEntry {
  final DateTime time;
  final double heartRate;
  final double distance;
  final double motorSpeed;

  HistoryEntry({
    required this.time,
    required this.heartRate,
    required this.distance,
    required this.motorSpeed,
  });
}

class VehicleCommand {
  final String type; // MOVE, SPEED, STOP
  final String? direction; // F, B, L, R, S
  final int? speed; // 0-100

  VehicleCommand.move(String dir)
      : type = 'MOVE',
        direction = dir,
        speed = null;

  VehicleCommand.setSpeed(int spd)
      : type = 'SPEED',
        direction = null,
        speed = spd;

  VehicleCommand.stop()
      : type = 'STOP',
        direction = 'S',
        speed = null;

  Map<String, dynamic> toJson() => {
        'cmd': type,
        if (direction != null) 'dir': direction,
        if (speed != null) 'spd': speed,
        'ts': DateTime.now().millisecondsSinceEpoch,
      };
}
