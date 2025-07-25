# api/views.py

from django.contrib.auth.models import User
from rest_framework import generics, viewsets, permissions, status, parsers, authentication
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.authtoken.models import Token
from rest_framework.authtoken.views import ObtainAuthToken
from .models import MoodLog, Diary, Photo
from .serializers import (
    UserRegisterSerializer,
    MoodLogSerializer,
    DiarySerializer,
    PhotoSerializer
)


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
    serializer_class = MoodLogSerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        user = self.request.user
        if not user or not user.is_authenticated:
            return MoodLog.objects.none()
        return MoodLog.objects.filter(user=user).order_by('-date')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class DiaryViewSet(viewsets.ModelViewSet):
    serializer_class = DiarySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Diary.objects.filter(user=self.request.user).order_by('-created_at')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


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
