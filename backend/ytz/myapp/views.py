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

import requests
from django.conf import settings

# AI 서버
AI_SERVER_URL = getattr(settings, "AI_SERVER_URL", "http://localhost:8001/llm/run")
def call_ai_server(text: str) -> dict:
    try:
        res = requests.post(
            AI_SERVER_URL,
            json={"text": text},
            timeout=3
        )
        return res.json()
    except Exception as e:
        return {"action": "error", "message": str(e)}

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

    # 센서 데이터 권한 필터링
    def get_queryset(self):
        user_id = self.request.query_params.get("user_id")
        team_id = self.request.query_params.get("team_id")

        qs = SensorData.objects.all().order_by('-created_at')

        # 필수 파라미터 없으면 차단
        if not user_id or not team_id:
            return SensorData.objects.none()

        team_user = TeamUser.objects.filter(
            user__user_id=user_id,
            team__team_id=team_id
        ).first()

        if not team_user:
            return SensorData.objects.none()

        # 일반 user → 팀에 속한 디바이스 센서만
        if team_user.role == "user":
            return qs.filter(
                device__teamdevice__team__team_id=team_id
            )

        # admin / sub_admin → 전체 조회
        return qs

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
    device_id = request.data.get("device_id")
    voice = request.data.get("voice_command")

    device = Device.objects.filter(device_id=device_id).first()
    if not device:
        return Response({"error": "디바이스 없음"}, status=404)

    if not voice:
        return Response({"error": "음성명령 없음"}, status=400)

    ai_result = call_ai_server(voice)

    action = ai_result.get("action")

    # AI 서버 에러
    if action == "error":
        return Response({
            "error": "AI 서버 오류",
            "detail": ai_result.get("message")
        }, status=502)

    # 처리할 명령 없음
    if action == "none":
        return Response({
            "message": "처리할 명령이 없습니다.",
            "ai_result": ai_result
        }, status=200)

    # AI 오류
    VALID_ACTIONS = {"off", "on", "rotate", "none"}

    if action not in VALID_ACTIONS:
        return Response({
            "error": "알 수 없는 AI action",
            "action": action
        }, status=400)

    # 실제 제어 로직
    fan_speed = ai_result.get("fan_speed")
    angle = ai_result.get("angle")

    if action == "off":
        device.power_state = False

    elif action == "on":
        device.power_state = True
        if fan_speed is not None:
            device.fan_speed = fan_speed

    elif action == "rotate":
        if angle is not None:
            device.angle = angle

    device.last_sync = timezone.now()
    device.save()

    return Response({
        "message": "AI 명령 처리 완료",
        "device": DeviceSerializer(device).data,
        "ai_result": ai_result
    })

@api_view(['POST'])
def send_alert(request):
    """
    알림 전송 (고온, 배터리 부족 등)
    """
    event = request.data.get("event")
    device_id = request.data.get("device_id")
    print(f"[ALERT] {device_id} - {event}")
    return Response({"message": f"Alert '{event}' sent for {device_id}"})

# 디바이스 등록
@api_view(['POST'])
def register_device(request):
    device_id = request.data.get("device_id")
    ip_address = request.data.get("ip_address")
    battery_level = request.data.get("battery_level")

    if not device_id:
        return Response({"error": "device_id 필수"}, status=400)

    device, created = Device.objects.update_or_create(
        device_id=device_id,
        defaults={
            "ip_address": ip_address,
            "battery_level": battery_level,
            "last_sync": timezone.now(),
            "power_state": False,
            "fan_speed": 1,
            "angle": 0.0,
        }
    )

    return Response({
        "message": "device registered" if created else "device updated",
        "device_id": device.device_id
    })

# ------------------------
# 사용자 인증 (회원가입)
# ------------------------
from django.contrib.auth.hashers import make_password, check_password

@api_view(['POST'])
def register_user(request):
    """회원가입"""
    user_id = request.data.get("user_id")
    password = request.data.get("password")
    name = request.data.get("name")
    birth_date = request.data.get("birth_date")

    if not all([user_id, password, name, birth_date]):
        return Response(
            {"error": "아이디, 비밀번호, 이름, 생년월일은 필수입니다."},
            status=400
        )

    if User.objects.filter(user_id=user_id).exists():
        return Response(
            {"error": "이미 존재하는 아이디입니다."},
            status=400
        )

    user = User.objects.create(
        user_id=user_id,
        password=make_password(password),
        name=name,
        birth_date=birth_date
    )

    return Response(
        {
            "message": "회원가입 성공",
            "user_id": user.user_id
        },
        status=201
    )

# ------------------------
# 팀 생성 / 참가
# ------------------------
@api_view(['POST'])
def create_team(request):
    team_name = request.data.get("team_name")
    team_password = request.data.get("team_password")
    user_id = request.data.get("user_id")
    device_id = request.data.get("device_id")

    user = User.objects.filter(user_id=user_id).first()
    device = Device.objects.filter(device_id=device_id).first()

    if not user:
        return Response({"error": "사용자 없음"}, status=400)

    if not device:
        return Response({"error": "등록되지 않은 디바이스입니다. 먼저 기기를 켜주세요."}, status=400)

    if TeamDevice.objects.filter(device=device).exists():
        return Response({"error": "이미 다른 팀에 등록된 디바이스"}, status=400)

    team = Team.objects.create(
        team_name=team_name,
        team_password=team_password
    )

    TeamUser.objects.create(
        team=team,
        user=user,
        role="admin"
    )

    TeamDevice.objects.create(team=team, device=device)

    return Response({
        "message": "팀 생성 완료",
        "role": "admin"
    })


