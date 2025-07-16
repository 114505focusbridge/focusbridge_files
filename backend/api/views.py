# api/views.py

from rest_framework import generics, viewsets, permissions, status, authentication
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from .models import MoodLog, Diary, Photo
from .serializers import UserRegisterSerializer, MoodLogSerializer, DiarySerializer, PhotoSerializer

class RegisterAPIView(generics.CreateAPIView):
    """
    使用者註冊 API：
    - URL: POST /api/auth/register/
    - 欄位: username, email (可選), password, password2
    - 成功回傳 JSON: { "username": "...", "email": "...", "token": "..." }
    """
    serializer_class = UserRegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        # 用序列化器驗證並建立新使用者
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # 建立或取得該使用者的 Token
        token, created = Token.objects.get_or_create(user=user)

        # 回傳需要的欄位給前端
        return Response({
            "username": user.username,
            "email": user.email,
            "token": token.key
        }, status=status.HTTP_201_CREATED)

class LogoutView(generics.GenericAPIView):
    """
    使用者登出 API：
    - URL: POST /api/auth/logout/
    - 必須帶上 Authorization: Token <token>
    - 伺服器端刪除 token，客戶端再刪除本機存的 token
    """
    authentication_classes = [authentication.TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        try:
            # 刪除該使用者的 token
            token = Token.objects.get(user=request.user)
            token.delete()
        except Token.DoesNotExist:
            pass

        return Response({"detail": "已成功登出。"}, status=status.HTTP_200_OK)

class MoodLogViewSet(viewsets.ModelViewSet):
    """
    心情日誌 CRUD：
    - GET    /api/moodlogs/         → 列出所有日誌（AllowAny 也能讀）
    - POST   /api/moodlogs/         → 建立新的日誌（須登入）
    - GET    /api/moodlogs/{id}/    → 取得單筆日誌（AllowAny 也能讀）
    - PUT    /api/moodlogs/{id}/    → 完整更新某筆日誌（須登入且該 user）
    - PATCH  /api/moodlogs/{id}/    → 部分更新（須登入且該 user）
    - DELETE /api/moodlogs/{id}/    → 刪除（須登入且該 user）
    """
    queryset = MoodLog.objects.all()
    serializer_class = MoodLogSerializer

    def get_permissions(self):
        # 如果是 list 或 retrieve，就任何人都能讀
        if self.action in ['list', 'retrieve']:
            return [permissions.AllowAny()]
        # 否則要登入才能修改、新增、刪除
        return [permissions.IsAuthenticated()]

    def perform_create(self, serializer):
        # 建立時，自動把 user 欄位設成當前登入使用者
        serializer.save(user=self.request.user)

    def get_queryset(self):
        """
        如果想要限制每個使用者只能看到自己的日誌，
        可以這樣改成只返回 request.user 的 queryset：
        
            return MoodLog.objects.filter(user=self.request.user)

        或者保留原本就全部列出（若是管理員要看所有人的日誌）。
        這裡示範只看自己的：
        """
        user = self.request.user
        # 如果尚未登入，AllowAny 一樣能 list 但 queryset 回空
        if not user or not user.is_authenticated:
            return MoodLog.objects.none()
        return MoodLog.objects.filter(user=user)

class DiaryViewSet(viewsets.ModelViewSet):
    queryset = Diary.objects.all()
    serializer_class = DiarySerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class PhotoViewSet(viewsets.ModelViewSet):
    queryset = Photo.objects.all()
    serializer_class = PhotoSerializer
    permission_classes = [permissions.IsAuthenticated]