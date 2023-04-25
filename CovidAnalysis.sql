---CREATE TABLE---


CREATE TABLE Covid_Deaths(
iso_code Text,
continent Text,
location Text,
date Date ,
population Numeric,
total_cases Numeric,
new_cases Numeric,
new_cases_smoothed Numeric,
total_deaths Numeric,
new_deaths Numeric,
new_deaths_smoothed Numeric,
total_cases_per_million Numeric,
new_cases_per_million Numeric,
new_cases_smoothed_per_million Numeric,
total_deaths_per_million Numeric,
new_deaths_per_million Numeric,
new_deaths_smoothed_per_million Numeric,
reproduction_rate Numeric,
icu_patients Numeric,
icu_patients_per_million Numeric,
hosp_patients Numeric,
hosp_patients_per_million Numeric,
weekly_icu_admissions Numeric,
weekly_icu_admissions_per_million Numeric,
weekly_hosp_admissions Numeric,
weekly_hosp_admissions_per_million Numeric
);

---CREATE TABLE---

Create Table Covid_Vaccinations 
(iso_code Text,
continent Text,
location Text ,
date Date,
new_tests Numeric,
total_tests Numeric,
total_tests_per_thousand Numeric ,
new_tests_per_thousand Numeric ,
new_tests_smoothed Numeric ,
new_tests_smoothed_per_thousand Numeric ,
positive_rate Numeric ,
tests_per_case Numeric ,
tests_units Text,
total_vaccinations Numeric,
people_vaccinated Numeric,
people_fully_vaccinated Numeric,
new_vaccinations Numeric,
new_vaccinations_smoothed Numeric,
total_vaccinations_per_hundred Numeric ,
people_vaccinated_per_hundred Numeric ,
people_fully_vaccinated_per_hundred Numeric ,
new_vaccinations_smoothed_per_million Numeric ,
stringency_index Numeric,
population_density Numeric ,
median_age Numeric ,
aged_65_older Numeric ,
aged_70_older Numeric ,
gdp_per_capita Numeric ,
extreme_poverty Numeric ,
cardiovasc_death_rate Numeric ,
diabetes_prevalence Numeric ,
female_smokers Numeric ,
male_smokers Numeric ,
handwashing_facilities Numeric ,
hospital_beds_per_thousand Numeric ,
life_expectancy Numeric ,
human_development_index Numeric 
);


---Table Altering---
ALTER TABLE Covid_deaths
RENAME COLUMN location to Country


--- Daily Total_cases vs Total_deaths---
SELECT
Country,
Date,
total_cases,
total_deaths,
Round((total_deaths/Total_cases) * 100 ,2)
FROM covid_deaths
WHERE continent IS NOT null
ORDER BY 1,2

---Percentage of the population infected--
SELECT
country,
Date,
Population,
Total_cases,
Round((Total_cases / population)*100,2)
FROM covid_deaths
WHERE Continent IS NOT null
ORDER BY 1,2 

---Percentage of the population that died from covid--
SELECT
Country,
Date,
Population,
Total_Deaths,
Round((Total_deaths / population)*100,4)
FROM covid_deaths
WHERE Continent IS NOT null
ORDER BY 1,2 


---Looking at county with the highest infection rate--
SELECT
Country,
Population,
MAX(Total_cases) AS highest_infection_count,
ROUND(MAX(Total_cases / Population) *100 ,2) AS percentage_population_infected
FROM Covid_deaths
GROUP BY 1,2
ORDER BY 4 DESC


---Looking at country with the highest death rate--
SELECT
Country,
Population,
MAX(Total_deaths) AS highest_deaths_count,
Round(MAX(Total_deaths / Population) *100 ,2) AS Death_Rate
FROM Covid_deaths
WHERE Continent IS NOT null
GROUP BY 1,2
ORDER BY 4 DESC


---Looking at country with the highest death count per poplulation--
SELECT 
Country,
MAX(Total_deaths) AS Total_death_count
FROM Covid_deaths
WHERE continent IS NOT null AND
Total_deaths IS NOT null
GROUP BY 1
ORDER BY 2 DESC

---showing continent with the highest death count---
SELECT 
Continent,
MAX(Total_deaths) AS Total_death_count
FROM Covid_deaths
WHERE continent IS NOT null 
GROUP BY 1
ORDER BY 2 DESC

---Global Numbers--
SELECT 
Date,
SUM(new_cases) AS Total_cases,
SUM(new_deaths) AS Total_deaths,
Round((SUM(new_deaths)  / SUM(new_cases))*100,2) AS DeathPercentage
FROM covid_deaths
WHERE continent IS NOT null
GROUP BY 1
ORDER BY 1,2

