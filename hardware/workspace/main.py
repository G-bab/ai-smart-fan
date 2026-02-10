# main.py
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import serial
import threading
import time
import re
import requests
import uvicorn
from datetime import datetime

# -------------------------------
# 설정
BASE_URL = "http://192.168.0.20:8000/api"
SERIAL_PORT = "/dev/ttyUSB0"
BAUD_RATE = 115200

# 전역 변수
ser = None
received_data = ""
pm25_grimm_value = None
pm25_grimm_timestamp = None
stop_event = threading.Event() # 스레드 종료 제어용

# -------------------------------
# 시리얼 읽기 함수 (스레드용)
def read_serial():
    global received_data, pm25_grimm_value, pm25_grimm_timestamp
    while not stop_event.is_set():
        if ser and ser.is_open:
            try:
                if ser.in_waiting > 0:
                    line = ser.readline().decode(errors="ignore").strip()
                    if line:
                        received_data = line
                        print(f"[ESP→RPi] {line}")
                        
                        # PM2.5 파싱
                        pm = parse_pm25_from_line(line)
                        if pm is not None:
                            pm25_grimm_value = pm
                            pm25_grimm_timestamp = datetime.utcnow().isoformat() + "Z"
                            print(f"[PM2.5 GRIMM] {pm25_grimm_value}")
            except Exception as e:
                print("Serial read error:", e)
                time.sleep(1)
        else:
            time.sleep(1)

def parse_pm25_from_line(line: str):
    if "PM2.5" not in line and "PM2.5" not in line.upper():
        return None
    m = re.search(r'(\d+)', line)
    if m:
        try: return int(m.group(1))
        except ValueError: return None
    return None

# -------------------------------
# 초기화 요청 함수들 (예외 처리 추가)
def safe_post_request(endpoint, data):
    try:
        url = f"{BASE_URL}{endpoint}"
        response = requests.post(url, json=data, timeout=2) # 2초 타임아웃
        print(f"📌 {endpoint}: {response.status_code}")
    except Exception as e:
        print(f"⚠️ {endpoint} 요청 실패: {e}")

def run_startup_tasks():
    print("🚀 초기 데이터 전송 시작...")
    safe_post_request("/devices/", {
        "device_id": "fan05", "battery_level": 85, "ip_address": "192.168.0.147",
        "power_state": False, "fan_speed": 1, "angle": 0
    })
    # 필요하면 ai_control, track_user 등도 여기에 추가

# -------------------------------
# ★ 백엔드 요청 전송 도우미 함수 (요청한 출력 포맷 적용)
def send_to_backend(endpoint: str, payload: dict, command_name: str):
    url = f"{BASE_URL}{endpoint}"
    try:
        # 타임아웃 2초 설정 (서버가 안 켜져 있어도 멈추지 않게)
        response = requests.post(url, json=payload, timeout=2)
        
        # 성공 (200번대)
        if 200 <= response.status_code < 300:
            print(f"{{{response.status_code}}}: {command_name} has been sent!")
        # 실패 (400, 500번대)
        else:
            print(f"{{{response.status_code}}}: request error (Server msg: {response.text})")
            
    except requests.exceptions.ConnectionError:
        print(f"{{Error}}: request error (Cannot connect to Backend at {url})")
    except Exception as e:
        print(f"{{Error}}: request error ({str(e)})")

# ★ 시나리오별 실행 함수들
def run_startup_tasks():
    print("\n🚀 [System Startup] 백엔드 연결 테스트 시작...\n")

    # 1️⃣ 디바이스 생성 (기존)
    send_to_backend("/devices/", {
        "device_id": "fan5296",
        "battery_level": 41,
        "ip_address": "192.168.0.147",
        "power_state": False,
        "fan_speed": 300,
        "angle": 15
    }, "Device Creation")

    # 3️⃣ 센서 데이터 업로드
    send_to_backend("/sensors/", {
        "device": "fan5296",
        "temperature": 50.3,
        "humidity": 1.4,
        "co2_level": 15,
        "ir_detected": False
    }, "Sensor Data Upload")

    send_to_backend("/ai/control/", {
        "mode": "follow",
        "user_x": 30,
        "temperature": 15.1,
        "voice_command": "켜"
    }, "Sensor Data Upload")

    send_to_backend("/alert/", {
        "device_id": "fan5296",
        "event": "습도 높음"
    }, "Error sent")
    
    print("\n✅ [System Startup] 테스트 완료.\n")
