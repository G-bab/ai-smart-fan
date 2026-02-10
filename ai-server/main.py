from fastapi import FastAPI
from schemas import LLMRequest, LLMResponse
from llm_service import run_llm

app = FastAPI(title="AI Smart Fan LLM Server")

@app.post("/llm/analyze", response_model=LLMResponse)
def analyze_command(req: LLMRequest):
    """
    Django → AI 서버
    """
    result = run_llm(req.text)
    return result
