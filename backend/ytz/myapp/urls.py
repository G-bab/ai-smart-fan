from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    UserViewSet, DeviceViewSet, SensorDataViewSet,
    FilterStatusViewSet, control_fan, send_alert
)

router = DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'devices', DeviceViewSet)
router.register(r'sensors', SensorDataViewSet)
router.register(r'filters', FilterStatusViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('devices/control/', control_fan),   # 풍향/풍속 제어
    path('devices/alert/', send_alert),      # 실시간 알림
]
