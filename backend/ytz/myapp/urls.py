from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    TeamViewSet, UserViewSet, DeviceViewSet,
    TeamUserViewSet, TeamDeviceViewSet,
    SensorDataViewSet, FilterStatusViewSet,
    control_fan, send_alert, register_device,
    register_user, login_user, get_my_role,
    create_team, join_team, find_user_id, reset_password,
    set_sub_admin, remove_team_user,
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
    path('auth/find-id/', find_user_id, name='find_user_id'),
    path('auth/reset-password/', reset_password, name='reset_password'),

    # --- 팀 관련 ---
    path('device/register/', register_device, name='register_device'),

    path('team/create/', create_team, name='create_team'),
    path('team/join/', join_team, name='join_team'),
    path('team/my-role/', get_my_role, name='get_my_role'),
    path('team/set-sub-admin/', set_sub_admin, name='set_sub_admin'),
    path('team/remove-user/', remove_team_user, name='remove_team_user'),

    # --- AI/제어 기능 ---
    path('ai/control/', control_fan, name='control_fan'),

    # --- 알림 ---
    path('alert/', send_alert, name='send_alert'),
]
