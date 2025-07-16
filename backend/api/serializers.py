# api/serializers.py

from django.contrib.auth.models import User
from rest_framework import serializers
from .models import MoodLog, Diary, Photo

class UserRegisterSerializer(serializers.ModelSerializer):
    """
    用於註冊的序列化器：
    - username: 必填
    - email: 選填
    - password: 必填
    - password2: 必填，用來確認兩次密碼一致
    """
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    password2 = serializers.CharField(write_only=True, required=True, label="Confirm Password", style={'input_type': 'password'})

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'password2']
        extra_kwargs = {
            'email': {'required': False, 'allow_blank': True},
        }

    def validate(self, attrs):
        """
        驗證 password 與 password2 是否一致。
        """
        pw = attrs.get('password')
        pw2 = attrs.get('password2')
        if pw != pw2:
            raise serializers.ValidationError({"password": "密碼欄位不一致。"})
        return attrs

    def create(self, validated_data):
        """
        移除 password2，使用 create_user 來建立使用者，
        讓 Django 自動做 password hash。
        """
        validated_data.pop('password2')
        password = validated_data.pop('password')
        user = User.objects.create_user(password=password, **validated_data)
        return user

class MoodLogSerializer(serializers.ModelSerializer):
    """
    用於對 MoodLog 模型做序列化：
    - id: 自動產生
    - user: 只讀，不讓客戶端指定
    - date: 只讀（自動填入）
    - score, note: 由客戶端輸入
    """
    class Meta:
        model = MoodLog
        fields = ['id', 'user', 'date', 'score', 'note']
        read_only_fields = ['id', 'date', 'user']

class DiarySerializer(serializers.ModelSerializer):
    class Meta:
        model = Diary
        fields = ['id', 'content', 'created_at']
        read_only_fields = ['created_at']
        
class PhotoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Photo
        fields = ['id', 'image', 'uploaded_at', 'album']
        read_only_fields = ['id', 'uploaded_at']
