from api.models import UserAchievementProgress

def update_achievement_progress(user, achievement_id, increment=1.0):
    progress, created = UserAchievementProgress.objects.get_or_create(
        user=user,
        achievement_id=achievement_id,
        defaults={'progress': 0.0}
    )
    progress.progress += increment
    progress.save()
