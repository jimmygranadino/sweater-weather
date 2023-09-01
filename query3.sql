/* QUERY 3
PROBLEM:
You're trapped in the past but determined to enjoy yourself anyway.
It's 2011. You're an avid & optimistic boater but don't like boating alone.
You've fortunately retained your sense of foresight since you bought your home.
You want to pick a state for your next day-long pleasure cruise where you'll
have the greatest chance of encountering other boaters while you're on the water.
As of 2009, according to the National Marine Manufacturers Association, one in 10 U.S. households owns a boat,
and you're going to assume for convenience that's true in all 50 states.
You're also guessing there's a 50% chance those boat owners go out on the balmiest day of the year (i.e. 75° F, no rain).
Optimizing for these factors and using these facts, census data, and weather data,
in which state and on which top 10 days in 2011 should you set your sights on hitting the water? */
-- ANALYSIS:

WITH state_historically_balmy_day AS
    (
        SELECT
            state,
            doy_std, 
            75 AS balmy, 
            MIN(doy_std) OVER(PARTITION BY state ORDER BY doy_std) AS generic_doy,
            AVG(tot_precipitation_in) AS historical_avg_daily_precip,
            AVG(avg_temperature_feelslike_2m_f) AS historical_avg_temp, 
            ABS(balmy - historical_avg_temp) AS delta_balmy

        FROM 
            sweater_weather.jgranadino.history_day

        WHERE 
            country = 'US'

        GROUP BY 
            state, 
            doy_std 

        ORDER BY 
            delta_balmy ASC, 
            initcap(state)
    ),
state_mappings AS
    (
        SELECT
            geo.stusab::VARCHAR, 
            state::NUMBER AS state, 
            s.state_name::VARCHAR AS state_name

        FROM 
            sweater_weather.jgranadino.census_geo AS geo
            JOIN sweater_weather.jgranadino.states AS s ON geo.stusab = s.state_code
    ), 
state_water_areas AS 
    (
        SELECT DISTINCT
            SUM(bga.awater) OVER(PARTITION BY state) AS water_m_2, 
            geo.stusab, 
            s.state_name

        FROM 
            sweater_weather.jgranadino.census_block_group_attribs AS bga
            JOIN sweater_weather.jgranadino.census_geo AS geo ON bga.statefp = geo.state
            JOIN sweater_weather.jgranadino.states AS s ON geo.stusab = s.state_code
    ),
state_most_boaters AS 
    (
        SELECT 
            epd.name, 
            epd.census2010pop * 0.10 AS total_boaters, 
            total_boaters * 0.5 AS boaters_out

        FROM 
            sweater_weather.jgranadino.census_pop_data AS epd
            JOIN state_water_areas AS swa ON epd.name = swa.state_name
    )

SELECT TOP 10
    table1.state, 
    (table3.water_m_2 / table2.boaters_out) AS water_per_boater, 
    table4.date, 
    historical_avg_daily_precip, 
    delta_balmy

FROM 
    state_historically_balmy_day AS table1 
    JOIN state_most_boaters AS table2 ON table1.state = table2.name
    JOIN state_water_areas AS table3 ON table1.state = table3.state_name
    JOIN sweater_weather.jgranadino.date_schedules AS table4 ON table1.doy_std = table4.day_of_year

WHERE 
    historical_avg_daily_precip < 0.01 AND table4.year = 2011 AND table1.delta_balmy < 1.0 AND water_per_boater IN
    (
        SELECT 
            MIN(swa_2.water_m_2 / smb_2.boaters_out) AS water_per_boater 

        FROM 
            state_historically_balmy_day AS shbd_2
            JOIN state_most_boaters AS smb_2 ON shbd_2.state = smb_2.name
            JOIN state_water_areas AS swa_2 ON shbd_2.state = swa_2.state_name
            JOIN sweater_weather.jgranadino.date_schedules AS ds_2 ON shbd_2.doy_std = ds_2.day_of_year

        GROUP BY 
            shbd_2.state, ds_2.date HAVING shbd_2.state = table1.state AND table4.date = ds_2.date
    )

ORDER BY 
    delta_balmy ASC;