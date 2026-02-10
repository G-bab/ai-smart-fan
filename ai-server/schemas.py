from pydantic import BaseModel

class LLMRequest(BaseModel):
    text: str

class LLMResponse(BaseModel):
    action: str          # on / off / rotate / speed
    fan_speed: int | None = None
    angle: float | None = None
