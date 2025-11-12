import whisper
import sounddevice as sd
import numpy as np
import tempfile
import scipy.io.wavfile as wav
import time

# Whisper base 모델 로드
model = whisper.load_model("base")  # base, small, medium, large 중 선택 가능

# 설정
duration = 5  # 녹음 시간 (초)
sample_rate = 16000

print("🎤 Whisper 음성 인식 시작 (5초마다 반복)... 종료하려면 Ctrl+C")

try:
    while True:
        print("\n🕒 녹음 중... 말해주세요!")
        audio = sd.rec(int(duration * sample_rate), samplerate=sample_rate, channels=1, dtype='int16')
        sd.wait()

        # 임시 WAV 파일로 저장
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
            wav.write(f.name, sample_rate, audio)
            print("🧠 Whisper 인식 중...")
            result = model.transcribe(
                f.name,
                language="ko",         # 한국어 고정
                task="transcribe",     # 번역이 아닌 음성 → 텍스트
                fp16=False             # GPU 없을 때 안정성 향상
            )
            print("🗣️ 인식된 텍스트:", result["text"])

        time.sleep(0.5)  # 약간의 텀
except KeyboardInterrupt:
    print("\n🛑 음성 인식 종료됨")