#include <Wire.h>
#include <pm2008_i2c.h>

#define LEFT_IN1   2
#define LEFT_IN2   3
#define LEFT_PWM   4

#define RIGHT_IN1  5
#define RIGHT_IN2  6
#define RIGHT_PWM  7

#define FAN        8

const int PWM_FREQ = 20000;
const int PWM_CHANNEL_LEFT  = 0;
const int PWM_CHANNEL_RIGHT = 1;
const int PWM_RESOLUTION = 8;

String inputString = "";

// PM2008M I2C 객체
PM2008_I2C pm2008_i2c;
uint16_t pm25_grimm = 0;                 // 최근 PM2.5 (GRIMM) 값
unsigned long lastPmRead = 0;
const unsigned long PM_READ_INTERVAL = 1000; // 1초 주기

void setMotor(int in1, int in2, int pwmChannel, int speed, int direction) {
  if (direction == 1) { // 정방향
    digitalWrite(in1, HIGH);
    digitalWrite(in2, LOW);
  } else if (direction == -1) { // 역방향
    digitalWrite(in1, LOW);
    digitalWrite(in2, HIGH);
  } else { // 정지
    digitalWrite(in1, LOW);
    digitalWrite(in2, LOW);
  }
  ledcWrite(pwmChannel, constrain(speed, 0, 255));
}

// PM2008M에서 값 읽어오기
void readPm2008() {
  uint8_t ret = pm2008_i2c.read();
  if (ret == 0) {
    pm25_grimm = pm2008_i2c.pm2p5_grimm;
    Serial.print("PM2.5 (GRIMM) : ");
    Serial.println(pm25_grimm);
  } else {
    Serial.print("PM2008 read error: ");
    Serial.println(ret);
  }
}

void setup() {
  Serial.begin(115200);

  pinMode(LEFT_IN1, OUTPUT);
  pinMode(LEFT_IN2, OUTPUT);
  pinMode(RIGHT_IN1, OUTPUT);
  pinMode(RIGHT_IN2, OUTPUT);
  pinMode(FAN, OUTPUT);

  ledcSetup(PWM_CHANNEL_LEFT, PWM_FREQ, PWM_RESOLUTION);
  ledcSetup(PWM_CHANNEL_RIGHT, PWM_FREQ, PWM_RESOLUTION);
  ledcAttachPin(LEFT_PWM, PWM_CHANNEL_LEFT);
  ledcAttachPin(RIGHT_PWM, PWM_CHANNEL_RIGHT);

  // I2C & PM2008M 초기화
  // 필요하면 Wire.begin(SDA_PIN, SCL_PIN); 으로 핀 지정
  Wire.begin();
  pm2008_i2c.begin();
  pm2008_i2c.command();   // 측정 모드 설정
  delay(1000);

  Serial.println("ESP32-S3 motor & fan & PM2008M ready.");
}

void loop() {
  // --- 문자열 명령 수신 ---
  if (Serial.available()) {
    char c = Serial.read();
    if (c == '\n') { // 명령 끝
      inputString.trim();
      handleCommand(inputString);
      inputString = "";
    } else {
      inputString += c;
    }
  }

  // --- PM2008M 주기적 읽기 ---
  unsigned long now = millis();
  if (now - lastPmRead >= PM_READ_INTERVAL) {
    lastPmRead = now;
    readPm2008();
  }
}

void handleCommand(String cmd) {
  cmd.toUpperCase();
  Serial.print("Received: ");
  Serial.println(cmd);

  // 이동 명령 처리
  if (cmd == "MOVE FWD") {
    setMotor(LEFT_IN1, LEFT_IN2, PWM_CHANNEL_LEFT, 200, 1);
    setMotor(RIGHT_IN1, RIGHT_IN2, PWM_CHANNEL_RIGHT, 200, 1);
  } 
  else if (cmd == "MOVE BACK") {
    setMotor(LEFT_IN1, LEFT_IN2, PWM_CHANNEL_LEFT, 200, -1);
    setMotor(RIGHT_IN1, RIGHT_IN2, PWM_CHANNEL_RIGHT, 200, -1);
  }
  else if (cmd == "MOVE LEFT") {
    setMotor(LEFT_IN1, LEFT_IN2, PWM_CHANNEL_LEFT, 180, -1);
    setMotor(RIGHT_IN1, RIGHT_IN2, PWM_CHANNEL_RIGHT, 180, 1);
  } 
  else if (cmd == "MOVE RIGHT") {
    setMotor(LEFT_IN1, LEFT_IN2, PWM_CHANNEL_LEFT, 180, 1);
    setMotor(RIGHT_IN1, RIGHT_IN2, PWM_CHANNEL_RIGHT, 180, -1);
  } 
  else if (cmd == "STOP") {
    setMotor(LEFT_IN1, LEFT_IN2, PWM_CHANNEL_LEFT, 0, 0);
    setMotor(RIGHT_IN1, RIGHT_IN2, PWM_CHANNEL_RIGHT, 0, 0);
  } 
  // 팬 제어 명령
  else if (cmd.startsWith("FAN")) {
    int speed = cmd.substring(4).toInt(); // "FAN 120" -> 120
    speed = constrain(speed, 0, 255);
    analogWrite(FAN, speed);
    Serial.print("Fan speed set to ");
    Serial.println(speed);
  } 
  else {
    Serial.println("Unknown command.");
  }
}
