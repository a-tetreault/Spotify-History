-- Update time_played to seconds from milliseconds
update streaming_history sh 
set time_played = time_played / 1000
where time_played > 0;


/*
1. Count plays per artist per year
2. Count plays per episode per year
3. Sum time played per artist per year
4. Most played artist (all time) -- BY count or time?
5. Most played song (all time) -- by count or time?
6. Most played album (all time) (by count)
7. Most played podcast (all time) (by time_played)
8. Most played artist (by year) -- by count or time?
9. Most played song (by year) -- by count or time?
10. Most played album (by year) (by count)
11. Most played podcast (by year) (by time_played)
12. Most skipped artist
13. Time of day habits -- by hour or noun quarters? or both?
*/

-- 1. Count plays per artist per year
select
	artist_name,
	count(*) as plays,
	extract(year from timestamp) as year
from
	streaming_history
where
	time_played > 120 and 
	artist_name is not null
group by
	extract(year from timestamp),
	artist_name
order by
	extract(year from timestamp) desc,
	count(*) desc;

-- 2. Count plays per episode per year
select
	episode_show_name,
	count(*) as plays,
	extract(year from timestamp) as year
from
	streaming_history
where
	time_played > 120 and
	episode_show_name is not null
group by
	extract(year from timestamp),
	episode_show_name
order by
	extract(year from timestamp) desc,
	count(*) desc;

-- 3. Sum time played per artist per year
select
	artist_name,
	sum(time_played) as tot_time_played,
	extract(year from timestamp) as year
from
	streaming_history
where
	artist_name is not null and
	time_played > 120
group by
	extract(year from timestamp),
	artist_name
order by
	extract(year from timestamp) desc,
	sum(time_played) desc;

-- 4. Most listened to artist all time by time played
select
	plays,
	tot_time_played,
	artist_name
from 
	(select
		count(*) as plays,
		sum(time_played) as tot_time_played,
		artist_name
	from
		streaming_history
	where
		time_played > 120 and
		artist_name is not null
	group by
		artist_name)
order by
	plays desc,
	tot_time_played desc;


-- 5. Most played song (all time) -- by count or time?
-- count
select
	artist_name,
	(case when track_name like 'Intro' then album_name || '-' || track_name
		else track_name end) as track_name,
	count(*) as plays
from
	streaming_history sh 
where
	track_name is not null and
	skipped is false
group by
	track_name,
	album_name,
	artist_name
order by
	count(*) desc;

-- time played
select
	artist_name,
	(case when track_name like 'Intro' then album_name || '-' || track_name
		else track_name end) as track_name,
	sum(time_played) as time_played
from
	streaming_history sh
where
	track_name is not null and
	skipped is false
group by
	track_name,
	album_name,
	artist_name
order by
	sum(time_played) desc;

-- 6. Most played album (all time) (by count)
select
	sh.artist_name,
	albums.album_name,
	albums.plays
from
	(select
		album_name,
		count(*) as plays
	from 
		streaming_history
	where
		time_played > 120 and
		artist_name is not null
	group by
		album_name) as albums
left join streaming_history sh 
	on sh.album_name = albums.album_name
group by
	albums.album_name,
	sh.artist_name,
	albums.plays
order by 
	albums.plays desc;

-- 7. Most played podcast (all time) (by time_played)
select
	episode_show_name,
	sum(time_played) as tot_time_played
from
	streaming_history
where 
	episode_show_name is not null and
	time_played > 120
group by
	episode_show_name
order by
	sum(time_played) desc;

-- Determine average time 
-- 8. Most listened to artist per year by time played
select 
	extract(year from timestamp) as year,
	sum(time_played) as tot_time_played,
	artist_name
from
	streaming_history sh
where
	time_played > 120 and
	artist_name is not null
group by
	extract(year from timestamp),
	artist_name
order by
	extract(year from timestamp) desc,
	sum(time_played) desc;

-- 9. Most played song (by year) -- by count or time?
-- count
select
	extract(year from timestamp) as year,
	count(*) as plays,
	(case when track_name like 'Intro' then album_name || '-' || track_name
		else track_name end) as track_name,
	artist_name
from
	streaming_history
where
	artist_name is not null and
	(skipped is false or time_played > 120)
group by
	extract(year from timestamp),
	track_name,
	artist_name,
	album_name
order by
	extract(year from timestamp) desc,
	count(*) desc;

-- time_played
select
	extract(year from timestamp) as year,
	sum(time_played) as tot_time_played,
	(case when track_name like 'Intro' then album_name || '-' || track_name
		else track_name end) as track_name,
	artist_name
from
	streaming_history
where
	artist_name is not null and
	(skipped is false or time_played > 120)
group by
	extract(year from timestamp),
	track_name,
	artist_name,
	album_name
order by
	extract(year from timestamp) desc,
	sum(time_played) desc;

-- 10. Most played album (by year) (by count)
select
	extract(year from timestamp) as year,
	count(*) as plays,
	album_name,
	artist_name
from
	streaming_history
where
	album_name is not null and
	(skipped is false or time_played > 60)
group by
	extract(year from timestamp),
	album_name,
	artist_name
order by
	extract(year from timestamp) desc,
	count(*) desc;

-- 11. Most listened to podcast per year
select
	extract(year from sh.timestamp) as year,
	episode_show_name,
	round(sum(time_played)::numeric, 2) as total_time_played
from 
	streaming_history sh
where
	time_played > 1 and
	episode_show_name is not null
group by
	extract(year from sh.timestamp),
	episode_show_name
order by
	extract(year from sh.timestamp) desc,
	sum(time_played) desc;

-- 12. Most skipped artist
select
	artist_name,
	count(*) as skips
from
	streaming_history
where
	skipped is true and
	artist_name is not null
group by
	artist_name
order by
	count(*) desc;

-- 13. Most skipped track
select
	track_name,
	artist_name,
	count(*) as skips
from
	streaming_history
where
	skipped is true and
	track_name is not null
group by
	track_name,
	artist_name
order by
	count(*) desc;

-- 14. Time of day habits
select
	extract('hour' from timestamp) as hour,
	sum(time_played) as tot_time_played
from
	streaming_history
group by
	extract('hour' from timestamp)
order by
	hour;