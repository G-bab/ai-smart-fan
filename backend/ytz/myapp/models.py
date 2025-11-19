# myapp/models.py
from django.db import models

class User(models.Model):
    user_id = models.CharField(max_length=50, primary_key=True)
    device_id = models.CharField(max_length=50, null=True, blank=True)
    password = models.CharField(max_length=255)
    name = models.CharField(max_length=100)
    birth_date = models.DateField(null=True, blank=True)
    is_admin = models.BooleanField(default=False)  # 관리자 여부

    def __str__(self):
        return self.name


class Device(models.Model):
    device_id = models.CharField(max_length=50, primary_key=True)
    battery_level = models.IntegerField(default=100)
    ip_address = models.CharField(max_length=100, null=True, blank=True)
    power_state = models.BooleanField(default=False)  # 전원 ON/OFF
    fan_speed = models.IntegerField(default=1)  # 풍속 단계
    angle = models.FloatField(default=0)  # 회전 각도
    last_sync = models.DateTimeField(auto_now=True)  # 마지막 통신 시간

    user = models.ForeignKey('User', on_delete=models.CASCADE, null=True, blank=True)

    def __str__(self):
        return f"{self.device_id} ({'ON' if self.power_state else 'OFF'})"


class SensorData(models.Model):
    sensor_id = models.AutoField(primary_key=True)
    device = models.ForeignKey('Device', on_delete=models.CASCADE, null=True, blank=True)

    temperature = models.FloatField(null=True, blank=True)
    humidity = models.FloatField(null=True, blank=True)
    dust_density = models.FloatField(null=True, blank=True)
    co2_level = models.FloatField(null=True, blank=True)
    ir_detected = models.BooleanField(default=False)
    heatmap_temp = models.FloatField(null=True, blank=True)

    network_sync = models.BooleanField(default=True)                # 네트워크 동기화 상태
    part_connected = models.BooleanField(default=True)              # 각 파트 연결 여부
    user_detected = models.IntegerField(default=0)                  # 사용자 감지 여부(1=감지됨, 0=없음)
    voice_command = models.CharField(max_length=100, null=True, blank=True)  # 음성 명령

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.device.device_id} | {self.created_at}"


class FilterStatus(models.Model):
    filter_id = models.AutoField(primary_key=True)
    device = models.ForeignKey('Device', on_delete=models.CASCADE, null=True, blank=True)
    dust_accumulated = models.FloatField(default=0.0)
    condition = models.CharField(max_length=50, default="Good")
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Filter {self.device.device_id}: {self.condition}"
