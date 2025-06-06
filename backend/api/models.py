# api/models.py

from django.db import models
from django.contrib.auth.models import User

class MoodLog(models.Model):
    """
    一個範例模型：使用者每日心情日誌（MoodLog）。
    - user: 關聯到 Django 內建的 User 模型
    - date: 自動填入建立日期
    - score: 情緒分數（1~10）
    - note: 可選的文字描述
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='mood_logs')
    date = models.DateField(auto_now_add=True)
    score = models.PositiveSmallIntegerField(default=5)
    note = models.TextField(blank=True)

    class Meta:
        db_table="moodlog"

# 使用者
class User(models.Model):
    User_Name = models.CharField(max_length=100)
    User_Password = models.CharField(max_length=100)
    Signup_Date = models.DateField()
    Tot_Hours = models.IntegerField()
    Tot_Exp = models.IntegerField()

    def __str__(self):
        return self.User_Name

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

    def __str__(self):
        return self.album_name

class Photo(models.Model):
    image = models.ImageField(upload_to='photos/')

class AlbumPhoto(models.Model):
    album = models.ForeignKey(Album, on_delete=models.CASCADE)
    photo = models.ForeignKey(Photo, on_delete=models.CASCADE)

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

# 情緒紀錄
class MoodEntry(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    date = models.DateField()
    weather_icon = models.CharField(max_length=50)
    color_mix = models.CharField(max_length=50)
    emotion_tag = models.CharField(max_length=50)
    note = models.TextField()

# 日記
class DiaryTitle(models.Model):
    title = models.CharField(max_length=100)

    def __str__(self):
        return self.title

class Diary(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    day = models.DateField()
    diary_title = models.ForeignKey(DiaryTitle, on_delete=models.CASCADE)
    content = models.TextField()

def __str__(self):
    return f"{self.user.username} - {self.date} - {self.score}"
