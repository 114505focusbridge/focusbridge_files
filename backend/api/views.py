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
from .utils.achievement import update_achievement_progress
from .utils.emotion_models import analyze_sentiment


# ✅ 使用者註冊
class RegisterAPIView(generics.CreateAPIView):
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


# ✅ 小記日記（含 AI 分析回傳）
class DiaryViewSet(viewsets.ModelViewSet):
    serializer_class = DiarySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Diary.objects.filter(user=self.request.user).order_by('-created_at')

    def create(self, request, *args, **kwargs):
        user = request.user
        content = request.data.get("content", "")
        emotion = request.data.get("emotion", "")

        if not content:
            return Response({"error": "日記內容不得為空"}, status=status.HTTP_400_BAD_REQUEST)

        label, ai_message, keywords, topics = analyze_sentiment(content)

        diary = Diary.objects.create(
            user=user,
            content=content,
            emotion=emotion,
            label=label,
            ai_message=ai_message
        )

        # 更新成就進度
        update_achievement_progress(user, 'first_diary', increment=1.0)
        update_achievement_progress(user, 'third_diary', increment=1.0)

        return Response({
            "id": diary.id,
            "label": label,
            "ai_message": ai_message
        }, status=status.HTTP_201_CREATED)


# ✅ 照片 CRUD + 上傳
class PhotoViewSet(viewsets.ModelViewSet):
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


# ✅ 登入擴充
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
