/* QUERY 1     
PROBLEM:
You want to go on a week-long vacation somewhere in the U.S. with your perfect sweater weather
(i.e. as close to 65°F all week and with very little rain all week).
  Which is the best city and 7-day span next year to do so based on historical weather data? */
-- ANALYSIS:

WITH step_1 AS 
    ( 
    SELECT 
            history_day.city, 
            history_day.state, 
            history_day.date_valid_std, 
            history_day.doy_std,
            SUM(tot_precipitation_in) OVER (PARTITION BY history_day.city ORDER BY date_valid_std ASC ROWS BETWEEN CURRENT ROW AND 6 FOLLOWING) AS rolling_weekly_tot_precip,
            AVG(max_temperature_feelslike_2m_f) OVER (PARTITION BY history_day.city ORDER BY date_valid_std ASC ROWS BETWEEN CURRENT ROW AND 6 FOLLOWING) AS rolling_weekly_avg_max_temp,
            MIN(date_valid_std) OVER (PARTITION BY history_day.city ORDER BY date_valid_std ASC ROWS BETWEEN CURRENT ROW AND 6 FOLLOWING) AS week_start,
            MIN(doy_std) OVER (PARTITION BY history_day.city ORDER BY doy_std ROWS BETWEEN CURRENT ROW AND 6 FOLLOWING) AS generic_week_start, 
            history_day.country

    FROM 
        sweater_weather.jgranadino.history_day 

    ORDER BY 
        week_start, 
        rolling_weekly_tot_precip, 
        rolling_weekly_avg_max_temp 
    ),
step_2 AS 
    ( 
    SELECT 
        step_1.city, 
        step_1.state, 
        (AVG(step_1.rolling_weekly_tot_precip)) AS historical_average_rolling_weekly_tot_precip, 
        (AVG(step_1.rolling_weekly_avg_max_temp)) AS historical_average_rolling_weekly_avg_max_temp, 
        (ABS(65 - historical_average_rolling_weekly_avg_max_temp)) AS delta_sweater_weather, 
        step_1.generic_week_start

    FROM 
        step_1

    GROUP BY 
        step_1.city,
        step_1.state,
        step_1.generic_week_start,
        country HAVING country = 'US' 

    ORDER BY 
        delta_sweater_weather ASC, 
        historical_average_rolling_weekly_avg_max_temp DESC
    )

SELECT 
    s2.city, 
    s2.state, 
    historical_average_rolling_weekly_tot_precip, 
    historical_average_rolling_weekly_avg_max_temp, 
    delta_sweater_weather, 
    generic_week_start, 
    ds.date

FROM 
    step_2 AS s2
    JOIN sweater_weather.jgranadino.date_schedules AS ds ON s2.generic_week_start = ds.day_of_year 

WHERE 
    historical_average_rolling_weekly_tot_precip < 0.1 AND ds.year = 2020

ORDER BY 
    delta_sweater_weather ASC

LIMIT 10;