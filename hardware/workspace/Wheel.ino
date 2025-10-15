/*
  ESP32-S3 Dual DC Motor Control Template
  ---------------------------------------
  - 모터 드라이버: L298N, L293D, TB6612FNG 등 호환 가능
  - 각 모터: 방향 제어 2핀 + PWM 속도 제어 1핀
  - PWM 주파수와 해상도는 필요에 따라 변경 가능
*/

#define LEFT_IN1   2   // 왼쪽 모터 방향 제어 1
#define LEFT_IN2   3   // 왼쪽 모터 방향 제어 2
#define LEFT_PWM   4   // 왼쪽 모터 속도 제어 (PWM 핀)

#define RIGHT_IN1  5   // 오른쪽 모터 방향 제어 1
#define RIGHT_IN2  6   // 오른쪽 모터 방향 제어 2
#define RIGHT_PWM  7   // 오른쪽 모터 속도 제어 (PWM 핀)

#define FAN 8


const int PWM_FREQ = 20000;  // PWM 주파수 (20kHz: 소음 최소화)
const int PWM_CHANNEL_LEFT  = 0;
const int PWM_CHANNEL_RIGHT = 1;
const int PWM_RESOLUTION = 8;  // 8비트 해상도 (0~255)

// 모터 제어 함수
void setMotor(int in1, int in2, int pwmChannel, int speed, int direction) {
  // direction: 1 = 정방향, -1 = 역방향, 0 = 정지
  if (direction == 1) {
    digitalWrite(in1, HIGH);
    digitalWrite(in2, LOW);
  } else if (direction == -1) {
    digitalWrite(in1, LOW);
    digitalWrite(in2, HIGH);
  } else {
    digitalWrite(in1, LOW);
    digitalWrite(in2, LOW);
  }

  // 속도 설정 (0~255)
  ledcWrite(pwmChannel, constrain(speed, 0, 255));
}

void setup() {
  Serial.begin(115200);

  // 핀 모드 설정
  pinMode(LEFT_IN1, OUTPUT);
  pinMode(LEFT_IN2, OUTPUT);
  pinMode(RIGHT_IN1, OUTPUT);
  pinMode(RIGHT_IN2, OUTPUT);

  // PWM 채널 설정
  ledcSetup(PWM_CHANNEL_LEFT, PWM_FREQ, PWM_RESOLUTION);
  ledcSetup(PWM_CHANNEL_RIGHT, PWM_FREQ, PWM_RESOLUTION);

  digitalWrite(FAN, HIGH);
  
  ledcAttachPin(LEFT_PWM, PWM_CHANNEL_LEFT);
  ledcAttachPin(RIGHT_PWM, PWM_CHANNEL_RIGHT);

  Serial.println("Motor control initialized.");
}

void loop() {
  // 예시: 전진
  setMotor(LEFT_IN1, LEFT_IN2, PWM_CHANNEL_LEFT, 200, 1);
  setMotor(RIGHT_IN1, RIGHT_IN2, PWM_CHANNEL_RIGHT, 200, 1);
  delay(2000);

  // 후진
  setMotor(LEFT_IN1, LEFT_IN2, PWM_CHANNEL_LEFT, 200, -1);
  setMotor(RIGHT_IN1, RIGHT_IN2, PWM_CHANNEL_RIGHT, 200, -1);
  delay(2000);

  // 좌회전
  setMotor(LEFT_IN1, LEFT_IN2, PWM_CHANNEL_LEFT, 180, -1);
  setMotor(RIGHT_IN1, RIGHT_IN2, PWM_CHANNEL_RIGHT, 180, 1);
  delay(1500);

  // 우회전
  setMotor(LEFT_IN1, LEFT_IN2, PWM_CHANNEL_LEFT, 180, 1);
  setMotor(RIGHT_IN1, RIGHT_IN2, PWM_CHANNEL_RIGHT, 180, -1);
  delay(1500);

  // 정지
  setMotor(LEFT_IN1, LEFT_IN2, PWM_CHANNEL_LEFT, 0, 0);
  setMotor(RIGHT_IN1, RIGHT_IN2, PWM_CHANNEL_RIGHT, 0, 0);
  delay(2000);

}


