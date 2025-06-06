from django.contrib import admin
from .models import User, Achievement, Goal, Album, AlbumPhoto, Photo, WeeklyMission, PositiveEmotionLog, SpecialDate, ExpLog, MoodEntry, Diary, DiaryTitle

admin.site.register(User)
admin.site.register(Achievement)
admin.site.register(Goal)
admin.site.register(Album)
admin.site.register(AlbumPhoto)
admin.site.register(Photo)
admin.site.register(WeeklyMission)
admin.site.register(PositiveEmotionLog)
admin.site.register(SpecialDate)
admin.site.register(ExpLog)
admin.site.register(MoodEntry)
admin.site.register(Diary)
admin.site.register(DiaryTitle)
