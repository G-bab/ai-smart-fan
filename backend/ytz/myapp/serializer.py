from rest_framework import serializers
from .models import Team, User, Device, TeamUser, TeamDevice, SensorData, FilterStatus


class TeamSerializer(serializers.ModelSerializer):
    class Meta:
        model = Team
        fields = '__all__'


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = '__all__'


class DeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = '__all__'


class TeamUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = TeamUser
        fields = '__all__'


class TeamDeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = TeamDevice
        fields = '__all__'


class SensorDataSerializer(serializers.ModelSerializer):
    class Meta:
        model = SensorData
        fields = '__all__'


class FilterStatusSerializer(serializers.ModelSerializer):
    class Meta:
        model = FilterStatus
        fields = '__all__'