SELECT *
FROM SQL_Project..[covid-death]

SELECT *
FROM SQL_Project..[covid-vaccinations] 

-- Selecting the data

SELECT LOCATION, date, total_cases,
                       new_cases,
                       total_deaths,
                       population
FROM SQL_Project..[covid-death]
ORDER BY 1,2 


--Total Cases vs. Total Deaths (What percent of infected people passed away )

SELECT LOCATION, date, total_cases,
                       total_deaths,
                       round((total_deaths/total_cases)*100,
                             2) AS death_percent
FROM SQL_Project..[covid-death]
WHERE continent IS NOT NULL 
ORDER BY 1,2 


-- Total cases vs. Population 
--(What percent of population got infected so far from 2020-01-27)

SELECT LOCATION, 
       date, 
       total_cases,
       population,
       (total_cases/population)*100 AS Infected_population_perc
FROM SQL_Project..[covid-death]
WHERE continent IS NOT NULL
ORDER BY 1,2 


-- Countries in the order of Infection rate till 24-01-2022 
--(Percent of the population infected with Covid-19)

SELECT LOCATION,
       MAX(total_cases) AS Highest_infection_count,
       population,
       MAX((total_cases/population)*100) AS Infected_population_perc
FROM SQL_Project..[covid-death]
WHERE continent IS NOT NULL 
GROUP BY LOCATION,
         population
ORDER BY Infected_population_perc DESC 



-- Countries in order of Death rate till 24-01-2022 (Percent of population died of Covid-19)

SELECT LOCATION,
       MAX(CAST (total_deaths AS int)) AS Highest_death_count,
       population,
       MAX((total_deaths/population)*100) AS population_perc_died
FROM SQL_Project..[covid-death]
WHERE continent IS NOT NULL 
GROUP BY LOCATION,
         population
ORDER BY population_perc_died DESC 



-- Countries in order of Death count

SELECT LOCATION,
       MAX(cast(total_deaths AS int)) AS Total_daeth_count
FROM SQL_Project..[covid-death]
WHERE continent IS NOT NULL
GROUP BY LOCATION
ORDER BY Total_daeth_count DESC 


-- Total death count across continents

SELECT LOCATION,
       MAX(cast(total_deaths AS int)) AS Total_daeth_count
FROM SQL_Project..[covid-death]
WHERE continent IS NULL
GROUP BY LOCATION
ORDER BY Total_daeth_count DESC 


-- Total population in order of continets

SELECT sum(population) AS continent_pop,
       continent
FROM SQL_Project..[covid-death]
WHERE continent in ('North America',
                    'South America',
                    'Asia',
                    'Africa',
                    'Oceania',
                    'Europe')
  AND date in
    (SELECT Max(date)
     FROM SQL_Project..[covid-death])
GROUP BY continent 


-- Continents with the highest death rate (Percent of population died of Covid)

SELECT LOCATION,
       population,
       MAX(cast(total_deaths AS int)) AS total_daeth,
       (MAX(cast(total_deaths AS int)) / population) AS Total_daeth_rate
FROM SQL_Project..[covid-death]
WHERE continent IS NULL
GROUP BY population,
         LOCATION
ORDER BY Total_daeth_rate DESC 



--- Global Figures
-- 1. Daily Percentage of death of new cases

SELECT date, Sum(new_cases) AS total_cases,
             Sum(cast(new_deaths AS int)) AS total_deaths,
             Sum(cast(new_deaths AS int)) / Sum(new_cases) AS Death_percent
FROM SQL_Project..[covid-death]
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2 



-- 2. Total cases and death as of 24-01-2022

SELECT Sum(new_cases) AS total_cases,
       Sum(cast(new_deaths AS int)) AS total_deaths,
       Sum(cast(new_deaths AS int)) / Sum(new_cases) AS Death_percent
FROM SQL_Project..[covid-death]
WHERE continent IS NOT NULL 



-- 3. Total population vaccinated per country (till 24-01-2022)

  SELECT dea.location,
         population,
         Max(CAST (total_vaccinations AS bigint)) AS Total_vaccination
  FROM SQL_Project..[covid-death] dea
  JOIN SQL_Project..[covid-vaccinations] vac ON dea.location = vac.location
  AND dea.date = vac.date WHERE dea.continent IS NOT NULL
GROUP BY dea.location,
         population
ORDER BY Total_vaccination DESC


-- 4. Total population vs. Vaccination daily stats

SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations
FROM SQL_Project..[covid-death] dea
JOIN SQL_Project..[covid-vaccinations] vac ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3 


-- 5. Rolling count of vaccination

SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       Sum(Convert(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location
                                                        ORDER BY dea.location,
                                                        dea.date) AS Rolling_vac_count
FROM SQL_Project..[covid-death] dea
JOIN SQL_Project..[covid-vaccinations] vac ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3 



-- 6. Rollong percent of vaccination per country population (Use of CTE) 
--(Not to confuse with percent of population taken first, second or third dose)

 WITH Perc_pop_vaccinated (continent,
                           LOCATION, date, population,
                                           new_vaccinations,
                                           Rolling_vac_count) AS
  (SELECT dea.continent,
          dea.location,
          dea.date,
          dea.population,
          vac.new_vaccinations,
          Sum(Convert(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location
                                                           ORDER BY dea.location,
                                                           dea.date) AS Rolling_vac_count
   FROM SQL_Project..[covid-death] dea
   JOIN SQL_Project..[covid-vaccinations] vac ON dea.location = vac.location
   AND dea.date = vac.date
   WHERE dea.continent IS NOT NULL 
)

SELECT *,
       (Rolling_vac_count/population)*100 AS Vaccination_perc_population
FROM Perc_pop_vaccinated 




-- 7.Above Stats with Temp Table

DROP TABLE IF EXISTS #Perc_pop_vaccinated
CREATE TABLE #Perc_pop_vaccinated (continent nvarchar(255),
                                  LOCATION nvarchar(255), 
                                  date datetime,
                                  population numeric, new_vaccinations numeric, Rolling_vac_count numeric)
INSERT INTO #Perc_pop_vaccinated
SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       Sum(Convert(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location
                                                        ORDER BY dea.location,
                                                        dea.date) AS Rolling_vac_count
FROM SQL_Project..[covid-death] dea
JOIN SQL_Project..[covid-vaccinations] vac ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 

SELECT *,
(Rolling_vac_count/population)*100 AS Vaccination_perc_population
FROM #Perc_pop_vaccinated
ORDER BY LOCATION, date 



-- Create View to store data for later visualizations

CREATE VIEW RollingPercentVaccine AS
SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       Sum(Convert(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location
                                                        ORDER BY dea.location,
                                                                 dea.date) AS Rolling_vac_count
FROM SQL_Project..[covid-death] dea
JOIN SQL_Project..[covid-vaccinations] vac ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
  SELECT *
  FROM RollingPercentVaccine