--Looking at total vaccination VS population--

SELECT
CD.Continent,
CD.Country,
CD.Date,
CD.POPULATION,
CAST(CV.new_vaccinations AS INT)
FROM covid_deaths CD
INNER JOIN covid_vaccinations CV
ON CD.country = CV.location
AND CD.Date = CV.date
WHERE  CD.Continent IS NOT null

--Looking at total vaccination Rolling_Total--

SELECT
CD.Continent,
CD.Country,
CD.Date,
CD.POPULATION,
CV.new_vaccinations,
SUM(CV.new_vaccinations) OVER(PARTITION BY CD.country ORDER BY CD.Country,CD.Date) AS Rolling_Total
FROM covid_deaths CD
INNER JOIN covid_vaccinations CV
ON CD.country = CV.location
AND CD.Date = CV.date
WHERE  CD.Continent IS NOT null
ORDER BY 2,3


--Total number of people vaccinated Vs population Using Subquery---

SELECT
Continent,
Country,
Date,
POPULATION,
new_vaccinations,
SUM(new_vaccinations) OVER(PARTITION BY country ORDER BY Country,Date) Rolling_Total,
Round((Rolling_Total/ Population)*100,2) AS Rolling_PercentageVaccinated
FROM 
(SELECT
CD.Continent,
CD.Country,
CD.Date,
CD.Population,
CV.new_vaccinations,
SUM(CV.new_vaccinations) OVER(PARTITION BY CD.country ORDER BY CD.Country,CD.Date) AS Rolling_Total
FROM covid_deaths CD
INNER JOIN covid_vaccinations CV
ON CD.country = CV.location
AND CD.Date = CV.date
WHERE  CD.Continent IS NOT null
ORDER BY 2,3) SA

--Total number of people vaccinated Vs population Using CTE---

WITH VacvsPOP
AS
(SELECT
CD.Continent,
CD.Country,
CD.Date,
CD.POPULATION,
CV.new_vaccinations,
SUM(CV.new_vaccinations) OVER(PARTITION BY CD.country ORDER BY CD.Country,CD.Date) AS  Rolling_Total
FROM covid_deaths CD
INNER JOIN covid_vaccinations CV
ON CD.country = CV.location
AND CD.Date = CV.date
WHERE  CD.Continent IS NOT null)

SELECT *,Round((Runing_Total / population)*100 ,2) FROM VacvsPOP

---Showing the daily percentage difference of the number of new vaccination fix---
 
SELECT
CD.Continent,
CD.Country,
CD.Date,
CD.POPULATION,
CV.new_vaccinations,
LAG(new_vaccinations) OVER(PARTITION BY CD.country ORDER BY CD.Country,CD.Date) AS PreviosDaysVaccination,
(LAG(new_vaccinations) OVER(PARTITION BY CD.country ORDER BY CD.Country,CD.Date) - CV.new_vaccinations) / 
LAG(new_vaccinations) OVER(PARTITION BY CD.country ORDER BY CD.Country,CD.Date)
FROM covid_deaths CD
INNER JOIN covid_vaccinations CV
ON CD.country = CV.location
AND CD.Date = CV.date
WHERE  CD.Continent IS NOT null AND CV.new_vaccinations is not null


---Creating views for later visualization---

CREATE VIEW 
Total_Vaccination_Rolling_Total
AS
SELECT
CD.Continent,
CD.Country,
CD.Date,
CD.POPULATION,
CV.new_vaccinations,
SUM(CV.new_vaccinations) OVER(PARTITION BY CD.country ORDER BY CD.Country,CD.Date) AS Rolling_Total
FROM covid_deaths CD
INNER JOIN covid_vaccinations CV
ON CD.country = CV.location
AND CD.Date = CV.date
WHERE  CD.Continent IS NOT null
ORDER BY 2,3

CREATE VIEW 
New_Vaccination_VS_Population
AS
SELECT
Continent,
Country,
Date,
POPULATION,
new_vaccinations,
SUM(new_vaccinations) OVER(PARTITION BY country ORDER BY Country,Date) Rolling_Total,
Round((Rolling_Total/ Population)*100,2) AS Rolling_PercentageVaccinated
FROM 
(SELECT
CD.Continent,
CD.Country,
CD.Date,
CD.Population,
CV.new_vaccinations,
SUM(CV.new_vaccinations) OVER(PARTITION BY CD.country ORDER BY CD.Country,CD.Date) AS Rolling_Total
FROM covid_deaths CD
INNER JOIN covid_vaccinations CV
ON CD.country = CV.location
AND CD.Date = CV.date
WHERE  CD.Continent IS NOT null
ORDER BY 2,3) SA

