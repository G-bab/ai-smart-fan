from rest_framework import serializers
from .models import User, Device, SensorData, FilterStatus

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = '__all__'

class DeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = '__all__'

class SensorDataSerializer(serializers.ModelSerializer):
    class Meta:
        model = SensorData
        fields = '__all__'

class FilterStatusSerializer(serializers.ModelSerializer):
    class Meta:
        model = FilterStatus
        fields = '__all__'
