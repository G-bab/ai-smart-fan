import cv2
import numpy as np
import time
import os
from ultralytics import YOLO

# -------------------------------
# 색상 특징 추출 함수
# -------------------------------
def get_color_feature(image):
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    hist = cv2.calcHist([hsv], [0, 1], None, [50, 60], [0, 180, 0, 256])
    cv2.normalize(hist, hist)
    return hist

# -------------------------------
# 등록 단계 (앞/뒤/좌/우 자동 촬영)
# -------------------------------
def register_person(model, cap):
    directions = ["Front", "Back", "Left", "Right"]
    base_features = []

    for direction in directions:
        print(f"📸 {direction} 촬영 준비... 5초 대기")

        # 5초 동안 실시간 화면 표시
        start_time = time.time()
        while time.time() - start_time < 5:
            ret, frame = cap.read()
            if not ret:
                continue
            cv2.putText(frame, f"{direction}", (30, 30),
                        cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 255), 2)
            cv2.imshow("ai-smart-fan", frame)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                return []

        # 5초 후 촬영
        ret, frame = cap.read()
        if not ret:
            continue

        results = model.predict(source=frame, conf=0.5, verbose=False)
        if len(results[0].boxes) == 0:
            print("❌ 사람이 감지되지 않았습니다. 다시 시도하세요.")
            continue

        # 첫 번째 사람 ROI 추출
        x1, y1, x2, y2 = map(int, results[0].boxes[0].xyxy[0])
        roi = frame[y1:y2, x1:x2]

        # 특징 추출
        feature = get_color_feature(roi)
        base_features.append(feature)

        # 촬영 결과 1초 보여주기
        cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
        cv2.putText(frame, f"{direction} Registered", (x1, y1-10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0,255,0), 2)
        cv2.putText(frame, "Person", (x1, y2+30),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0,255,0), 2)
        cv2.imshow("ai-smart-fan", frame)
        cv2.waitKey(1000)

    # ai 폴더 안에 저장
    os.makedirs("ai", exist_ok=True)
    np.save("ai/base_features.npy", base_features)
    print("✅ 등록 완료: 네 방향 특징 저장됨")
    return base_features

# -------------------------------
# 추적 단계 (등록된 사람만 표시 + 10초마다 동적 특징 업데이트)
# -------------------------------
def track_registered_person(model, cap, base_features):
    print("📷 등록된 사람만 트래킹 시작... (종료: Q 키)")

    dynamic_features = []  # 별도 관리 (최대 20장)
    last_capture_time = time.time()
    last_print_time = time.time()  # 중앙 좌표 출력용

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        h, w = frame.shape[:2]  # 프레임 크기
        center_x, center_y = w // 2, h // 2  # 화면 중앙

        results = model.predict(source=frame, conf=0.5, verbose=False)

        best_sim = 0
        best_box = None
        best_roi = None

        for box in results[0].boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            roi = frame[y1:y2, x1:x2]
            current_feature = get_color_feature(roi)

            # base_features + dynamic_features 모두 비교
            all_features = base_features + dynamic_features
            sims = [cv2.compareHist(f, current_feature, cv2.HISTCMP_CORREL) for f in all_features]
            max_sim = max(sims) if sims else 0  # 평균 대신 최대값 사용

            if max_sim > best_sim:
                best_sim = max_sim
                best_box = (x1, y1, x2, y2)
                best_roi = roi

        # 등록된 사람만 표시
        if best_box and best_sim > 0.7:
            x1, y1, x2, y2 = best_box
            cx, cy = (x1 + x2) // 2, (y1 + y2) // 2  # 바운딩박스 중앙
            rel_x, rel_y = cx - center_x, cy - center_y  # 화면 중앙 기준 좌표

            cv2.rectangle(frame, (x1, y1), (x2, y2), (0,255,0), 2)
            cv2.putText(frame, "Registered Person", (x1, y1-10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0,255,0), 2)
            cv2.putText(frame, "Person", (x1, y2+30),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0,255,0), 2)

            # 1초마다 중앙 좌표 출력 (화면 중앙 기준)
            if time.time() - last_print_time > 1:
                print(f"📍 중앙 기준 좌표: ({rel_x}, {rel_y})")
                last_print_time = time.time()

            # 10초마다 새로운 특징 추가
            if time.time() - last_capture_time > 10 and best_sim > 0.8:  # 검증 조건 강화
                new_feature = get_color_feature(best_roi)
                dynamic_features.append(new_feature)
                if len(dynamic_features) > 20:
                    dynamic_features.pop(0)  # 오래된 특징 삭제
                last_capture_time = time.time()
                print(f"📸 새로운 특징 추가 (동적 {len(dynamic_features)}장 유지 중)")

        cv2.imshow("ai-smart-fan", frame)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

# -------------------------------
# 메인 실행
# -------------------------------
if __name__ == "__main__":
    model = YOLO("ai/human_detect.pt")
    cap = cv2.VideoCapture(0)

    # 등록 단계 실행
    base_features = register_person(model, cap)

    # 추적 단계 실행
    if base_features:
        track_registered_person(model, cap, base_features)