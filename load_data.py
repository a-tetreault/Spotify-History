import psycopg
import hidden
import requests
import json


with psycopg.connect("postgres://postgres@localhost:5432/Spotify") as conn:

    with conn.cursor() as cur:

        cur.execute("""
            drop table if exists streaming_history;
            create table if not exists streaming_history(
                timestamp           timestamp,
                time_played         real,
                track_name          text,
                artist_name         text,
                album_name          text,
                track_uri           text,
                episode_name        text,
                episode_show_name   text,
                episode_uri         text,
                reason_start        text,
                reason_end          text,
                shuffle             boolean,
                skipped             boolean,
                offline             boolean,
                offline_timestamp   real,
                file                text
            );
        """)
        while True:
            fname = input("Enter filename: ")
            if fname.lower() == 'exit':
                break
            if not fname:
                print("BONK! not a real file")
                fname = input("Enter filename: ")
            print("Retrieving", fname)
            with open(fname, encoding = "UTF-8") as handle:
                try:
                    json_data = json.load(handle)
                except json.JSONDecodeError as e:
                    print(f"Error decoding JSON: {e}")
                    continue

                if isinstance(json_data, list): # if the json data you pull is a list then try to load it
                    for item in json_data:
                        timestamp = item.get("ts", "N/A")
                        time_played = item.get("ms_played", "N/A")
                        track_name = item.get("master_metadata_track_name", "N/A")
                        artist_name = item.get("master_metadata_album_artist_name", "N/A")
                        album_name = item.get("master_metadata_album_album_name", "N/A")
                        track_uri = item.get("spotify_track_uri", "N/A")
                        episode_name = item.get("episode_name", "N/A")
                        episode_show_name = item.get("episode_show_name", "N/A")
                        episode_uri = item.get("spotify_episode_uri", "N/A")
                        reason_start = item.get("reason_start", None)
                        reason_end = item.get("reason_end", None)
                        shuffle = item.get("shuffle", None)
                        skipped = item.get("skipped", None)
                        offline = item.get("offline", None)
                        offline_timestamp = item.get("offline_timestamp", None)
                        file = fname


                        cur.execute("""
                            insert into streaming_history
                            (timestamp, time_played, track_name,
                            artist_name, album_name, track_uri, episode_name,
                            episode_show_name, episode_uri, reason_start, reason_end,
                            shuffle, skipped, offline, offline_timestamp, file)
                            values (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                        """, (timestamp, time_played, track_name,
                            artist_name, album_name, track_uri, episode_name,
                            episode_show_name, episode_uri, reason_start, reason_end,
                            shuffle, skipped, offline, offline_timestamp, file)
                        )
                    print(f"Finished importing {fname}. Add another file or type exit")
                else:
                    print("This JSON is not a list. Skipping.")
                      
        print('Commiting and closing database connection...')
        conn.commit()

