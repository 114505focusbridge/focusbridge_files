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
    TodoViewSet,
    AchievementListView,
    AchievementClaimView,
    WalletView,
)

# 創建路由器實例
router = DefaultRouter()

# 註冊 ViewSets
# router 會自動為這些 ViewSets 創建 URL 規則 (list, create, retrieve, update, delete)
router.register(r'moodlogs', MoodLogViewSet, basename='moodlog')
router.register(r'diaries', DiaryViewSet, basename='diary')
router.register(r'photos', PhotoViewSet, basename='photo')
router.register(r'todos', TodoViewSet, basename='todo')

urlpatterns = [
    # 1. 路由器 URL，這裡不再重複加上 'api/' 前綴
    path('', include(router.urls)),

    # 2. 獨立的認證相關 API，也移除 'api/' 前綴
    path('auth/register/', RegisterAPIView.as_view(), name='register'),
    path('auth/login/', obtain_auth_token, name='login'),
    path('auth/logout/', LogoutView.as_view(), name='logout'),

    # 3. 成就與錢包相關 API，也移除 'api/' 前綴
    path('achievements/', AchievementListView.as_view(), name='achievements'),
    path('achievements/claim/', AchievementClaimView.as_view(), name='achievements-claim'),
    path('wallet/', WalletView.as_view(), name='wallet'),
]