# main.py
from fastapi import FastAPI
from fastapi.responses import JSONResponse
import serial
import threading
import time

app = FastAPI(title="Raspberry Pi - ESP32 Bridge")

# ---- 시리얼 설정 ----
# ESP32가 /dev/ttyUSB0 (또는 COM3 등)에 연결되어 있다면:
try:
    ser = serial.Serial("/dev/ttyUSB0", baudrate=115200, timeout=1)
except Exception as e:
    print("ESP 시리얼 포트 열기 실패:", e)
    ser = None

# ---- 백그라운드 리스너 ----
received_data = ""

def read_serial():
    global received_data
    if not ser:
        return
    while True:
        try:
            line = ser.readline().decode().strip()
            if line:
                received_data = line
                print(f"ESP -> RPi: {line}")
        except Exception:
            time.sleep(0.5)

if ser:
    threading.Thread(target=read_serial, daemon=True).start()

# ---- API 엔드포인트 ----

@app.get("/")
def root():
    return {"status": "Raspberry Pi FastAPI running"}

@app.get("/esp/latest")
def get_latest():
    """ESP가 보낸 최근 데이터를 반환"""
    return JSONResponse({"latest_data": received_data})

@app.post("/esp/send/{msg}")
def send_to_esp(msg: str):
    """라즈베리 → ESP로 문자열 전송"""
    if ser:
        ser.write((msg + "\n").encode())
        return {"sent": msg}
    return {"error": "Serial port not connected"}