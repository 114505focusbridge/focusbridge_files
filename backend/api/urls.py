# backend/api/urls.py

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework.authtoken.views import obtain_auth_token
from .views import RegisterAPIView, LogoutView, MoodLogViewSet, DiaryViewSet, PhotoViewSet

# 建立 DRF 的 DefaultRouter，並註冊 MoodLogViewSet
router = DefaultRouter()
router.register(r'moodlogs', MoodLogViewSet, basename='moodlog')
router.register(r'diaries',DiaryViewSet,basename='diary')
router.register(r'photos',PhotoViewSet,basename='photo')


urlpatterns = [
    # 1. 使用者註冊：POST /api/auth/register/
    path('auth/register/', RegisterAPIView.as_view(), name='register'),

    # 2. 使用者登入（取得 Token）：POST /api/auth/login/
    path('auth/login/', obtain_auth_token, name='login'),

    # 3. 使用者登出（刪除 Token）：POST /api/auth/logout/
    path('auth/logout/', LogoutView.as_view(), name='logout'),

    # 4. MoodLogViewSet 相關的所有操作，對應 /api/moodlogs/ 與 /api/moodlogs/{pk}/
    path('', include(router.urls)),
]