@api_view(['POST'])
def join_team(request):
    team_name = request.data.get("team_name")
    team_password = request.data.get("team_password")
    user_id = request.data.get("user_id")

    team = Team.objects.filter(team_name=team_name).first()
    user = User.objects.filter(user_id=user_id).first()

    if not team or not user:
        return Response({"error": "팀 또는 사용자 없음"}, status=404)

    if team.team_password != team_password:
        return Response({"error": "팀 비밀번호 불일치"}, status=403)

    if TeamUser.objects.filter(team=team, user=user).exists():
        return Response({"error": "이미 팀에 소속됨"}, status=400)

    TeamUser.objects.create(
        team=team,
        user=user,
        role="user"
    )

    return Response({"message": "팀 참가 완료", "role": "user"})

# 로그인
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


# 아이디 찾기 (이름, 생년월일 일치 시)
@api_view(['POST'])
def find_user_id(request):
    name = request.data.get("name")
    birth_date = request.data.get("birth_date")

    if not name or not birth_date:
        return Response(
            {"error": "이름과 생년월일을 입력해야 합니다."},
            status=400
        )

    user = User.objects.filter(
        name=name,
        birth_date=birth_date
    ).first()

    if not user:
        return Response(
            {"error": "일치하는 사용자가 없습니다."},
            status=404
        )

    return Response({
        "user_id": user.user_id
    })

# 비밀번호 재설정 (이름, 생년월일, id 일치 시)
@api_view(['POST'])
def reset_password(request):
    user_id = request.data.get("user_id")
    name = request.data.get("name")
    birth_date = request.data.get("birth_date")
    new_password = request.data.get("new_password")

    if not all([user_id, name, birth_date, new_password]):
        return Response(
            {"error": "모든 정보를 입력해야 합니다."},
            status=400
        )

    user = User.objects.filter(
        user_id=user_id,
        name=name,
        birth_date=birth_date
    ).first()

    if not user:
        return Response(
            {"error": "입력한 정보가 일치하지 않습니다."},
            status=404
        )

    user.password = make_password(new_password)
    user.save()

    return Response({
        "message": "비밀번호가 성공적으로 재설정되었습니다."
    })

# 팀 목록 조회
@api_view(["GET"])
def get_my_teams(request):
    user_id = request.query_params.get("user_id")
    if not user_id:
        return Response({"error": "user_id는 필수입니다."}, status=400)

    # user 존재 확인
    user = User.objects.filter(user_id=user_id).first()
    if not user:
        return Response({"error": "사용자 없음"}, status=404)

    team_users = TeamUser.objects.filter(user=user).select_related("team")

    result = []
    for tu in team_users:
        result.append({
            "team_id": tu.team.team_id,
            "team_name": tu.team.team_name,
            "role": tu.role
        })

    return Response({"teams": result}, status=200)

# 팀별 권한 분리
@api_view(['GET'])
def get_my_role(request):
    user_id = request.query_params.get("user_id")
    team_id = request.query_params.get("team_id")

    team_user = TeamUser.objects.filter(
        user__user_id=user_id,
        team__team_id=team_id
    ).first()

    if not team_user:
        return Response({"error": "접근 권한 없음"}, status=403)

    return Response({"role": team_user.role})

#------------------------------
# admin 전용 기능
#------------------------------
# sub_admin 권한 부여 및 회수
@api_view(['POST'])
def set_sub_admin(request):
    admin_id = request.data.get("admin_id")
    team_user_id = request.data.get("team_user_id")

    team_user = TeamUser.objects.filter(team_user_id=team_user_id).first()
    if not team_user:
        return Response({"error": "대상 사용자가 없습니다."}, status=404)

    admin = TeamUser.objects.filter(
        user__user_id=admin_id,
        team=team_user.team,
        role="admin"
    ).first()

    if not admin:
        return Response({"error": "권한 없음"}, status=403)

    team_user.role = "sub_admin"
    team_user.save()

    return Response({"message": "sub_admin 권한 부여 완료"})

#------------------------------
# admin 전용 기능
#------------------------------
# 팀 비밀번호 확인 및 변경 기능
@api_view(['POST'])
def team_password(request):
    admin_id = request.data.get("admin_id")
    team_id = request.data.get("team_id")
    new_password = request.data.get("new_password")  # optional

    # admin 권한 확인
    admin = TeamUser.objects.filter(
        user__user_id=admin_id,
        team__team_id=team_id,
        role="admin"
    ).first()

    if not admin:
        return Response({"error": "관리자만 접근 가능합니다."}, status=403)

    team = admin.team

    # 비밀번호 변경 요청이 있는 경우
    if new_password:
        team.team_password = new_password
        team.save()
        return Response({
            "message": "팀 비밀번호가 변경되었습니다.",
            "team_password": team.team_password
        })

    # 조회만 하는 경우
    return Response({
        "team_password": team.team_password
    })

#-------------------------
# admin, sub_admin 기능
# 팀원 삭제
@api_view(['POST'])
def remove_team_user(request):
    """
    팀원 삭제 (admin, sub_admin)
    """
    requester_id = request.data.get("requester_id")
    team_id = request.data.get("team_id")
    target_user_id = request.data.get("target_user_id")

    requester = TeamUser.objects.filter(
        user__user_id=requester_id,
        team__team_id=team_id,
        role__in=["admin", "sub_admin"]
    ).first()

    if not requester:
        return Response({"error": "권한이 없습니다."}, status=403)

    target = TeamUser.objects.filter(
        user__user_id=target_user_id,
        team__team_id=team_id
    ).first()

    if not target:
        return Response({"error": "삭제할 사용자를 찾을 수 없습니다."}, status=404)

    if target.role == "admin":
        return Response(
            {"error": "관리자는 삭제할 수 없습니다."},
            status=400
        )

    target.delete()
    return Response({"message": "팀원이 삭제되었습니다."})
