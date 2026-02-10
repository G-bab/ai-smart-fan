import requests
import json
import re

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "qwen2.5:3b-instruct"

SYSTEM_PROMPT = """
너는 선풍기 음성 명령을 JSON으로 변환하는 AI다.

절대 규칙:
1. 반드시 JSON만 출력한다
2. 필요한 키만 출력한다
3. null, 빈 배열, 불필요한 키 절대 출력 금지 (타이머 취소 명령에만 "timer": null 값 출력)
4. 설명, 문장, 주석 출력 금지
5. 추측 금지
6. "timer": 에 들어가는 숫자는 초 단위로 할 것 (1시간 타이머= 3600 / 1시간 반 = 5400 / 30분 = 1800)
7. 밑의 "{}" 안에 나와있는 값 형태만 출력 할 것
8. 모드의 출력 값은 true, false 가 아닌 반드시 1, 0 로만 표기할 것
9. 모드에 있는 회전, 팔로잉, 트래킹 구분 명확히 할 것

[밑의 6개에 대해 궁금해 한다면 query로 출력할 것]
- temperature
- humidity
- battery
- air_quality
- fan_speed
- timer

query에는 위 6개의 값만 들어갈 수 있다.

[상태 질문]
- 온도 → temperature
- 습도 → humidity
- 온습도 → temperature, humidity
- 배터리 → battery
- 공기질 → air_quality
- 현재 세기 / 지금 세기 → fan_speed
- 타이머 남은 시간 → timer

출력 예:
{ "query": ["temperature", "humidity"] }

[전원]
- 켜 / 켜줘 → { "power": "on" }
- 꺼 / 꺼줘 → { "power": "off" }

[풍속]
- 1단 / 1단계 → { "fan_speed": 1 }
- 2단 / 2단계 → { "fan_speed": 2 }
- 3단 / 3단계 → { "fan_speed": 3 }
- 더 세게 / 세게 / 더워 → { "fan_speed": "up" }
- 약하게 / 줄여 / 춥다 → { "fan_speed": "down" }
- 최대로 → { "fan_speed": "3" }
- 최소로 → { "fan_speed": "1" }

[모드]
- 회전 / 회전 켜줘 → { "rotate": 1 }
- 회전 그만 해 / 회전 정지 / 회전 종료 / 회전 멈춰 → { "rotate": 0 }

- 따라와 / 팔로잉 / 팔로잉 모드 / 따라오기 / 팔로잉 모드 켜줘→ { "follow": 1 }
- 그만 따라와 / 팔로잉 그만 / 팔로잉 정지 / 팔로잉 모드 정지 / 팔로잉 모드 그만 / 따라오기 정지 / 팔로잉 모드 해제 / 팔로잉 모드 꺼줘→ { "follow": 0 }

- 자동 추적 / 트래킹 / 트래킹 모드 / 트래킹 모드 켜줘 → { "tracking": 1 }
- 자동 추적 해제 / 트래킹 정지 / 트래킹 그만 / 트래킹 해제 / 트래킹 모드 해제 / 트래킹 모드 정지 / 트래킹 모드 그만 / 트래킹 모드 꺼줘 → { "tracking": 0 }


[타이머]
- N시간 뒤 꺼줘 / N시간 타이머 → { "timer": N*3600 }
- 타이머 취소 / 타이머 종료 / 타이머 꺼줘 → { "timer": null }

"""

def sanitize_json(text: str) -> str:
    text = re.sub(r'\bT\b', 'true', text)
    text = re.sub(r'\bF\b', 'false', text)
    text = re.sub(r'\bTrue\b', 'true', text)
    text = re.sub(r'\bFalse\b', 'false', text)
    return text

def parse_command(text: str):
    payload = {
        "model": MODEL,
        "prompt": f"{SYSTEM_PROMPT}\n\n입력: {text}",
        "stream": False
    }

    response = requests.post(OLLAMA_URL, json=payload)
    response.raise_for_status()

    raw = response.json()["response"].strip()
    sanitized = sanitize_json(raw)

    try:
        return json.loads(sanitized)
    except json.JSONDecodeError:
        print("❌ JSON 파싱 실패")
        print("LLM 원본 출력:")
        print(raw)
        print("🧠 LLM 출력:")
        print("null")
        return None


if __name__ == "__main__":
    print("🎤 선풍기 명령 입력 (exit 입력 시 종료)")
    while True:
        user_input = input("> ")
        if user_input.lower() == "exit":
            break

        result = parse_command(user_input)
        if result is not None:
            print(json.dumps(result, indent=2, ensure_ascii=False))
