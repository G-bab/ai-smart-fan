from ultralytics import YOLO
import cv2

# 커스텀 모델 로드
model = YOLO("ai/human_detect.pt")  # 모델 파일은 ai 폴더에 위치

# 노트북 내장 카메라 열기
cap = cv2.VideoCapture(0)

print("📷 사람 인식 시작... (종료: Q 키)")

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    # 추론 실행
    results = model.predict(source=frame, conf=0.5, verbose=False)

    # 바운딩 박스 시각화
    annotated_frame = results[0].plot()
    cv2.imshow("YOLOv8 Human Detection", annotated_frame)

    # Q 키 누르면 종료
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()