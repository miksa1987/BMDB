# BMDB

A Postgres database to generate random workouts with varying parameters.

## Getting started

1. Start your database
2. import the SQL dump by running psql your_desired_dbname < bm_2021xxxxx.sql

## Getting workouts

You can get workouts by:
SELECT _ from bm.get_workout(ARRAY['list', 'of', 'equipment'], ARRAY['list', 'of', 'exercise groups'], 'goal', num_of_ex_per_group, higher_reps, 'difficulty')
A little explanation on parameters:
List of equipment can be found by SELECT _ FROM bm.equipment
List of exercise groups can be found by SELECT _ FROM bm.exercisegroups
Goals can be found by SELECT _ FROM bm.sets_and_reps (goal column)
Num_of_ex_per_group is the number of exercises per exercise group.
Higher_reps are you going to hit higher reps? Then set this to TRUE, otherwise FALSE. Best used with 'endurance' goal.
Difficulties can be found by SELECT \* FROM bm.levels. Return exercises up to this difficulty level.

## Contributing

I'll be happy to receive pull requests!
