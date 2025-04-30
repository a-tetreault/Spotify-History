library(DBI)
library(RPostgreSQL)
library(tidyverse)


conn <- dbConnect(RPostgreSQL::PostgreSQL(),dbname = 'Spotify', 
                 host = 'localhost',
                 port = 5432,
                 user = 'tetreault',
                 password = 'Maya24-Nova42')

# Load list of queries
queries <- list(
    query0  =   '-- 1. Count plays per artist per year
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
                	count(*) desc;',
    query1  =   '-- 2. Count plays per episode per year
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
            	    count(*) desc;',
    query2  =   '-- 3. Sum time played per artist per year
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
                	sum(time_played) desc;',
    query3  =   '-- 4. Most listened to artist all time by time played
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
                	tot_time_played desc;',
    query4  =   '-- 5. Most played song (all time) -- by count or time?',
    query5  =   '-- 6. Most played album (all time) (by count)
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
                	albums.plays desc;',
    query6  =   '-- 7. Most played podcast (all time) (by time_played)
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
                	sum(time_played) desc;',
    query7  =   '-- 8. Most listened to artist per year by time played 
                select 
                	extract(year from timestamp) 		as year,
                	round(sum(time_played)::numeric, 2) as total_time_played,
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
                	sum(time_played) desc;',
    query8  =   '-- 9. Most played song (by year) -- by count or time?',
    query9  =   '-- 10. Most played album (by year) (by count)
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
                	count(*) desc;',
    query10 =   '-- 11. Most listened to podcast per year
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
                	sum(time_played) desc;',
    query11 =   '-- 12. Most skipped artist
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
                	count(*) desc;',
    query12 =   '-- 13. Most skipped track
                select
                    track_name,
                    artist_name,
                    count(*) as skips
                from
                    streaming_history
                where
                    skipped is true and
                    artist_name is not null
                group by
                    track_name,
                    artist_name
                order by
                    count(*) desc;',
    query13 =   '-- 14. Time of day habits
                select
                	extract(hour from timestamp) as hour,
                	sum(time_played) as tot_time_played
                from
                	streaming_history
                group by
                	extract(hour from timestamp)
                order by
                	hour;'
)

# Load results into list
results <- lapply(queries, function(query) {
    dbGetQuery(conn, query)
})
# 1. Play count per artist per year
artist_plays_byyr <- tibble(results[[0]])

# 2. Play count per podcast per year
podcast_plays_byyr <- tibble(results[[1]])

# 3. Sum time played per artist per year
artist_time_byyr <- tibble(results[[2]])

# 4. Most played artist (all time) -- BY count or time?
mp_artist_at <- tibble(results[[3]])

# 5. Most played song (all time) -- by count or time?
mp_track_at <- tibble(results[[4]])

# 6. Most played album (all time) (by count)
mp_album_at <- tibble(results[[5]])

# 7. Most played podcast (all time) (by time_played)
mp_pod_at <- most_played_pod <- tibble(results[[6]])

# 8. Most played artist (by year) -- by count or time?
mp_artist_byyr <- tibble(results[[7]])

# 9. Most played song (by year) -- by count or time?
mp_track_byyr <- tibble(results[[8]])

# 10. Most played album (by year) (by count)
mp_album_byyr <- tibble(results[[9]])

# 11. Most played podcast (by year) (by time_played)
mp_pod_byyr <- tibble(results[[10]])

# 12. Most skipped artist
most_skipped_artist <- tibble(results[[11]])

# 13. Most skipped track
most_skipped_track <- tibble(results[[12]])

# 14. Time of day habits
time_of_day <- tibble(results[[13]])
time_of_day1 <- time_of_day %>% 
    mutate(tot_time_played = tot_time_played / 60)
tod_plot <- ggplot(time_of_day1, mapping = aes(hour, tot_time_played)) +
    geom_col() 
    
tod_plot
