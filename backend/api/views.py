from django.contrib.auth.models import User
from django.db import IntegrityError
from django.db.models import F
from django.utils import timezone
from datetime import datetime

from rest_framework import (
    generics, viewsets, permissions, status, parsers, authentication
)
from rest_framework import serializers as drf_serializers
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.authtoken.models import Token
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.views import APIView
from rest_framework.exceptions import ValidationError

from .models import MoodLog, Diary, Photo, UserAchievementProgress, Todo
from .serializers import (
    UserRegisterSerializer,
    MoodLogSerializer,
    DiarySerializer,
    PhotoSerializer,
    UserAchievementSerializer,  # 針對 Achievement 本體
    TodoSerializer,
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

# ✅ 心情紀錄（僅限自己的資料）
class MoodLogViewSet(viewsets.ModelViewSet):
    serializer_class = MoodLogSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return MoodLog.objects.filter(user=self.request.user).order_by('id')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

# ✅ 小記日記（含 AI 分析功能）
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

        # 🧠 使用模型分析情緒
        label, ai_message, keywords, topics = analyze_sentiment(content)

        # ✅ 建立日記，儲存分析結果
        diary = Diary.objects.create(
            user=user,
            content=content,
            emotion=emotion,
            sentiment=label,
            ai_message=ai_message,
            keywords=", ".join(keywords),
            topics=", ".join(topics)
        )

        # 🎯 更新成就進度（示例 id，依你的規則）
        update_achievement_progress(user, 'first_diary', increment=1.0)
        update_achievement_progress(user, 'third_diary', increment=1.0)

        return Response({
            "success": True,
            "id": diary.id,
            "label": label,
            "ai_message": ai_message,
            "keywords": keywords,
            "topics": topics
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

# ✅ 登入擴充（可選：回傳 username）
class CustomObtainAuthToken(ObtainAuthToken):
    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        token = Token.objects.get(key=response.data['token'])
        user = token.user
        return Response({'token': token.key, 'username': user.username})

# ✅ 成就進度查詢（修正：對 UserAchievementProgress 序列化）
class AchievementListView(APIView):
    permission_classes = [IsAuthenticated]

    class UserAchievementProgressSerializer(drf_serializers.ModelSerializer):
        # 攤平回傳 Achievement 的主要欄位
        id = drf_serializers.ReadOnlyField(source='achievement.id')
        achTitle = drf_serializers.ReadOnlyField(source='achievement.achTitle')
        achContent = drf_serializers.ReadOnlyField(source='achievement.achContent')
        exp = drf_serializers.ReadOnlyField(source='achievement.exp')
        is_daily = drf_serializers.ReadOnlyField(source='achievement.is_daily')

        class Meta:
            model = UserAchievementProgress
            fields = ['id', 'achTitle', 'achContent', 'exp', 'is_daily', 'progress', 'unlocked']

    def get(self, request):
        user = request.user
        progress_qs = UserAchievementProgress.objects.filter(user=user)
        serializer = self.UserAchievementProgressSerializer(progress_qs, many=True)
        return Response(serializer.data)

# ✅ 今日備忘錄 / To-Do
class TodoViewSet(viewsets.ModelViewSet):
    """
    /api/todos/
      - GET    /api/todos/?date=YYYY-MM-DD   只看當天（未帶 date 則回傳自己的全部）
      - POST   /api/todos/                   {title, date?, time?}
      - PATCH  /api/todos/{id}/              {is_done: true/false}
      - DELETE /api/todos/{id}/
    """
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = TodoSerializer

    def get_queryset(self):
        qs = Todo.objects.filter(user=self.request.user)

        # ?date=YYYY-MM-DD
        date_str = self.request.query_params.get('date')
        if date_str:
            try:
                day = datetime.fromisoformat(date_str).date()
            except ValueError:
                raise ValidationError({"date": "日期格式錯誤，需 YYYY-MM-DD"})
            qs = qs.filter(date=day)

        # 未完成在前 -> 時間（NULL 放最後）-> 建立時間
        return qs.order_by('is_done', F('time').asc(nulls_last=True), 'created_at')

    def perform_create(self, serializer):
        # user 從後端帶入；date 若未傳，TodoSerializer 會預設為今天
        serializer.save(user=self.request.user)
