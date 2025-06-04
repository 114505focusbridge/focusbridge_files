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
        ordering = ['-date']  # 預設依日期倒序排列

    def __str__(self):
        return f"{self.user.username} - {self.date} - {self.score}"
