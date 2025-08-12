from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone

class MoodLog(models.Model):
    GENDER_CHOICES = [
        ('male', '男'),
        ('female', '女'),
        ('none', '不願透露'),
    ]
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='mood_logs')
    name = models.CharField(max_length=20)
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES, default='none')
    birth = models.DateTimeField()

    def __str__(self):
        return f"{self.user.username} 的個人資料"


class Achievement(models.Model):
    id = models.CharField(primary_key=True, max_length=50)
    achTitle = models.CharField(max_length=100)
    achContent = models.TextField()
    exp = models.IntegerField()
    is_daily = models.BooleanField(default=False)

    def __str__(self):
        return self.achTitle


class UserAchievementProgress(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    achievement = models.ForeignKey(Achievement, on_delete=models.CASCADE)
    progress = models.FloatField(default=0.0)
    unlocked = models.BooleanField(default=False)

    class Meta:
        unique_together = ('user', 'achievement')


class Goal(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    ach = models.ForeignKey(Achievement, on_delete=models.CASCADE)
    ach_time = models.DateTimeField()

    def __str__(self):
        return f"{self.user.username} achieved {self.ach} at {self.ach_time}"


class Album(models.Model):
    album_name = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.album_name


class Photo(models.Model):
    EMOTION_CHOICES = [
        ('快樂', '快樂'),
        ('憤怒', '憤怒'),
        ('悲傷', '悲傷'),
        ('恐懼', '恐懼'),
        ('驚訝', '驚訝'),
        ('厭惡', '厭惡'),
    ]

    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='photos')
    emotion = models.CharField(max_length=10, choices=EMOTION_CHOICES, default='快樂')
    image = models.ImageField(upload_to='photos/%Y/%m/%d/')
    uploaded_at = models.DateTimeField(auto_now_add=True)
    album = models.ForeignKey(Album, on_delete=models.SET_NULL, null=True, blank=True, related_name='photos')

    def __str__(self):
        return f"Photo {self.id} ({self.emotion})"


class WeeklyMission(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    mission = models.TextField()
    is_completed = models.BooleanField(default=False)
    complete_time = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        status = 'Done' if self.is_completed else 'Pending'
        return f"{self.user.username}: {self.mission} - {status}"


class PositiveEmotionLog(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    date = models.DateField()
    emotion_type = models.CharField(max_length=100)
    description = models.TextField()
    source_event = models.TextField()

    def __str__(self):
        return f"{self.user.username} - {self.emotion_type} @ {self.date}"


class SpecialDate(models.Model):
    date_name = models.CharField(max_length=100)
    date = models.DateField()

    def __str__(self):
        return self.date_name


class ExpLog(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    get_exp_time = models.DateTimeField()
    get_exp = models.IntegerField()
    reason = models.TextField()
    special_date = models.ForeignKey(SpecialDate, on_delete=models.SET_NULL, null=True)
    current_total = models.IntegerField()

    def __str__(self):
        return f"{self.user.username} +{self.get_exp} @ {self.get_exp_time}"


class MoodImage(models.Model):
    name = models.CharField(max_length=50)
    image = models.ImageField(upload_to='mood_images/')

    def __str__(self):
        return self.name


class MoodEntry(models.Model):
    date = models.DateField()
    weather_icon = models.ForeignKey(MoodImage, on_delete=models.SET_NULL, null=True, blank=True, related_name='diary_entries')
    color_mix = models.ImageField(upload_to='MoodEntry/')
    emotion_tag = models.CharField(max_length=50)
    note = models.TextField()

    def __str__(self):
        return f"{self.date} - {self.emotion_tag}"


class DiaryTitle(models.Model):
    title = models.CharField(max_length=100)

    def __str__(self):
        return self.title


class Diary(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    emotion = models.CharField(max_length=20)
    content = models.TextField()
    sentiment = models.CharField(max_length=20, blank=True)  # AI 分析情緒標籤
    keywords = models.TextField(blank=True)  # 擷取關鍵詞
    topics = models.TextField(blank=True)  # 主題分類
    ai_message = models.TextField(blank=True)  # Gemini 給的回饋語句

    def __str__(self):
        return f"Diary {self.id} by {self.user.username} @ {self.created_at}"

class Todo(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='todos')
    title = models.CharField(max_length=200)
    date = models.DateField(db_index=True)                 # 要顯示哪一天（我們先做「只看今天」）
    time = models.TimeField(null=True, blank=True)         # 可選的時間（右側 10:00/12:00 之類）
    is_done = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['is_done', 'time', 'created_at']       # 未完成在前，再依時間/建立順序

    def __str__(self):
        t = self.time.strftime('%H:%M') if self.time else '--:--'
        return f"{self.user.username} | {self.date} {t} | {self.title}"