Select *
From CovidDeaths
Where continent is not null
Order by 3,4

-- Select Data that we're going to be using

Select location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Where continent is not null
Order by 1,2

-- Looking at Total Cases vs Total Deaths
-- What's the likelihood of dying if you contract covid in Spain?
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths
Where Location like '%Spain%'
and continent is not null
Order by 1,2

-- Looking at Total Cases vs Population
-- What percentage of population infected with Covid?
Select location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths
Order by 1,2

-- What percentage of population got Covid in Spain?
Select location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths
Where Location like '%Spain%'
Order by 1,2

--What countries have highest infection rate compared to population?
Select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
GROUP BY location, population
Order by PercentPopulationInfected DESC

-- What countries have highest Death Count per Population?
Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
Where continent is not null
GROUP BY location
Order by TotalDeathCount DESC 

-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing continents with highest Death Count per Population
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
Where continent is not null
GROUP BY continent
Order by TotalDeathCount DESC 


-- GLOBAL NUMBERS
-- Global Death % per day
Select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as GlobalDeathPercentageperDay
From CovidDeaths
Where continent is not null
Group by date
Order by 1,2
-- Aggregate Global Death %
Select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as GlobalDeathPercentage
From CovidDeaths
Where continent is not null
--Group by date
Order by 1,2



-- Looking at Total Population vs Vaccinations

Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations
From CovidDeaths as dth
Join CovidVaccinations as vac
	ON dth.location = vac.location
	and dth.date = vac.date
	Where dth.continent is not null
Order by 2,3

--What Percentage of Population has received at least one Covid Vaccine?
Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations, 
sum(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dth.Location Order by dth.location, dth.date) as VaccinationsUpToDate
From CovidDeaths as dth
Join CovidVaccinations as vac
	ON dth.location = vac.location
	and dth.date = vac.date
	Where dth.continent is not null
Order by 2,3


-- Method 1 to perform calculation on Partition By in the previous query - USING A CTE 

With PopvsVac (Continent, Location, Date, Population, new_vaccinations, VaccinationsUpToDate)
as
(
Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations, 
sum(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dth.Location Order by dth.location, dth.date) as VaccinationsUpToDate
From CovidDeaths as dth
Join CovidVaccinations as vac
	ON dth.location = vac.location
	and dth.date = vac.date
Where dth.continent is not null
--Order by 2,3
)

Select *, (VaccinationsUpToDate/population)*100 as PercentagePopulationVaccinatedUpToDate
From PopvsVac


-- Method 2 to perform calculation on Partition By in the previous query - USING A TEMP TABLE

DROP TABLE if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime, 
Population numeric, 
New_vaccinations numeric,
VaccinationsUpToDate numeric)

Insert into #PercentPopulationVaccinated
Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations, 
sum(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dth.Location Order by dth.location, dth.date) as VaccinationsUpToDate
From CovidDeaths as dth
Join CovidVaccinations as vac
	ON dth.location = vac.location
	and dth.date = vac.date
--Where dth.continent is not null
--Order by 2,3

Select *, (VaccinationsUpToDate/population)*100 as PercentagePopulationVaccinatedUpToDate
From #PercentPopulationVaccinated





-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations, 
sum(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dth.Location Order by dth.location, dth.date) as VaccinationsUpToDate
From CovidDeaths as dth
Join CovidVaccinations as vac
	ON dth.location = vac.location
	and dth.date = vac.date
Where dth.continent is not null
--Order by 2,3

Select *
From PercentPopulationVaccinated