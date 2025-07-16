# api/models.py

from django.db import models
from django.contrib.auth.models import User

class MoodLog(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='mood_logs')
    password = models.CharField(max_length=100,)
    date = models.DateField(auto_now_add=True)
    Tot_Hours = models.IntegerField(default=0)
    Tot_Exp = models.IntegerField(default=0)

    class Meta:
        ordering = ['-date']  # 預設依日期倒序排列

    def __str__(self):
        return f"{self.user.username} - {self.date} - {self.score}"
    
# 成就
class Achievement(models.Model):
    ach_title = models.CharField(max_length=100)
    ach_content = models.TextField()
    exp = models.IntegerField()

    def __str__(self):
        return self.ach_title

# 達成成就
class Goal(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    ach = models.ForeignKey(Achievement, on_delete=models.CASCADE)
    ach_time = models.DateTimeField()

# 相簿和照片
class Album(models.Model):
    album_name = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.album_name

class Photo(models.Model):
    image = models.ImageField(upload_to='photos/')
    uploaded_at = models.DateTimeField(auto_now_add=True)
    album = models.ForeignKey(
        Album,
        on_delete=models.SET_NULL,
        null=True,  # 允許照片不屬於任何相簿
        blank=True,
        related_name='photos'
    )

    def __str__(self):
        return f"Photo {self.id}"
    
# 每週任務
class WeeklyMission(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    mission = models.TextField()
    is_completed = models.BooleanField(default=False)
    complete_time = models.DateTimeField(null=True, blank=True)

# 正向情緒標籤
class PositiveEmotionLog(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    date = models.DateField()
    emotion_type = models.CharField(max_length=100)
    description = models.TextField()
    source_event = models.TextField()

# 特別日期
class SpecialDate(models.Model):
    date_name = models.CharField(max_length=100)
    date = models.DateField()

    def __str__(self):
        return self.date_name

# 經驗值
class ExpLog(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    get_exp_time = models.DateTimeField()
    get_exp = models.IntegerField()
    reason = models.TextField()
    special_date = models.ForeignKey(SpecialDate, on_delete=models.SET_NULL, null=True)
    current_total = models.IntegerField()

#情緒圖片
class MoodImage(models.Model):
    name = models.CharField(max_length=50) 
    image = models.ImageField(upload_to='mood_images/')
    
# 情緒紀錄
class MoodEntry(models.Model):
    date = models.DateField()
    weather_icon = models.ForeignKey(
        MoodImage,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='diary_entries')
    color_mix = models.ImageField(upload_to='MoodEntry/')
    emotion_tag = models.CharField(max_length=50)
    note = models.TextField()



# 日記
class DiaryTitle(models.Model):
    title = models.CharField(max_length=100)

    def __str__(self):
        return self.title

class Diary(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    content = models.TextField()

