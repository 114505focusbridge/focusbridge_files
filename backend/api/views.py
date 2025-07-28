# api/views.py

from django.contrib.auth.models import User
from rest_framework import generics, viewsets, permissions, status, parsers, authentication
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.authtoken.models import Token
from rest_framework.authtoken.views import ObtainAuthToken, APIView
from .models import MoodLog, Diary, Photo, UserAchievementProgress
from .serializers import (
    UserRegisterSerializer,
    MoodLogSerializer,
    DiarySerializer,
    PhotoSerializer,
    UserAchievementSerializer
)
from rest_framework.permissions import IsAuthenticated
from .utils import update_achievement_progress

class RegisterAPIView(generics.CreateAPIView):
    """
    使用者註冊 API：
    - POST /api/auth/register/
    - 欄位: username, email, password, password2
    - 回傳: { username, email, token }
    """
    serializer_class = UserRegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            'username': user.username,
            'email': user.email,
            'token': token.key
        }, status=status.HTTP_201_CREATED)


class LogoutView(generics.GenericAPIView):
    """
    使用者登出 API：
    - POST /api/auth/logout/
    - Authorization: Token <token>
    """
    authentication_classes = [authentication.TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        Token.objects.filter(user=request.user).delete()
        return Response({'detail': '已成功登出。'}, status=status.HTTP_200_OK)


class MoodLogViewSet(viewsets.ModelViewSet):
    queryset = MoodLog.objects.all()
    serializer_class = MoodLogSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class DiaryViewSet(viewsets.ModelViewSet):
    serializer_class = DiarySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Diary.objects.filter(user=self.request.user).order_by('-created_at')

    def perform_create(self, serializer):
            diary = serializer.save(user=self.request.user)
            update_achievement_progress(self.request.user, 'first_diary', increment=1.0)
            update_achievement_progress(self.request.user, 'third_diary', increment=1.0)

class PhotoViewSet(viewsets.ModelViewSet):
    """
    照片 CRUD：
    - GET    /api/photos/       → 列出自己的照片
    - POST   /api/photos/       → 上傳照片
    - GET    /api/photos/{id}/  → 取得單張
    - PUT    /api/photos/{id}/  → 更新
    - DELETE /api/photos/{id}/  → 刪除
    """
    authentication_classes = [authentication.TokenAuthentication]
    permission_classes     = [permissions.IsAuthenticated]
    serializer_class       = PhotoSerializer
    parser_classes         = [parsers.MultiPartParser, parsers.FormParser]

    def get_queryset(self):
        return Photo.objects.filter(owner=self.request.user).order_by('-uploaded_at')

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)
        update_achievement_progress(self.request.user, '2', increment=1.0)

    @action(detail=False, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def upload(self, request):
        """
        可用於額外的 /api/photos/upload/ 上傳
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(owner=request.user)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


# 登入 token 端點
class CustomObtainAuthToken(ObtainAuthToken):
    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        token = Token.objects.get(key=response.data['token'])
        user = token.user
        return Response({'token': token.key, 'username': user.username})

class AchievementListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        progress = UserAchievementProgress.objects.filter(user=user)
        serializer = UserAchievementSerializer(progress, many=True)
        return Response(serializer.data)
    
