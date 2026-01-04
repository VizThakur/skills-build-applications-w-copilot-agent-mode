from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from djongo import models

class Team(models.Model):
    name = models.CharField(max_length=100, unique=True)
    class Meta:
        app_label = 'octofit_tracker'

class Activity(models.Model):
    user = models.CharField(max_length=100)
    activity_type = models.CharField(max_length=100)
    duration = models.IntegerField()
    class Meta:
        app_label = 'octofit_tracker'

class Leaderboard(models.Model):
    user = models.CharField(max_length=100)
    score = models.IntegerField()
    class Meta:
        app_label = 'octofit_tracker'

class Workout(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField()
    class Meta:
        app_label = 'octofit_tracker'

class Command(BaseCommand):
    help = 'Populate the octofit_db database with test data'

    def handle(self, *args, **kwargs):
        User = get_user_model()
        # Clear data
        User.objects.all().delete()
        Team.objects.all().delete()
        Activity.objects.all().delete()
        Leaderboard.objects.all().delete()
        Workout.objects.all().delete()

        # Teams
        marvel = Team.objects.create(name='Marvel')
        dc = Team.objects.create(name='DC')

        # Users
        ironman = User.objects.create_user(username='ironman', email='ironman@marvel.com', password='password')
        batman = User.objects.create_user(username='batman', email='batman@dc.com', password='password')
        superman = User.objects.create_user(username='superman', email='superman@dc.com', password='password')
        captain = User.objects.create_user(username='captain', email='captain@marvel.com', password='password')

        # Activities
        Activity.objects.create(user='ironman', activity_type='run', duration=30)
        Activity.objects.create(user='batman', activity_type='cycle', duration=45)
        Activity.objects.create(user='superman', activity_type='swim', duration=60)
        Activity.objects.create(user='captain', activity_type='run', duration=25)

        # Leaderboard
        Leaderboard.objects.create(user='ironman', score=100)
        Leaderboard.objects.create(user='batman', score=90)
        Leaderboard.objects.create(user='superman', score=110)
        Leaderboard.objects.create(user='captain', score=95)

        # Workouts
        Workout.objects.create(name='Morning Cardio', description='30 min run + 15 min cycle')
        Workout.objects.create(name='Strength', description='Pushups, Pullups, Squats')

        self.stdout.write(self.style.SUCCESS('octofit_db database populated with test data'))
