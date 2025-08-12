# backend/api/urls.py

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework.authtoken.views import obtain_auth_token

from .views import (
    RegisterAPIView,
    LogoutView,
    MoodLogViewSet,
    DiaryViewSet,
    PhotoViewSet,
    # ⬇️ 新增
    TodoViewSet,
    # ⬇️ 若想用客製化登入，取消註解下一行並在下方路由切換
    # CustomObtainAuthToken,
    # ⬇️ AchievementListView 先不要註冊，等之後修好對應的 Serializer 再放
    # AchievementListView,
)

router = DefaultRouter()
router.register(r'moodlogs', MoodLogViewSet, basename='moodlog')
router.register(r'diaries', DiaryViewSet, basename='diary')
router.register(r'photos', PhotoViewSet, basename='photo')
# ⬇️ 新增 To-Do 路由
router.register(r'todos', TodoViewSet, basename='todo')

urlpatterns = [
    # 1. 使用者註冊
    path('auth/register/', RegisterAPIView.as_view(), name='register'),

    # 2A. 預設登入（回傳 token）
    path('auth/login/', obtain_auth_token, name='login'),

    # 2B.（可選）改用自訂登入（回傳 token + username）
    # path('auth/login/', CustomObtainAuthToken.as_view(), name='login'),

    # 3. 登出
    path('auth/logout/', LogoutView.as_view(), name='logout'),

    # 4. ViewSets
    path('', include(router.urls)),

    # （先別開）成就進度 API：等之後把 Serializer 對 model 對齊再註冊
    # path('achievements/', AchievementListView.as_view(), name='achievements'),
]
