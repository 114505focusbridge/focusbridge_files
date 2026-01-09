# backend/api/utils/achievement.py
"""
成就工具集（手動領取情緒餘額版）

重點：
- update_achievement_progress()：只更新/建立使用者的成就進度，不做發點數。
- is_claimable_by_id() / get_status_by_id()：判斷是否可領、今日是否已領、里程碑是否已領過。
- claim_achievement()：執行「入帳情緒餘額」並寫入 ExpLog（每日/里程碑用不同 reason 格式）。

注意：真正的列表/領取 API 已在 views.py 完成，
這裡提供同樣的邏輯工具，未來 views 可以直接改為呼叫這裡的函式，避免重複程式。
"""

from __future__ import annotations
from datetime import timedelta, time as dtime
from typing import Dict, Tuple

from django.utils import timezone

from api.models import (
    Achievement,
    UserAchievementProgress,
    ExpLog,
    Diary,
    Todo,
    Photo,
)

# ---------------- 基本日期/統計工具 ----------------

def _today():
    return timezone.localdate()

def _has_diary_on(user, day):
    return Diary.objects.filter(user=user, date=day).exists()

def _streak_until_today(user) -> int:
    """以今天為終點，連續寫日記的天數（含今天）。"""
    day = _today()
    streak = 0
    while _has_diary_on(user, day):
        streak += 1
        day -= timedelta(days=1)
    return streak

def _diary_count(user) -> int:
    return Diary.objects.filter(user=user).count()

def _photo_count(user) -> int:
    return Photo.objects.filter(owner=user).count()

def _todos_done_today(user) -> int:
    return Todo.objects.filter(user=user, date=_today(), is_done=True).count()

def _early_bird_count(user) -> int:
    # 09:00 前寫日記的次數
    return Diary.objects.filter(user=user, created_at__time__lt=dtime(9, 0)).count()

def _night_owl_count(user) -> int:
    # 22:00 後寫日記的次數
    return Diary.objects.filter(user=user, created_at__time__gte=dtime(22, 0)).count()

# ---------------- 錢包：查餘額 / 入帳 ----------------

def current_balance(user) -> int:
    """
    讀取目前情緒餘額。
    優先使用 ExpLog.current_total；若缺少，改用加總。
    """
    last = ExpLog.objects.filter(user=user).order_by('-get_exp_time', '-id').first()
    if last and last.current_total is not None:
        return int(last.current_total)
    return int(sum(ExpLog.objects.filter(user=user).values_list('get_exp', flat=True)) or 0)

def emit_wallet(user, amount: int, reason: str) -> int:
    """
    將 amount（可正可負）寫入錢包流水，並回傳最新餘額。
    reason 範例：
      - 里程碑入帳： "ach:first_diary"
      - 每日入帳：   "daily:daily_diary:2025-08-15"
      - 兌換扣款：   "redeem:item_001 x2"
    """
    amount = int(amount)
    new_total = current_balance(user) + amount
    ExpLog.objects.create(
        user=user,
        get_exp_time=timezone.now(),
        get_exp=amount,
        reason=reason,
        current_total=new_total,
        special_date=None,
    )
    return new_total

# ---------------- 已領取判斷 ----------------

def _claimed_milestone(user, ach_id: str) -> bool:
    return ExpLog.objects.filter(user=user, reason=f'ach:{ach_id}').exists()

def _claimed_daily_today(user, ach_id: str) -> bool:
    return ExpLog.objects.filter(
        user=user,
        reason=f'daily:{ach_id}:{_today().isoformat()}'
    ).exists()

# ---------------- 可領條件判斷 ----------------

