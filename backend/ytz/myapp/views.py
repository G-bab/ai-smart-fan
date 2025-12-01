from rest_framework import viewsets, status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.utils import timezone
from .models import (
    Team, User, Device, TeamUser, TeamDevice,
    SensorData, FilterStatus
)
from .serializer import (
    TeamSerializer, UserSerializer, DeviceSerializer,
    TeamUserSerializer, TeamDeviceSerializer,
    SensorDataSerializer, FilterStatusSerializer
)


# ------------------------
# 기본 CRUD 뷰셋
# ------------------------

class TeamViewSet(viewsets.ModelViewSet):
    queryset = Team.objects.all()
    serializer_class = TeamSerializer

    def destroy(self, request, *args, **kwargs):
        user_id = request.query_params.get("user_id")
        team_id = kwargs.get("pk")

        # 해당 유저의 역할 확인
        team_user = TeamUser.objects.filter(user__user_id=user_id, team__team_id=team_id).first()
        if not team_user or team_user.role != "admin":
            return Response({"error": "관리자만 팀을 삭제할 수 있습니다."}, status=403)

        # 팀 삭제
        team = self.get_object()
        team.delete()
        return Response({"message": "팀이 삭제되었습니다."}, status=200)


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer


class DeviceViewSet(viewsets.ModelViewSet):
    queryset = Device.objects.all()
    serializer_class = DeviceSerializer

    def partial_update(self, request, *args, **kwargs):
        """선풍기 수동 제어 (전원, 풍속, 각도 등)"""
        device = self.get_object()
        for field in ["fan_speed", "power_state", "angle"]:
            if field in request.data:
                setattr(device, field, request.data[field])
        device.last_sync = timezone.now()
        device.save()
        return Response(DeviceSerializer(device).data)


class TeamUserViewSet(viewsets.ModelViewSet):
    queryset = TeamUser.objects.all()
    serializer_class = TeamUserSerializer


class TeamDeviceViewSet(viewsets.ModelViewSet):
    queryset = TeamDevice.objects.all()
    serializer_class = TeamDeviceSerializer


class SensorDataViewSet(viewsets.ModelViewSet):
    queryset = SensorData.objects.all().order_by('-created_at')
    serializer_class = SensorDataSerializer

    def create(self, request, *args, **kwargs):
        """라즈베리파이 → 서버로 센서 데이터 업로드"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)

        device = serializer.validated_data.get('device')
        if device:
            temp = serializer.validated_data.get('temperature')
            # 온도 기반 자동 풍속 제어
            if temp:
                if temp > 30:
                    device.fan_speed = 3
                elif temp > 25:
                    device.fan_speed = 2
                else:
                    device.fan_speed = 1
                device.last_sync = timezone.now()
                device.save()

        return Response(serializer.data, status=status.HTTP_201_CREATED)


class FilterStatusViewSet(viewsets.ModelViewSet):
    queryset = FilterStatus.objects.all().order_by('-filter_id')
    serializer_class = FilterStatusSerializer


# ------------------------
# 추가 제어 기능 (AI / 음성 / 알림)
# ------------------------

@api_view(['POST'])
def control_fan(request):
    """
    AI 기반 풍속·회전 제어 (온도, 위치, 음성 명령 포함)
    """
    mode = request.data.get("mode")  # auto / follow / manual
    user_x = request.data.get("user_x")
    temperature = request.data.get("temperature")
    voice = request.data.get("voice_command")

    # 음성 명령 처리
    if voice:
        print(f"[VOICE CMD] {voice}")
        if voice.lower() in ["off", "꺼", "정지"]:
            return Response({
                "message": "Fan turned off by voice command",
                "power_state": False
            }, status=status.HTTP_200_OK)

    # 제어 응답 데이터 구성
    response = {"mode": mode, "angle": None, "fan_speed": None}

    # 사용자 위치 기반 회전 제어
    if mode == "follow" and user_x is not None:
        response["angle"] = max(0, min(180, float(user_x)))

    # 온도 기반 풍속 조절
    if temperature:
        if temperature > 30:
            response["fan_speed"] = 3
        elif temperature > 25:
            response["fan_speed"] = 2
        else:
            response["fan_speed"] = 1

    return Response(response, status=status.HTTP_200_OK)


@api_view(['POST'])
def send_alert(request):
    """
    알림 전송 (고온, 배터리 부족 등)
    """
    event = request.data.get("event")
    device_id = request.data.get("device_id")
    print(f"[ALERT] {device_id} - {event}")
    return Response({"message": f"Alert '{event}' sent for {device_id}"})


# ------------------------
# 사용자 인증 (회원가입 / 로그인)
# ------------------------
from django.contrib.auth.hashers import make_password, check_password

@api_view(['POST'])
def register_user(request):
    """회원가입"""
    user_id = request.data.get("user_id")
    password = request.data.get("password")
    name = request.data.get("name")

    if not user_id or not password:
        return Response({"error": "아이디와 비밀번호는 필수입니다."}, status=400)

    if User.objects.filter(user_id=user_id).exists():
        return Response({"error": "이미 존재하는 아이디입니다."}, status=400)

    user = User.objects.create(
        user_id=user_id,
        password=make_password(password),
        name=name
    )
    return Response({"message": "회원가입 성공", "user_id": user.user_id}, status=201)


@api_view(['POST'])
def login_user(request):
    """로그인"""
    user_id = request.data.get("user_id")
    password = request.data.get("password")

    try:
        user = User.objects.get(user_id=user_id)
    except User.DoesNotExist:
        return Response({"error": "존재하지 않는 아이디입니다."}, status=400)

    if check_password(password, user.password):
        return Response({
            "message": "로그인 성공",
            "user_id": user.user_id,
            "name": user.name
        })
    else:
        return Response({"error": "비밀번호가 일치하지 않습니다."}, status=400)


# ------------------------
# 팀 생성 / 참가
# ------------------------
@api_view(['POST'])
def create_team(request):
    """팀 생성"""
    team_name = request.data.get("team_name")
    user_id = request.data.get("user_id")

    user = User.objects.filter(user_id=user_id).first()
    if not user:
        return Response({"error": "존재하지 않는 사용자입니다."}, status=400)

    team = Team.objects.create(team_name=team_name)
    TeamUser.objects.create(team=team, user=user, role="admin")

    return Response({
        "message": "팀 생성 완료",
        "team_id": team.team_id,
        "team_name": team.team_name,
        "admin": user.name
    }, status=201)


@api_view(['POST'])
def join_team(request):
    """팀 참가"""
    team_name = request.data.get("team_name")
    user_id = request.data.get("user_id")

    team = Team.objects.filter(team_name=team_name).first()
    if not team:
        return Response({"error": "존재하지 않는 팀입니다."}, status=404)

    user = User.objects.filter(user_id=user_id).first()
    if not user:
        return Response({"error": "존재하지 않는 사용자입니다."}, status=404)

    TeamUser.objects.create(team=team, user=user, role="common_user")
    return Response({"message": f"{user.name}님이 {team_name} 팀에 참가했습니다."})

