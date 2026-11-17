
-- COVID-19 Data Exploration (SQLite)
-- Data: Our World in Data (Feb 2020 – Apr 2021) | Adapted from Alex the Analyst's tutorial, rewritten for SQLite
-- Skills used: Joins, CTEs, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types


Select *
From CovidDeaths
Where continent is not null 
order by 3,4;


Select Location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Where continent is not null 
order by 1,2;


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths
Where location like 'India'
and continent is not null 
order by 1,2;


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths
--Where location like 'India'
order by 1,2;


-- Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
--Where location like 'India'
Group by Location, Population
order by PercentPopulationInfected desc;


-- Countries with Highest Death Count per Population
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
--Where location like 'India'
Where continent is not null 
Group by Location
order by TotalDeathCount desc;


-- BREAKING THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count per population
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
--Where location like 'India'
Where continent is not null 
Group by continent
order by TotalDeathCount desc;


-- Global Numbers 
Select sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 
as DeathPercentage
From CovidDeaths
-- Where location like 'India'
WHERE continent is not null;
-- Group by date
-- order by 1,2;


-- Looking at Total Population vs Vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(cast(vac.new_vaccinations as int)) over (PARTITION by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population) * 100
from CovidDeaths as dea
JOIN CovidVaccinations as vac 
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not NULL
order by 2,3;

-- Use CTE
with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(cast(vac.new_vaccinations as int)) over (PARTITION by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population) * 100
FROM CovidDeaths as dea
JOIN CovidVaccinations as vac 
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not NULL
-- order by 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100 as PercentVaccinated
from PopvsVac;


-- Temp Table 
DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMP TABLE PercentPopulationVaccinated
(
continent TEXT,
location TEXT,
date datetime,
population NUMERIC,
new_vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
);

Insert into PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(cast(vac.new_vaccinations as int)) over (PARTITION by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population) * 100
FROM CovidDeaths as dea
JOIN CovidVaccinations as vac 
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not NULL;

Select *, (RollingPeopleVaccinated/population)*100 AS PercentVaccinated
from PercentPopulationVaccinated;


-- Creating View for later visualizations
DROP VIEW IF EXISTS PercentPopulationVaccinatedView;
Create view PercentPopulationVaccinatedView as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(cast(vac.new_vaccinations as int)) over (PARTITION by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population) * 100
FROM CovidDeaths as dea
JOIN CovidVaccinations as vac 
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not NULL;

SELECT * FROM PercentPopulationVaccinatedView;