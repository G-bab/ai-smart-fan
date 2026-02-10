from django.db import models


# ---------------------------
# 팀 (Team)
# ---------------------------
class Team(models.Model):
    team_id = models.AutoField(primary_key=True)
    team_name = models.CharField(
        max_length=100,
        default="default_team"
    )
    team_password = models.CharField(
        max_length=4,
        default="0000"
    )

    def __str__(self):
        return self.team_name


# ---------------------------
# 사용자 (User)
# ---------------------------
class User(models.Model):
    user_id = models.CharField(max_length=50, primary_key=True)  # Key
    password = models.CharField(max_length=255, null=True, blank=True)  # Field
    name = models.CharField(max_length=100, null=True, blank=True)  # Field2
    device_id = models.CharField(max_length=50, null=True, blank=True)  # Field3
    birth_date = models.DateField(null=True, blank=True)  # Field4

    def __str__(self):
        return self.name or self.user_id


# ---------------------------
# 선풍기 (Device)
# ---------------------------
class Device(models.Model):
    device_id = models.CharField(max_length=50, primary_key=True)  # Key
    battery_level = models.IntegerField(null=True, blank=True)  # Field
    ip_address = models.CharField(max_length=100, null=True, blank=True)  # Field2
    power_state = models.BooleanField(default=False)  # Field3
    fan_speed = models.IntegerField(default=1)  # Field4
    angle = models.FloatField(default=0.0)  # Field5
    last_sync = models.DateTimeField(auto_now=True)  # Field6

    def __str__(self):
        return f"{self.device_id} ({'ON' if self.power_state else 'OFF'})"


# ---------------------------
# 센서 데이터 (SensorData)
# ---------------------------
class SensorData(models.Model):
    sensor_id = models.AutoField(primary_key=True)  # Key
    device = models.ForeignKey(Device, on_delete=models.CASCADE)  # Key2 (FK)
    temperature = models.FloatField(null=True, blank=True)  # Field
    humidity = models.FloatField(null=True, blank=True)  # Field2
    dust_density = models.FloatField(null=True, blank=True)  # Field3
    co2_level = models.FloatField(null=True, blank=True)  # Field4
    ir_detected = models.BooleanField(default=False)  # Field5
    heatmap_temp = models.FloatField(null=True, blank=True)  # Field6
    created_at = models.DateTimeField(auto_now_add=True)  # Field7

    def __str__(self):
        return f"SensorData {self.sensor_id} ({self.device.device_id})"


# ---------------------------
# 공기청정 필터 상태 (FilterStatus)
# ---------------------------
class FilterStatus(models.Model):
    filter_id = models.AutoField(primary_key=True)  # Key
    device = models.ForeignKey(Device, on_delete=models.CASCADE)  # Key2 (FK)
    dust_accumulated = models.FloatField(null=True, blank=True)  # Field
    condition = models.CharField(max_length=50, null=True, blank=True)  # Field2

    def __str__(self):
        return f"FilterStatus({self.device.device_id} - {self.condition})"


# ---------------------------
# 팀 사용자 연결 (TeamUser)
# ---------------------------
class TeamUser(models.Model):
    team_user_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    team = models.ForeignKey(Team, on_delete=models.CASCADE)

    ROLE_CHOICES = [
        ('admin', 'Admin'),
        ('sub_admin', 'Sub Admin'),
        ('user', 'User'),
    ]
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)

    def __str__(self):
        return f"{self.user.user_id} in {self.team.team_name} ({self.role})"


# ---------------------------
# 팀 디바이스 연결 (TeamDevice)
# ---------------------------
class TeamDevice(models.Model):
    team_device_id = models.AutoField(primary_key=True)  # Key
    team = models.ForeignKey(Team, on_delete=models.CASCADE)  # Key2 (FK)
    device = models.ForeignKey(Device, on_delete=models.CASCADE)  # Key3 (FK)

    def __str__(self):
        return f"{self.team.team_name} ↔ {self.device.device_id}"
