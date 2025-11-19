# main.py
from fastapi import FastAPI
from fastapi.responses import JSONResponse
import serial
import threading
import time
import re
from datetime import datetime

app = FastAPI(title="Raspberry Pi - ESP32 Motor & Fan Control Bridge")

# -------------------------------
# 시리얼 설정
try:
    ser = serial.Serial("/dev/ttyUSB0", baudrate=115200, timeout=1)
    print("ESP32 시리얼 연결 성공 (/dev/ttyUSB0)")
except Exception as e:
    print("ESP 시리얼 포트 열기 실패:", e)
    ser = None

# -------------------------------
# 백그라운드 리스너 (ESP -> RPi)
received_data = ""

# PM2.5 (GRIMM) 값 저장용
pm25_grimm_value = None
pm25_grimm_timestamp = None  # ISO 문자열로 저장

def parse_pm25_from_line(line: str):
    """
    ESP에서 찍는 형태 예:
    'PM2.5 (GRIMM) : 23'
    같은 줄에서 숫자만 뽑아서 int로 반환
    """
    if "PM2.5" not in line and "PM2.5" not in line.upper():
        return None

    m = re.search(r'(\d+)', line)
    if m:
        try:
            return int(m.group(1))
        except ValueError:
            return None
    return None

def read_serial():
    global received_data, pm25_grimm_value, pm25_grimm_timestamp
    if not ser:
        return
    while True:
        try: 
            line = ser.readline().decode(errors="ignore").strip()
            if line:
                received_data = line
                print(f"[ESP→RPi] {line}")

                # PM2.5 (GRIMM) 라인 파싱
                pm = parse_pm25_from_line(line)
                if pm is not None:
                    pm25_grimm_value = pm
                    pm25_grimm_timestamp = datetime.utcnow().isoformat() + "Z"
                    print(f"[PM2.5 GRIMM] {pm25_grimm_value} (updated at {pm25_grimm_timestamp})")

        except Exception as e:
            print("Serial read error:", e)
            time.sleep(0.5)

if ser:
    threading.Thread(target=read_serial, daemon=True).start()

# -------------------------------
# 명령 전송 함수 (RPi -> ESP)
def send_command(cmd: str):
    """ESP32로 명령 문자열 전송"""
    if ser:
        ser.write((cmd + "\n").encode("utf-8"))
        print(f"[RPi->ESP] {cmd}")
        return True
    else:
        print("시리얼 연결 없음.")
        return False

# -------------------------------
# API 엔드포인트

@app.get("/")
def root():
    return {"status": "Raspberry Pi FastAPI running"}

@app.get("/esp/latest")
def get_latest():
    """ESP32가 보낸 최근 데이터를 반환"""
    return JSONResponse({"latest_data": received_data})

# ★ 새로 추가: 최신 PM2.5(GRIMM) 값 조회
@app.get("/sensor/pm25")
def get_pm25_grimm():
    """
    ESP32가 시리얼로 출력한 'PM2.5 (GRIMM)' 라인에서
    파싱한 최신 값을 반환
    """
    if pm25_grimm_value is None:
        return JSONResponse({
            "pm25_grimm": None,
            "timestamp": None,
            "latest_raw": received_data,
            "message": "아직 PM2.5 (GRIMM) 값을 한 번도 받지 못했습니다."
        })

    return JSONResponse({
        "pm25_grimm": pm25_grimm_value,
        "timestamp": pm25_grimm_timestamp,
        "latest_raw": received_data
    })

# -------------------------------
# 이동 제어 명령
@app.post("/move/{direction}")
def move_command(direction: str):
    """
    이동 제어 명령
    direction: fwd / back / left / right / stop
    """
    direction = direction.lower()
    mapping = {
        "fwd": "MOVE FWD",
        "back": "MOVE BACK",
        "left": "MOVE LEFT",
        "right": "MOVE RIGHT",
        "stop": "STOP",
    }
    if direction in mapping:
        ok = send_command(mapping[direction])
        return {"sent": mapping[direction], "status": "ok" if ok else "error"}
    else:
        return {"error": f"Invalid direction '{direction}'"}

# -------------------------------
#  팬 제어 명령
@app.post("/fan/{speed}")
def fan_command(speed: int):
    """
    선풍기 모터 속도 제어 (0~255)
    """
    speed = max(0, min(speed, 255))
    ok = send_command(f"FAN {speed}")
    return {"sent": f"FAN {speed}", "status": "ok" if ok else "error"}

# -------------------------------
# 임의 문자열 전송 (테스트용)
@app.post("/esp/send/{msg}")
def send_to_esp(msg: str):
    """라즈베리 -> ESP로 문자열 전송"""
    ok = send_command(msg)
    return {"sent": msg, "status": "ok" if ok else "error"}
