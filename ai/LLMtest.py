import requests
import json

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "qwen2.5:3b-instruct"

SYSTEM_PROMPT = """
너는 선풍기 음성 명령을 JSON으로 변환하는 AI다.

절대 규칙:
1. 반드시 JSON만 출력한다
2. 필요한 키만 출력한다
3. null, 빈 배열, 불필요한 키 절대 출력 금지 (타이머 취소 명령에만 "timer_hours": null 값 출력)
4. 설명, 문장, 주석 출력 금지
5. 추측 금지

[밑의 5개에 대해 궁금해 한다면 query로 출력할 것]
- temperature
- humidity
- battery
- air_quality
- fan_speed

query에는 위 5개의 값만 들어갈 수 있다.

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
- 회전 → { "mode": "rotate" }
- 따라와 / 따라오기 → { "mode": "follow" }
- 자동 추적 → { "mode": "tracking" }

[타이머]
- N시간 뒤 꺼줘 / N시간 타이머 → { "timer_hours": N }

[상태 질문]
- 온도 → temperature
- 습도 → humidity
- 온습도 → temperature, humidity
- 배터리 → battery
- 공기질 → air_quality
- 현재 세기 / 지금 세기 → fan_speed

출력 예:
{ "query": ["temperature", "humidity"] }
"""

def parse_command(text: str):
    payload = {
        "model": MODEL,
        "prompt": f"{SYSTEM_PROMPT}\n\n입력: {text}",
        "stream": False
    }

    response = requests.post(OLLAMA_URL, json=payload)
    response.raise_for_status()

    result_text = response.json()["response"].strip()

    try:
        return json.loads(result_text)
    except json.JSONDecodeError:
        print("❌ JSON 파싱 실패")
        print("LLM 원본 출력:")
        print(result_text)
        return None


if __name__ == "__main__":
    print("🎤 선풍기 명령 입력 (exit 입력 시 종료)")
    while True:
        user_input = input("\n> ")
        if user_input.lower() == "exit":
            break

        result = parse_command(user_input)
        print("🧠 LLM 출력:")
        print(json.dumps(result, indent=2, ensure_ascii=False))
