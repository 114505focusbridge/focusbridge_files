# backend/backend/urls.py
from rest_framework.authtoken.views import obtain_auth_token
from django.contrib import admin
from django.urls import path, include
from django.http import HttpResponse

# 1. 根目錄 (http://127.0.0.1:8000/) 進來時的回應
def root_view(request):
    return HttpResponse(
        "Welcome! Django ",
        content_type="text/plain",
    )

urlpatterns = [
    # 根目錄 (/) 顯示簡易提示文字
    path('', root_view),

    # Django 管理後台介面 (/admin/)
    path('admin/', admin.site.urls),

    # 將所有以 /api/ 開頭的請求轉到 api 應用的路由設定
    path('api/', include('api.urls')),
    # … 其他路由 …
    path('api/auth/token/', obtain_auth_token, name='api-token-auth'),
]
