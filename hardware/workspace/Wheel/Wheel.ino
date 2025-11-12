
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

  Serial.println("ESP32-S3 motor & fan control ready.");
}

void loop() {
  // 문자열 명령 수신
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
  // 팬 제어 명령 (예: FAN 120)
  else if (cmd.startsWith("FAN")) {
    int speed = cmd.substring(4).toInt(); // "FAN 120" → 120
    speed = constrain(speed, 0, 255);
    analogWrite(FAN, speed);
    Serial.print("Fan speed set to ");
    Serial.println(speed);
  } 
  else {
    Serial.println("Unknown command.");
  }
}