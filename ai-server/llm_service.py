def run_llm(text: str) -> dict:
    text = text.lower()

    if "꺼" in text or "off" in text:
        return {
            "action": "off",
            "fan_speed": None,
            "angle": None
        }

    if "세게" in text or "강" in text:
        return {
            "action": "on",
            "fan_speed": 3,
            "angle": None
        }

    if "약" in text:
        return {
            "action": "on",
            "fan_speed": 1,
            "angle": None
        }

    if "왼쪽" in text:
        return {
            "action": "rotate",
            "fan_speed": None,
            "angle": 30
        }

    return {
        "action": "none",
        "fan_speed": None,
        "angle": None
    }
