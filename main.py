from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "AI 스마트 선풍기 백엔드 실행 중!"}