# -------------------------------
# ★ Lifespan: 앱이 켜지고 꺼질 때 실행될 로직
@asynccontextmanager
async def lifespan(app: FastAPI):
    # 1. 시작될 때 (Startup)
    global ser
    try:
        ser = serial.Serial(SERIAL_PORT, baudrate=BAUD_RATE, timeout=1)
        print(f"✅ 시리얼 연결 성공: {SERIAL_PORT}")
    except Exception as e:
        print(f"❌ 시리얼 포트 열기 실패: {e}")
        ser = None
    
    # 시리얼 읽기 스레드 시작
    t = threading.Thread(target=read_serial, daemon=True)
    t.start()
    
    # 초기 API 데이터 전송 (별도 스레드 혹은 비동기로 하는 게 좋지만, 여기선 간단히 호출)
    run_startup_tasks()
    
    yield  # 앱이 실행되는 동안 여기서 대기
    
    # 2. 꺼질 때 (Shutdown)
    print("🛑 서버 종료 중... 시리얼 닫기")
    stop_event.set()
    if ser and ser.is_open:
        ser.close()

# 앱 생성 (lifespan 적용)
app = FastAPI(title="RPi-ESP32 Bridge", lifespan=lifespan)

# -------------------------------
# API 라우터들 (기존 코드와 동일)

@app.get("/")
def root():
    return JSONResponse({
            "status": "Raspberry Pi FastAPI running",
            "device_id": "fan5296",
            "battery_level": 41,
            "ip_address": "192.168.0.147",
            "power_state": True,
            "fan_speed": 300,
            "angle": 15
        })

@app.get("/sensor/pm25")
def get_pm25_grimm():
    if pm25_grimm_value is None:
        return JSONResponse({
            "pm25_grimm": None,
            "timestamp": None,
            "latest_raw": received_data,
            "message": "데이터 대기 중..."
        })
    return JSONResponse({
        "pm25_grimm": pm25_grimm_value,
        "timestamp": pm25_grimm_timestamp,
        "latest_raw": received_data
    })

def send_command(cmd: str):
    if ser and ser.is_open:
        ser.write((cmd + "\n").encode("utf-8"))
        print(f"[RPi->ESP] {cmd}")
        return True
    return False

@app.post("/move/{direction}")
def move_command(direction: str):
    mapping = {"fwd": "MOVE FWD", "back": "MOVE BACK", "left": "MOVE LEFT", "right": "MOVE RIGHT", "stop": "STOP"}
    direction = direction.lower()
    if direction in mapping:
        return {"sent": mapping[direction], "status": "ok" if send_command(mapping[direction]) else "error"}
    return {"error": "Invalid direction"}

@app.post("/fan/{speed}")
def fan_command(speed: int):
    speed = max(0, min(speed, 255))
    cmd = f"FAN {speed}"
    return {"sent": cmd, "status": "ok" if send_command(cmd) else "error"}

# ... (위쪽 코드는 그대로 유지) ...

if __name__ == "__main__":

    # 윈도우인지 리눅스(라즈베리파이)인지에 따라 포트 자동 설정하면 편해
    # 하드웨어 담당자 컴퓨터(Windows)라면 COM 포트 확인 필요!
    # 예: Windows에서는 "COM3", "COM4" 등
    # 라즈베리파이는 "/dev/ttyUSB0"
    
    # 여기서 직접 실행할 때 설정을 덮어씌울 수 있어
    # SERIAL_PORT = "COM3"  <-- 윈도우에서 테스트할 때 주석 풀고 포트 맞추기

    print("🚀 FastAPI 서버를 시작합니다...")
    # port=8001로 설정한 이유: 8000번은 보통 Django가 쓰고 있을 확률이 높아서 피함
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)