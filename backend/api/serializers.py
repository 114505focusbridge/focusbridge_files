# api/serializers.py

from django.contrib.auth.models import User
from rest_framework import serializers
from .models import MoodLog, Diary, Photo, Album, Achievement

class UserRegisterSerializer(serializers.ModelSerializer):
    """
    註冊用序列化器：
    - username, email, password, password2
    """
    password = serializers.CharField(
        write_only=True, required=True, style={'input_type': 'password'}
    )
    password2 = serializers.CharField(
        write_only=True, required=True, label="Confirm Password",
        style={'input_type': 'password'}
    )

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'password2']
        extra_kwargs = {'email': {'required': False, 'allow_blank': True}}

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "兩次密碼不一致。"})
        return attrs

    def create(self, validated_data):
        validated_data.pop('password2')
        password = validated_data.pop('password')
        user = User.objects.create_user(password=password, **validated_data)
        return user


class MoodLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = MoodLog
        fields = ['id', 'user', 'name', 'gender', 'birth']
        read_only_fields = ['user']


class DiarySerializer(serializers.ModelSerializer):
    """
    對應 Diary 模型：
    - id, content, created_at (只讀)
    """
    class Meta:
        model = Diary
        fields = ['id', 'user', 'created_at', 'emotion', 'content']
        read_only_fields = ['id', 'user', 'created_at']


class PhotoSerializer(serializers.ModelSerializer):
    """
    照片序列化器：
    - owner (只讀)、emotion、image、uploaded_at (只讀)、album
    """
    owner       = serializers.ReadOnlyField(source='owner.username')
    emotion     = serializers.ChoiceField(choices=Photo.EMOTION_CHOICES)
    image       = serializers.ImageField()
    uploaded_at = serializers.DateTimeField(read_only=True)
    album       = serializers.PrimaryKeyRelatedField(
                      queryset=Album.objects.all(),
                      allow_null=True,
                      required=False
                  )

    class Meta:
        model  = Photo
        fields = ['id', 'owner', 'emotion', 'image', 'uploaded_at', 'album']


# 如果你還有別的 serializers，例如 UserLogin、Achievement 等，
# 請依照上面的格式，確保每個 serializer 的 fields 都與 model 一致。

class UserAchievementSerializer(serializers.ModelSerializer):

    class Meta:
        model = Achievement
        fields = ['id', 'achTitle', 'achContent','exp','is_daily']
        read_only_fields = ['id', 'achTitle','achContent']