def is_claimable(user, ach: Achievement) -> bool:
    """
    達成條件且尚未領取 → True。
    每日成就：看今天是否已領。
    里程碑：看是否曾領過。
    """
    aid = ach.id

    # 已領檢查
    if ach.is_daily:
        if _claimed_daily_today(user, aid):
            return False
    else:
        if _claimed_milestone(user, aid):
            return False

    # 條件判斷（依我們既定的 MVP 成就集合）
    if aid == 'first_diary':
        return _diary_count(user) >= 1
    if aid == 'third_diary':
        return _diary_count(user) >= 3
    if aid == 'photo_first':
        return _photo_count(user) >= 1
    if aid == 'todo_first_done':
        return Todo.objects.filter(user=user, is_done=True).exists()
    if aid == 'streak_7':
        return _streak_until_today(user) >= 7
    if aid == 'early_bird_3':
        return _early_bird_count(user) >= 3
    if aid == 'night_owl_3':
        return _night_owl_count(user) >= 3
    if aid == 'daily_diary':
        return _has_diary_on(user, _today())
    if aid == 'daily_todo3':
        return _todos_done_today(user) >= 3

    # 未定義的成就先返回不可領
    return False

def is_claimable_by_id(user, ach_id: str) -> bool:
    ach = Achievement.objects.filter(pk=ach_id).first()
    return is_claimable(user, ach) if ach else False

def get_status(user, ach: Achievement) -> Dict:
    """
    回傳前端顯示狀態：
      - claimable：是否可領
      - claimed_today：每日成就今天是否已領
      - unlocked：里程碑是否已領過
    """
    claimable = is_claimable(user, ach)
    if ach.is_daily:
        return {
            "claimable": claimable,
            "claimed_today": _claimed_daily_today(user, ach.id),
            "unlocked": False,
        }
    else:
        return {
            "claimable": claimable,
            "claimed_today": False,
            "unlocked": _claimed_milestone(user, ach.id),
        }

def get_status_by_id(user, ach_id: str) -> Dict:
    ach = Achievement.objects.filter(pk=ach_id).first()
    if not ach:
        return {"claimable": False, "claimed_today": False, "unlocked": False}
    return get_status(user, ach)

# ---------------- 「手動領取」主流程 ----------------

def claim_achievement(user, ach_id: str) -> Tuple[bool, Dict]:
    """
    嘗試領取成就。
    成功：回傳 (True, {id, amount, balance, status: {...}})
    失敗：回傳 (False, {detail: <原因>})
    """
    ach = Achievement.objects.filter(pk=ach_id).first()
    if not ach:
        return False, {"detail": "成就不存在"}

    # 已領檢查
    if ach.is_daily and _claimed_daily_today(user, ach_id):
        return False, {"detail": "今天已領取"}
    if not ach.is_daily and _claimed_milestone(user, ach_id):
        return False, {"detail": "已領取過"}

    # 達成條件？
    if not is_claimable(user, ach):
        return False, {"detail": "尚未達成領取條件"}

    amount = int(ach.exp or 0)
    if amount <= 0:
        return False, {"detail": "此成就未設定可發放點數"}

    reason = f"daily:{ach_id}:{_today().isoformat()}" if ach.is_daily else f"ach:{ach_id}"
    balance = emit_wallet(user, amount, reason)

    # 里程碑：同步標記已解鎖（非必要，但讓 progress 表有感）
    if not ach.is_daily:
        uap, _ = UserAchievementProgress.objects.get_or_create(
            user=user, achievement=ach, defaults={"progress": 0.0, "unlocked": False}
        )
        if not uap.unlocked:
            uap.unlocked = True
        # 若要以 progress 表示完成門檻，這裡先簡單設為 1
        if (uap.progress or 0) < 1:
            uap.progress = 1
        uap.save()

    status = get_status(user, ach)
    status.update({"claimable": False})  # 領完後就不可領
    return True, {
        "id": ach_id,
        "amount": amount,
        "balance": balance,
        "status": status,
    }

# ---------------- 進度更新（只記錄，不入帳） ----------------

def update_achievement_progress(user, achievement_id: str, increment: float = 1.0) -> UserAchievementProgress:
    """
    僅更新/建立成就進度，不做入帳：
    - 用於你在各事件（如新增日記/完成待辦/上傳照片）想記錄「累積次數」時。
    - 真正的情緒餘額發放請透過 claim_achievement() 進行。
    """
    progress, _ = UserAchievementProgress.objects.get_or_create(
        user=user,
        achievement_id=achievement_id,
        defaults={'progress': 0.0, 'unlocked': False},
    )
    try:
        progress.progress = (progress.progress or 0.0) + float(increment)
    except Exception:
        # increment 不是數字就忽略
        pass
    progress.save()
    return progress
