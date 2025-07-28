from django.contrib.auth.models import User
from rest_framework import serializers
from .models import MoodLog, Diary, Photo, Album, Achievement

# ✅ 使用者註冊序列化器
class UserRegisterSerializer(serializers.ModelSerializer):
    """
    使用者註冊序列化器：
    - 欄位: username, email, password, password2
    - 功能: 檢查密碼一致性、使用者唯一性，建立帳號
    """
    password = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'}
    )
    password2 = serializers.CharField(
        write_only=True,
        required=True,
        label="確認密碼",
        style={'input_type': 'password'}
    )

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'password2']
        extra_kwargs = {
            'email': {'required': False, 'allow_blank': True},
        }

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "兩次密碼不一致。"})
        return attrs

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("使用者名稱已存在，請換一個。")
        return value

    def validate_email(self, value):
        if value and User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Email 已被註冊。")
        return value

    def create(self, validated_data):
        validated_data.pop('password2')
        password = validated_data.pop('password')
        user = User.objects.create_user(password=password, **validated_data)
        return user

# ✅ 情緒紀錄序列化器
class MoodLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = MoodLog
        fields = ['id', 'user', 'name', 'gender', 'birth']
        read_only_fields = ['user']

# ✅ 日記序列化器
class DiarySerializer(serializers.ModelSerializer):
    class Meta:
        model = Diary
        fields = ['id', 'user', 'created_at', 'emotion', 'content']
        read_only_fields = ['id', 'user', 'created_at']

# ✅ 照片序列化器
class PhotoSerializer(serializers.ModelSerializer):
    owner = serializers.ReadOnlyField(source='owner.username')
    emotion = serializers.ChoiceField(choices=Photo.EMOTION_CHOICES)
    image = serializers.ImageField()
    uploaded_at = serializers.DateTimeField(read_only=True)
    album = serializers.PrimaryKeyRelatedField(
        queryset=Album.objects.all(),
        allow_null=True,
        required=False
    )

    class Meta:
        model = Photo
        fields = ['id', 'owner', 'emotion', 'image', 'uploaded_at', 'album']

# ✅ 成就序列化器
class UserAchievementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Achievement
        fields = ['id', 'achTitle', 'achContent', 'exp', 'is_daily']
        read_only_fields = ['id', 'achTitle', 'achContent']
