from api.models import Achievement, UserAchievementProgress

def update_achievement_progress(user, achievement_id, increment=1.0):
    try:
        # 嘗試取得對應的成就資料
        achievement = Achievement.objects.get(id=achievement_id)
        progress_obj, created = UserAchievementProgress.objects.get_or_create(
            user=user,
            achievement=achievement,
            defaults={'progress': 0.0, 'unlocked': False}
        )

        # 若尚未解鎖，則增加進度
        if not progress_obj.unlocked:
            progress_obj.progress += increment
            if progress_obj.progress >= 1.0:
                progress_obj.progress = 1.0
                progress_obj.unlocked = True
            progress_obj.save()
    except Achievement.DoesNotExist:
        print(f"⚠️ 無法找到 ID 為 '{achievement_id}' 的成就，請先建立 Achievement。")
        return  # 中止執行，避免 FOREIGN KEY 錯誤

    # 建立或取得該成就的進度紀錄
    progress, created = UserAchievementProgress.objects.get_or_create(
        user=user,
        achievement=achievement,
        defaults={'progress': 0.0, 'unlocked': False}
    )

    # 更新進度
    progress.progress += increment
    if progress.progress >= 1.0:
        progress.unlocked = True
    progress.save()

    print(f"✅ 已更新 {achievement.achTitle} 的進度，目前為 {progress.progress:.2f}，是否解鎖：{progress.unlocked}")

