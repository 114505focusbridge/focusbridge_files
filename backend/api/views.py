from django.contrib.auth.models import User
from django.db import IntegrityError
from rest_framework import generics, viewsets, permissions, status, parsers, authentication
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.authtoken.models import Token
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.views import APIView
from rest_framework.exceptions import ValidationError

from .models import MoodLog, Diary, Photo, UserAchievementProgress
from .serializers import (
    UserRegisterSerializer,
    MoodLogSerializer,
    DiarySerializer,
    PhotoSerializer,
    UserAchievementSerializer
)
from rest_framework.permissions import IsAuthenticated
from .utils.achievement import update_achievement_progress  # ✅ 正確指定模組
from .utils.emotion_models import analyze_sentiment



# ✅ 使用者註冊
class RegisterAPIView(generics.CreateAPIView):
    """
    使用者註冊 API：
    - POST /api/auth/register/
    """
    serializer_class = UserRegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            user = serializer.save()
            token, _ = Token.objects.get_or_create(user=user)
            return Response({
                'username': user.username,
                'email': user.email,
                'token': token.key
            }, status=status.HTTP_201_CREATED)
        except IntegrityError:
            raise ValidationError({"error": "帳號或 Email 已存在，請更換後再試。"})

# ✅ 登出
class LogoutView(generics.GenericAPIView):
    """
    使用者登出 API：
    - POST /api/auth/logout/
    """
    authentication_classes = [authentication.TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        Token.objects.filter(user=request.user).delete()
        return Response({'detail': '已成功登出。'}, status=status.HTTP_200_OK)

# ✅ 心情紀錄
class MoodLogViewSet(viewsets.ModelViewSet):
    queryset = MoodLog.objects.all()
    serializer_class = MoodLogSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

# ✅ 小記日記
class DiaryViewSet(viewsets.ModelViewSet):
    serializer_class = DiarySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Diary.objects.filter(user=self.request.user).order_by('-created_at')

    def perform_create(self, serializer):
        diary = serializer.save(user=self.request.user)
        update_achievement_progress(self.request.user, 'first_diary', increment=1.0)
        update_achievement_progress(self.request.user, 'third_diary', increment=1.0)

# ✅ 照片
class PhotoViewSet(viewsets.ModelViewSet):
    """
    照片 CRUD + 上傳
    """
    authentication_classes = [authentication.TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = PhotoSerializer
    parser_classes = [parsers.MultiPartParser, parsers.FormParser]

    def get_queryset(self):
        return Photo.objects.filter(owner=self.request.user).order_by('-uploaded_at')

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)
        update_achievement_progress(self.request.user, '2', increment=1.0)

    @action(detail=False, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def upload(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(owner=request.user)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

# ✅ 登入 token 擴充版本
class CustomObtainAuthToken(ObtainAuthToken):
    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        token = Token.objects.get(key=response.data['token'])
        user = token.user
        return Response({'token': token.key, 'username': user.username})

# ✅ 查詢使用者成就進度
class AchievementListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        progress = UserAchievementProgress.objects.filter(user=user)
        serializer = UserAchievementSerializer(progress, many=True)
        return Response(serializer.data)
