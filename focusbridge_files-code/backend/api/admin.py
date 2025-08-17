# backend/api/admin.py
from django.contrib import admin
from .models import (
    MoodLog, Achievement, Goal, Album, Photo, WeeklyMission,
    PositiveEmotionLog, SpecialDate, ExpLog, MoodImage, MoodEntry,
    Diary, DiaryTitle, Todo, UserAchievementProgress
)

# 讓 PhotoAdmin 的 autocomplete_fields 能查到 Album
@admin.register(Album)
class AlbumAdmin(admin.ModelAdmin):
    search_fields = ('album_name',)  # ← 關鍵：提供自動完成要用的查詢欄位
    list_display = ('id', 'album_name', 'created_at')
    ordering = ('-created_at',)

@admin.register(Photo)
class PhotoAdmin(admin.ModelAdmin):
    # 你若想要在後台輸入 Photo 時可以用自動完成找 owner/album，就留著這行
    autocomplete_fields = ('owner', 'album')
    list_display = ('id', 'owner', 'emotion', 'album', 'uploaded_at')
    list_filter = ('emotion', 'uploaded_at', 'album')
    search_fields = ('id', 'owner__username')  # 這行不是解錯誤的關鍵，但很實用
    ordering = ('-uploaded_at',)

# 其餘模型照舊
@admin.register(MoodLog)
class MoodLogAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'name', 'gender', 'birth')
    search_fields = ('user__username', 'name')

admin.site.register(Achievement)
admin.site.register(Goal)
admin.site.register(WeeklyMission)
admin.site.register(PositiveEmotionLog)
admin.site.register(SpecialDate)
admin.site.register(ExpLog)
admin.site.register(MoodImage)
admin.site.register(MoodEntry)
admin.site.register(Diary)
admin.site.register(DiaryTitle)
admin.site.register(Todo)
admin.site.register(UserAchievementProgress)
