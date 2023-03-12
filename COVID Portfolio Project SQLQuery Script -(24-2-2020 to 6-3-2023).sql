/* 
COVID 19 DATA EXPLORATION. DATA COVERS FROM 24/2/2020 TO 6/3/2023
*/

select *
from CovidDeaths$
where continent is not null
order by 3,4

--select *
--from CovidVaccinations$
--where continent is not null
--order by 3,4

--Data used

select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths$
where continent is not null
order by 1,2

--Total cases vs Total Deaths (Whole Data. Remove comment marks to view country by country)
--Shows the likelihood of dying if you get COVID as as 6 June, 2023.

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths$
--where location like '%Nigeria%'
where continent is not null
order by 1,2


--Total cases vs Population (Whole Data. Remove comments marks to view country by country)
--Shows what percentage of the Population got COVID

select location, date, population, total_cases, (total_cases/population)*100 as InfectedPopulationPercentage
from CovidDeaths$
--where location like '%Nigeria%'
where continent is not null
order by 1,2


--Countries with highest infection rate compared to population

select location, population, Max(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as InfectedPopulationPercentage
from CovidDeaths$
--where location like '%Nigeria%'
where continent is not null
Group by Location, Population
order by InfectedPopulationPercentage desc


--Countries with highest death counts per population

select location, MAX(cast(total_deaths as bigint)) as HighestDeathCount
from CovidDeaths$
--where location like '%Nigeria%'
where continent is not null
Group by location
order by HighestDeathCount desc


--Breaking things down by continent
--Showing continents with the highest death count per population
--correct for me

select location, MAX(cast(total_deaths as bigint)) as HighestDeathCount
from CovidDeaths$
--where location like '%Africa%'
where continent is null
Group by location
order by HighestDeathCount desc

select continent, MAX(cast(total_deaths as bigint)) as HighestDeathCount
from CovidDeaths$
--where location like '%Africa%'
where continent is not null
Group by continent
order by HighestDeathCount desc


--Global numbers

select date, sum(new_cases) as Total_cases, sum(cast(new_deaths as int)) as Total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathToInfectionPercentage
from CovidDeaths$
--where location like '%Nigeria%'
where continent is not null
group by date
order by 1,2

--Overall global numbers

select sum(new_cases) as Total_cases, sum(cast(new_deaths as int)) as Total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathToInfectionPercentage
from CovidDeaths$
--where location like '%Nigeria%'
where continent is not null
--group by date
order by 1,2


--Total population vs Vaccinations as a rolling/cummulative count

select Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations
, SUM(convert(bigint,Vac.new_vaccinations)) OVER (Partition by Dea.location Order by Dea.location, Dea.date ROWS UNBOUNDED PRECEDING)
as CummulativePeopleVaccinated
from CovidDeaths$ Dea
join CovidVaccinations$ Vac
	on Dea.location = Vac.location 
	and Dea.date = Vac.date
where Dea.continent is not null
order by 1,2,3


/* 
When you partition by a value, there is no point ordering by it alos, the partition by location and order by location
caused the error message, "Order by list range window frame has total size of 1020 bytes. Largest size supported is 900 bytes.".
To solve it, you either remove the location after order by, as below, or you disable the default range with the "ROWS UNBOUNDED PRECEDING" query as above.
Also, use "bigint" instead of just "int" when the data is very large.

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths$ dea
Join CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3
*/


--Get the percentage of total population vaccinated daily in two ways-CTE and Temp Table
--A CTE to get the percentage of total population vaccinated daily.

With PopvsVac (Continent, location, date, population, new_vaccinations, CummulativePeopleVaccinated)
as
(
select Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations
, SUM(convert(bigint,Vac.new_vaccinations)) OVER (Partition by Dea.location Order by Dea.location, Dea.date ROWS UNBOUNDED PRECEDING)
as CummulativePeopleVaccinated
from CovidDeaths$ Dea
join CovidVaccinations$ Vac
	on Dea.location = Vac.location 
	and Dea.date = Vac.date
where Dea.continent is not null
--order by 1,2,3
)
select *, (CummulativePeopleVaccinated/population)*100 as PercentageofPopulationVaccinated
from PopvsVac


--Temporary Table

Drop Table if exists PercentageofPopulationVaccinated
Create table PercentageofPopulationVaccinated
(
Continent nvarchar(255), 
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
CummulativePeopleVaccinated numeric
)

insert into PercentageofPopulationVaccinated
select Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations
, SUM(convert(bigint,Vac.new_vaccinations)) OVER (Partition by Dea.location Order by Dea.location, Dea.date ROWS UNBOUNDED PRECEDING)
as CummulativePeopleVaccinated
from CovidDeaths$ Dea
join CovidVaccinations$ Vac
	on Dea.location = Vac.location 
	and Dea.date = Vac.date
--where Dea.continent is not null
--order by 1,2,3

select *, (CummulativePeopleVaccinated/population)*100 as PercentageofPopulationVaccinated
from PercentageofPopulationVaccinated

 
 --Creating view for visualization

create view PercentofPopulationVaccinated as
select Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations
, SUM(convert(bigint,Vac.new_vaccinations)) OVER (Partition by Dea.location Order by Dea.location, Dea.date ROWS UNBOUNDED PRECEDING)
as CummulativePeopleVaccinated
from CovidDeaths$ Dea
join CovidVaccinations$ Vac
	on Dea.location = Vac.location 
	and Dea.date = Vac.date
where Dea.continent is not null
--order by 1,2,3

select *
from PercentofPopulationVaccinated
