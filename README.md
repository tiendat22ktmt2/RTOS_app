# Vehicle Controller App 🚗

Flutter app điều khiển xe qua WebSocket, hỗ trợ iOS & Android.

## Cấu trúc project

```
lib/
├── main.dart                  # Entry point
├── theme/
│   └── app_theme.dart         # Dark industrial theme
├── models/
│   └── sensor_data.dart       # Data models & commands
├── services/
│   └── vehicle_service.dart   # WebSocket + simulation
├── widgets/
│   ├── metric_card.dart       # Reusable metric cards
│   └── dpad_controller.dart   # D-Pad điều hướng
└── screens/
    ├── dashboard_screen.dart  # Màn hình chính
    ├── history_screen.dart    # Biểu đồ lịch sử
    └── settings_screen.dart   # Cấu hình WebSocket
```

## Cài đặt

```bash
flutter pub get
flutter run
```

## Kết nối ESP32

### 1. Cài thư viện
Dùng Arduino IDE, cài:
- `WebSocketsServer` by Markus Sattler
- `ArduinoJson`

### 2. Code ESP32

```cpp
#include <WiFi.h>
#include <WebSocketsServer.h>
#include <ArduinoJson.h>

const char* ssid = "YOUR_WIFI";
const char* password = "YOUR_PASS";

WebSocketsServer webSocket(81);

// Cảm biến
int heartRate = 72;
int distance = 120;
int motorSpeed = 0;
String direction = "S";

void onWebSocketEvent(uint8_t client_num, WStype_t type, uint8_t* payload, size_t length) {
  if (type == WStype_TEXT) {
    // Nhận lệnh từ app
    StaticJsonDocument<200> doc;
    deserializeJson(doc, payload);
    
    String cmd = doc["cmd"].as<String>();
    if (cmd == "MOVE") {
      direction = doc["dir"].as<String>();
      moveMotor(direction);
    } else if (cmd == "SPEED") {
      motorSpeed = doc["spd"].as<int>();
      setMotorSpeed(motorSpeed);
    } else if (cmd == "STOP") {
      stopMotors();
    }
  }
}

void sendSensorData() {
  // Đọc cảm biến thật ở đây
  // heartRate = readHeartSensor();
  // distance = readUltrasonic();
  
  StaticJsonDocument<300> doc;
  doc["hr"] = heartRate;
  doc["dist"] = distance;
  doc["spd"] = motorSpeed;
  doc["dir"] = direction;
  doc["obstacle"] = (distance < 25);
  doc["bat"] = 87;
  doc["ts"] = "2024-01-01T00:00:00Z";
  
  String output;
  serializeJson(doc, output);
  webSocket.broadcastTXT(output);
}

void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) delay(500);
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());  // Dùng IP này để điền vào app
  
  webSocket.begin();
  webSocket.onEvent(onWebSocketEvent);
}

void loop() {
  webSocket.loop();
  sendSensorData();   // Gửi mỗi 500ms
  delay(500);
}

// Hàm điều khiển motor (tuỳ theo driver L298N/L293D)
void moveMotor(String dir) {
  if (dir == "F") { /* forward */ }
  else if (dir == "B") { /* backward */ }
  else if (dir == "L") { /* left */ }
  else if (dir == "R") { /* right */ }
}

void setMotorSpeed(int spd) {
  // analogWrite(EN_PIN, map(spd, 0, 100, 0, 255));
}

void stopMotors() {
  direction = "S";
  // Tắt tất cả motor
}
```

### 3. Cấu hình app
1. Mở app → icon ⚙️ Settings
2. Nhập địa chỉ: `ws://<IP_ESP32>:81`
3. Nhấn "Lưu & Kết nối"

## Cảm biến tương thích

| Cảm biến | Đo gì | Module |
|---|---|---|
| HC-SR04 | Khoảng cách | Siêu âm |
| MAX30100/30102 | Nhịp tim + SpO2 | I2C |
| Driver L298N | Điều khiển motor | PWM |

## Tính năng

- ✅ D-Pad điều hướng với haptic feedback
- ✅ Điều chỉnh tốc độ PWM (slider)
- ✅ Hiển thị nhịp tim realtime
- ✅ Cảnh báo vật cản (< 25cm)
- ✅ Biểu đồ lịch sử (nhịp tim, khoảng cách, tốc độ)
- ✅ WebSocket auto-reconnect
- ✅ Chế độ Simulation (không cần phần cứng)
- ✅ Command log
- ✅ Chỉ báo pin
