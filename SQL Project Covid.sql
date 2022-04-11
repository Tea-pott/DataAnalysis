SELECT *
FROM SQL_Project..[covid-death]

SELECT *
FROM SQL_Project..[covid-vaccinations]


-- Selecting the data

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM SQL_Project..[covid-death]
order by 1,2


--Total Cases vs. Total Deaths (What percent of infected people passed away )

SELECT location, date, total_cases, total_deaths, round((total_deaths/total_cases)*100, 2) AS death_percent
From SQL_Project..[covid-death]
WHERE continent is not null
--Where location = 'Germany'
order by 1,2


-- Total cases vs. Population (What percent of population got infected so far from 2020-01-27)

SELECT location, date, total_cases, population, (total_cases/population)*100 AS Infected_population_perc
From SQL_Project..[covid-death]
WHERE continent is not null
order by 1,2


-- Countries in the order of Infection rate till 24-01-2022 (Percent of the population infected with Covid-19)

SELECT location, MAX(total_cases) as Highest_infection_count, population, MAX((total_cases/population)*100) as Infected_population_perc
From SQL_Project..[covid-death]
WHERE continent is not null
--Where location = 'Germany'
Group by location, population
order by Infected_population_perc desc


-- Countries in order of Death rate till 24-01-2022 (Percent of population died of Covid-19)

SELECT location, MAX(cast (total_deaths as int)) as Highest_death_count, population, MAX((total_deaths/population)*100) as population_perc_died
From SQL_Project..[covid-death]
WHERE continent is not null
--Where location = 'Germany'
Group by location, population
order by population_perc_died desc


-- Countries in order of Death count

SELECT location, MAX(cast(total_deaths as int)) as Total_daeth_count 
From SQL_Project..[covid-death]
WHERE continent is not null
Group by location
Order by Total_daeth_count desc


-- Total death count across continents

SELECT location, MAX(cast(total_deaths as int)) as Total_daeth_count
From SQL_Project..[covid-death]
WHERE continent is null
Group by location
Order by Total_daeth_count desc


-- Total population in order of continets

SELECT sum(population) as continent_pop, continent
From SQL_Project..[covid-death]
WHERE continent in ('North America', 'South America', 'Asia', 'Africa', 'Oceania', 'Europe') and date in (SELECT Max(date) 
From SQL_Project..[covid-death])
Group by continent


-- Continents with the highest death rate (Percent of population died of Covid)

SELECT location, population, MAX(cast(total_deaths as int)) as total_daeth, (MAX(cast(total_deaths as int)) / population) as Total_daeth_rate
From SQL_Project..[covid-death]
WHERE continent is null
Group by population, location
Order by Total_daeth_rate desc




--- Global Figures

-- 1. Daily Percentage of death of new cases  

SELECT date, Sum(new_cases) as total_cases, Sum(cast(new_deaths as int)) as total_deaths,
	   Sum(cast(new_deaths as int)) / Sum(new_cases) as Death_percent
From SQL_Project..[covid-death]
WHERE continent is not null
Group by date
Order by 1,2


-- 2. Total cases and death as of 24-01-2022

SELECT Sum(new_cases) as total_cases, Sum(cast(new_deaths as int)) as total_deaths,
	   Sum(cast(new_deaths as int)) / Sum(new_cases) as Death_percent
From SQL_Project..[covid-death]
WHERE continent is not null


-- 3. Total population vaccinated per country (till 24-01-2022)

SELECT dea.location, population, Max(cast (total_vaccinations as bigint)) as Total_vaccination
From SQL_Project..[covid-death] dea
Join SQL_Project..[covid-vaccinations] vac
	On dea.location = vac.location 
	and dea.date = vac.date
WHERE dea.continent is not null
Group by dea.location, population
Order by Total_vaccination desc


-- 4. Total population vs. Vaccination daily stats 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From SQL_Project..[covid-death] dea
Join SQL_Project..[covid-vaccinations] vac
	On dea.location = vac.location 
	and dea.date = vac.date
WHERE dea.continent is not null
Order by 2,3


-- 5. Rolling count of vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	Sum(Convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,
	dea.date) as Rolling_vac_count
From SQL_Project..[covid-death] dea
Join SQL_Project..[covid-vaccinations] vac
	On dea.location = vac.location 
	and dea.date = vac.date
WHERE dea.continent is not null
Order by 2,3


-- 6. Rollong percent of vaccination per country population (Use of CTE) (Not to confuse with percent of population taken first, second or third dose)  

With Perc_pop_vaccinated (continent, location, date, population, new_vaccinations, Rolling_vac_count)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	Sum(Convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,
	dea.date) as Rolling_vac_count
From SQL_Project..[covid-death] dea
Join SQL_Project..[covid-vaccinations] vac
	On dea.location = vac.location 
	and dea.date = vac.date
WHERE dea.continent is not null
-- Order by 2,3
)
Select *, (Rolling_vac_count/population)*100 as Vaccination_perc_population 
From Perc_pop_vaccinated 


-- 7.Above Stats with Temp Table

DROP Table if exists #Perc_pop_vaccinated 
Create table #Perc_pop_vaccinated 
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
Rolling_vac_count numeric
)

Insert into #Perc_pop_vaccinated 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	Sum(Convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,
	dea.date) as Rolling_vac_count
From SQL_Project..[covid-death] dea
Join SQL_Project..[covid-vaccinations] vac
	On dea.location = vac.location 
	and dea.date = vac.date
WHERE dea.continent is not null
-- Order by 2,3

Select *, (Rolling_vac_count/population)*100 as Vaccination_perc_population 
From #Perc_pop_vaccinated 
order by location, date



-- Create View to store data for later visualizations 


Create View RollingPercentVaccine as 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	Sum(Convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,
	dea.date) as Rolling_vac_count
From SQL_Project..[covid-death] dea
Join SQL_Project..[covid-vaccinations] vac
	On dea.location = vac.location 
	and dea.date = vac.date
WHERE dea.continent is not null

Select * 
From RollingPercentVaccine

