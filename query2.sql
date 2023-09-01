/* QUERY 2
PROBLEM:
You're shocked to discover your favorite sweater was a time machine.
Worse yet, it has unraveled on arrival.
Stranded, you're now a climate-conscious homebuyer in 2011 looking to acquire a home anywhere in any state in the U.S. and looking to install solar there.
As a citizen of the future and as a data professional, you also have the power of foresight and can extrapolate future historical weather patterns.
You're also thinking that the 2010 census data will give you a relatively good sense of where to start your search for an ideal property.
Using historical weather data and the 2010 census results, provide a ranked list optimizing the following two conditions combined:
Which state in the U.S. gets approximately the most available solar radiation across an entire year for a solar panel installation on your property?
Which state has the most available homes for purchase according to the census results?
Create a ranked list of the ideal states in which to buy your home, equally weighting both conditions. */
-- ANALYSIS:

WITH state_land_ratios AS
    ( 
        SELECT 
            state_code,
            (SUM(land_area_m2) / SUM(total_area_m2)) AS state_total_area_total_land_area_ratio

        FROM 
            sweater_weather.jgranadino.census_housing

        GROUP BY 
            state_code

        ORDER BY 
            state_total_area_total_land_area_ratio DESC   
    ),
most_homes_for_sale AS
    (
        SELECT
            state_code,
            SUM(
                CASE
                    WHEN vacancy_status = 'For Sale' THEN 1 
                    ELSE 0
                END
            ) AS total_for_sale

        FROM 
            sweater_weather.jgranadino.census_housing

        GROUP BY 
            state_code 

        ORDER BY 
            total_for_sale DESC
    ),
total_solar_radiation AS 
    (
        SELECT 
            state.state_code,
            SUM(avg_of__daily_tot_radiation_solar_total_wpm2) AS yearly_tot_solar_radiation

        FROM 
            sweater_weather.jgranadino.climatology_day AS cd
            JOIN sweater_weather.jgranadino.states AS state ON COLLATE(cd.state, 'en-ci') = COLLATE(state.state_name, 'en-ci')

        WHERE 
            cd.country = 'US'

        GROUP BY
            state.state_code

        ORDER BY 
            yearly_tot_solar_radiation DESC
)

SELECT 
    most_homes_for_sale.state_code, 
    yearly_tot_solar_radiation, 
    state_total_area_total_land_area_ratio, 
    (yearly_tot_solar_radiation * state_total_area_total_land_area_ratio) AS yearly_state_total_available_land_radiation, 
    RANK() OVER (ORDER BY yearly_state_total_available_land_radiation DESC) AS rank_radiation, 
    total_for_sale, 
    RANK() OVER (ORDER BY total_for_sale DESC) AS rank_total_for_sale

FROM 
    total_solar_radiation, 
    most_homes_for_sale, 
    state_land_ratios 

WHERE 
    total_solar_radiation.state_code = most_homes_for_sale.state_code AND total_solar_radiation.state_code = state_land_ratios.state_code

ORDER BY 
    rank_radiation + rank_total_for_sale ASC, 
    rank_radiation ASC;