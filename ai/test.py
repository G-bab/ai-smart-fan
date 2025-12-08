import whisper
import sounddevice as sd
import numpy as np
import queue
import time
import tempfile
import scipy.io.wavfile as wav

# Whisper 모델 (GPU 있으면 large-v2, CPU면 small/medium 권장)
model = whisper.load_model("small")

SAMPLE_RATE = 16000
CHANNELS = 1
BLOCK_SECONDS = 0.5       # 오디오 블록 크기 (0.5초씩 읽기)
CHUNK_SECONDS = 3.0       # 이만큼 모이면 한 번 인식 (지연/정확도 트레이드오프)
VAD_THRESHOLD = 500       # 무음 감지 임계값 (환경에 맞춰 조정)
USE_VAD = True            # 간단 VAD 사용 토글

audio_q = queue.Queue()

def audio_callback(indata, frames, time_info, status):
    if status:
        print(f"⚠️ Audio status: {status}")
    # int16 → 큐에 넣기
    audio_q.put(indata.copy())

def is_speech(chunk_int16, threshold=VAD_THRESHOLD):
    # 절대 에너지로 간단한 VAD
    return np.mean(np.abs(chunk_int16)) > threshold

print("🎤 실시간 Whisper 시작 (종료: Ctrl+C)")
buffer = []

try:
    with sd.InputStream(samplerate=SAMPLE_RATE,
                        channels=CHANNELS,
                        dtype='int16',
                        blocksize=int(SAMPLE_RATE * BLOCK_SECONDS),
                        callback=audio_callback):
        last_transcribe = time.time()
        while True:
            # 큐에서 블록 가져와 버퍼에 축적
            while not audio_q.empty():
                block = audio_q.get()
                buffer.append(block)

            # 누적 길이 확인
            total_samples = sum(b.shape[0] for b in buffer)
            if total_samples >= int(SAMPLE_RATE * CHUNK_SECONDS):
                # 버퍼 병합
                audio_chunk = np.concatenate(buffer, axis=0).flatten()
                buffer.clear()

                # VAD로 무음이면 스킵
                if USE_VAD and not is_speech(audio_chunk):
                    # 무음이면 너무 오래 스킵하지 않도록 소량만 유지
                    continue

                # int16 → float32 정규화
                audio_f32 = audio_chunk.astype(np.float32) / 32768.0
                # 레벨 노멀라이즈
                max_amp = np.max(np.abs(audio_f32)) + 1e-8
                audio_f32 = audio_f32 / max_amp

                # Whisper는 파일 경로 입력이 편하니 임시 WAV로 저장 후 호출
                with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
                    wav.write(f.name, SAMPLE_RATE, (audio_f32 * 32767).astype(np.int16))
                    result = model.transcribe(
                        f.name,
                        language="ko",
                        task="transcribe",
                        fp16=False,
                        temperature=0.0,
                        beam_size=5,
                        best_of=5,
                        no_speech_threshold=0.2,
                        logprob_threshold=-1.0
                    )
                text = result.get("text", "").strip()
                if text:
                    print(f"🗣️ {text}")
                else:
                    print("🔇 (무음 또는 저신뢰 발화)")

            # 너무 바쁘지 않게 약간 쉼
            time.sleep(0.01)

except KeyboardInterrupt:
    print("\n🛑 실시간 인식 종료")