# main.py
from fastapi import FastAPI
from fastapi.responses import JSONResponse
import serial
import threading
import time

app = FastAPI(title="Raspberry Pi - ESP32 Motor & Fan Control Bridge")

# -------------------------------
# ⚙️ 시리얼 설정
# -------------------------------
try:
    ser = serial.Serial("/dev/ttyUSB0", baudrate=115200, timeout=1)
    print("✅ ESP32 시리얼 연결 성공 (/dev/ttyUSB0)")
except Exception as e:
    print("❌ ESP 시리얼 포트 열기 실패:", e)
    ser = None

# -------------------------------
# 🔄 백그라운드 리스너 (ESP → RPi)
# -------------------------------
received_data = ""

def read_serial():
    global received_data
    if not ser:
        return
    while True:
        try:
            line = ser.readline().decode(errors="ignore").strip()
            if line:
                received_data = line
                print(f"[ESP→RPi] {line}")
        except Exception as e:
            print("Serial read error:", e)
            time.sleep(0.5)

if ser:
    threading.Thread(target=read_serial, daemon=True).start()

# -------------------------------
# 🚗 명령 전송 함수 (RPi → ESP)
# -------------------------------
def send_command(cmd: str):
    """ESP32로 명령 문자열 전송"""
    if ser:
        ser.write((cmd + "\n").encode("utf-8"))
        print(f"[RPi→ESP] {cmd}")
        return True
    else:
        print("⚠️ 시리얼 연결 없음.")
        return False

# -------------------------------
# 🌐 API 엔드포인트
# -------------------------------

@app.get("/")
def root():
    return {"status": "Raspberry Pi FastAPI running"}

@app.get("/esp/latest")
def get_latest():
    """ESP32가 보낸 최근 데이터를 반환"""
    return JSONResponse({"latest_data": received_data})


# -------------------------------
# 🚀 이동 제어 명령
# -------------------------------
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
# 🌬️ 팬 제어 명령
# -------------------------------
@app.post("/fan/{speed}")
def fan_command(speed: int):
    """
    선풍기 모터 속도 제어 (0~255)
    """
    speed = max(0, min(speed, 255))
    ok = send_command(f"FAN {speed}")
    return {"sent": f"FAN {speed}", "status": "ok" if ok else "error"}


# -------------------------------
# 💬 임의 문자열 전송 (테스트용)
# -------------------------------
@app.post("/esp/send/{msg}")
def send_to_esp(msg: str):
    """라즈베리 → ESP로 문자열 전송"""
    ok = send_command(msg)
    return {"sent": msg, "status": "ok" if ok else "error"}
