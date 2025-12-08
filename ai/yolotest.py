import cv2
import time
from ultralytics import YOLO

# YOLO 모델 로드
model = YOLO("ai/human_detect.pt")

# 카메라 열기
cap = cv2.VideoCapture(0)

print("📷 YOLO 실행 + FPS 표시 시작... (종료: Q 키)")

# FPS 계산용 변수
prev_time = time.time()
fps = 0

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    # YOLO 예측
    results = model.predict(source=frame, conf=0.5, verbose=False)
    annotated_frame = results[0].plot()

    # FPS 계산
    cur_time = time.time()
    fps = 1 / (cur_time - prev_time)
    prev_time = cur_time

    # FPS 화면에 표시
    cv2.putText(annotated_frame, f"FPS: {int(fps)}", (30, 30),
                cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

    # 화면 출력
    cv2.imshow("ai-smart-fan", annotated_frame)

    # Q 키 누르면 종료
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()