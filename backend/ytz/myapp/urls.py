from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    TeamViewSet, UserViewSet, DeviceViewSet,
    TeamUserViewSet, TeamDeviceViewSet,
    SensorDataViewSet, FilterStatusViewSet,
    control_fan, send_alert,
    register_user, login_user,
    create_team, join_team, track_user
)

router = DefaultRouter()
router.register(r'teams', TeamViewSet)
router.register(r'users', UserViewSet)
router.register(r'devices', DeviceViewSet)
router.register(r'team-users', TeamUserViewSet)
router.register(r'team-devices', TeamDeviceViewSet)
router.register(r'sensors', SensorDataViewSet)
router.register(r'filters', FilterStatusViewSet)

urlpatterns = [
    # --- CRUD 기본 라우트 ---
    path('', include(router.urls)),

    # --- 인증 (회원가입/로그인) ---
    path('auth/register/', register_user, name='register'),
    path('auth/login/', login_user, name='login'),

    # --- 팀 관련 ---
    path('team/create/', create_team, name='create_team'),
    path('team/join/', join_team, name='join_team'),

    # --- AI/제어 기능 ---
    path('ai/control/', control_fan, name='control_fan'),
    path('ai/track/', track_user, name='track_user'),

    # --- 알림 ---
    path('alert/', send_alert, name='send_alert'),
]
