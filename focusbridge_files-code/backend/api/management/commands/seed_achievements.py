from django.core.management.base import BaseCommand
from api.models import Achievement

ACHIEVEMENTS = [
    {"id": "first_diary",     "achTitle": "第一篇小記",    "achContent": "寫下第一篇日記",     "exp": 10, "is_daily": False},
    {"id": "third_diary",     "achTitle": "三篇達成",      "achContent": "累積三篇日記",       "exp": 20, "is_daily": False},
    {"id": "photo_first",     "achTitle": "第一張照片",    "achContent": "上傳第一張照片",     "exp": 5,  "is_daily": False},
    {"id": "todo_first_done", "achTitle": "完成第一件事",  "achContent": "完成你的第一個待辦", "exp": 5,  "is_daily": False},
    {"id": "streak_7",        "achTitle": "連續七天",      "achContent": "連續 7 天寫日記",    "exp": 30, "is_daily": False},
    {"id": "early_bird_3",    "achTitle": "早鳥 x3",       "achContent": "三次 09:00 前寫日記","exp": 10, "is_daily": False},
    {"id": "night_owl_3",     "achTitle": "夜貓 x3",       "achContent": "三次 22:00 後寫日記","exp": 10, "is_daily": False},
    {"id": "daily_diary",     "achTitle": "每日小記",      "achContent": "今天寫日記",         "exp": 3,  "is_daily": True},
    {"id": "daily_todo3",     "achTitle": "每日三件事",    "achContent": "今天完成 3 件待辦",  "exp": 5,  "is_daily": True},
]

class Command(BaseCommand):
    help = "Seed default achievements for FocusBridge"

    def handle(self, *args, **options):
        created_cnt, updated_cnt = 0, 0
        for a in ACHIEVEMENTS:
            obj, created = Achievement.objects.update_or_create(
                id=a["id"],
                defaults={
                    "achTitle": a["achTitle"],
                    "achContent": a["achContent"],
                    "exp": a["exp"],
                    "is_daily": a["is_daily"],
                },
            )
            created_cnt += 1 if created else 0
            updated_cnt += 0 if created else 1
        self.stdout.write(self.style.SUCCESS(
            f"Seeded achievements. created={created_cnt}, updated={updated_cnt}"
        ))
