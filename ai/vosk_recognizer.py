from vosk import Model, KaldiRecognizer
import pyaudio
import json

# 모델 경로 설정
model_path = "ai/vosk-model-small-ko-0.22"
model = Model(model_path)
rec = KaldiRecognizer(model, 16000)

# 마이크 입력 설정
p = pyaudio.PyAudio()

# 기본 입력 장치 사용 (노트북 내장 마이크)
stream = p.open(format=pyaudio.paInt16,
                channels=1,
                rate=16000,
                input=True,
                frames_per_buffer=8000)
stream.start_stream()

print("🎤 음성 명령을 말하세요...")

try:
    while True:
        data = stream.read(4000, exception_on_overflow=False)
        if rec.AcceptWaveform(data):
            result = json.loads(rec.Result())
            print("🗣️ 인식된 텍스트:", result['text'])
except KeyboardInterrupt:
    print("\n🛑 종료됨")
    stream.stop_stream()
    stream.close()
    p.terminate()