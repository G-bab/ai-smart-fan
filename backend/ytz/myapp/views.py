from rest_framework import viewsets, status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.utils import timezone
from .models import User, Device, SensorData, FilterStatus
from .serializer import UserSerializer, DeviceSerializer, SensorDataSerializer, FilterStatusSerializer

# 사용자 CRUD
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

# 선풍기 기기 CRUD + 제어 관련
class DeviceViewSet(viewsets.ModelViewSet):
    queryset = Device.objects.all()
    serializer_class = DeviceSerializer

    # 커스텀 제어 (풍속/전원/각도)
    def partial_update(self, request, *args, **kwargs):
        device = self.get_object()
        fan_speed = request.data.get("fan_speed")
        power_state = request.data.get("power_state")
        angle = request.data.get("angle")

        if fan_speed is not None:
            device.fan_speed = fan_speed
        if power_state is not None:
            device.power_state = power_state
        if angle is not None:
            device.angle = angle

        device.last_sync = timezone.now()
        device.save()
        return Response(DeviceSerializer(device).data)

# 센서 데이터 저장 (라즈베리파이 → 서버)
class SensorDataViewSet(viewsets.ModelViewSet):
    queryset = SensorData.objects.all().order_by('-created_at')
    serializer_class = SensorDataSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)

        # 추가: AI 제어 알고리즘 트리거
        device = serializer.validated_data.get('device')
        if not device:
            return Response({"error": "device field is required"}, status=400)
        temp = serializer.validated_data['temperature']
        humidity = serializer.validated_data['humidity']

        # 풍속 자동 조절 로직 (예시)
        if temp > 30:
            device.fan_speed = 3
        elif temp > 25:
            device.fan_speed = 2
        else:
            device.fan_speed = 1

        device.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)

# 공기청정 필터 상태
class FilterStatusViewSet(viewsets.ModelViewSet):
    queryset = FilterStatus.objects.all().order_by('-updated_at')
    serializer_class = FilterStatusSerializer

# AI 기반 풍속·회전 제어 API
@api_view(['POST'])
def control_fan(request):
    """
    사용자의 위치 좌표, 온습도, 음성 명령을 기반으로
    팬 풍속 및 회전각 자동 조절
    """
    mode = request.data.get("mode")  # auto / follow / manual
    user_x = request.data.get("user_x")
    temperature = request.data.get("temperature")
    voice = request.data.get("voice_command")  # ✅ 추가된 부분

    # 음성 명령 처리 (선택적으로 로그 or 제어에 반영)
    if voice:
        print(f"[VOICE CMD] {voice}")
        # 예: 음성으로 'off'라고 하면 선풍기 정지
        if voice.lower() in ["off", "꺼", "정지"]:
            return Response({
                "message": "Fan turned off by voice command",
                "power_state": False
            }, status=status.HTTP_200_OK)

    # 단순한 예시 제어 로직
    response = {"mode": mode, "angle": None, "fan_speed": None}

    if mode == "follow" and user_x is not None:
        # 사용자 위치에 따라 회전각도 조절
        angle = max(0, min(180, float(user_x)))
        response["angle"] = angle

    if temperature:
        if temperature > 30:
            response["fan_speed"] = 3
        elif temperature > 25:
            response["fan_speed"] = 2
        else:
            response["fan_speed"] = 1

    return Response(response, status=status.HTTP_200_OK)

# 고온 경고 / 배터리 부족 알림
@api_view(['POST'])
def send_alert(request):
    """
    특정 이벤트 발생 시 사용자에게 알림 전송
    (ex. 고온 경고, 배터리 부족)
    """
    event = request.data.get("event")
    device_id = request.data.get("device_id")

    # 여기에 WebSocket / MQTT 연동 가능
    print(f"[ALERT] {device_id} - {event}")
    return Response({"message": f"Alert '{event}' sent for {device_id}"})
