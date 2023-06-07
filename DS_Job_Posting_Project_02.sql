# **********CREATE TABLE + LOAD DATA **********

use dsjobpostings;

create table ds_jobs (
	Indexs int, Job_Title varchar(255),	Salary_Estimate varchar(255),  Job_Description text, Rating float,  
    Company_Name varchar(255), Location varchar(255), Headquarters varchar(255), Size varchar(255), Founded int,
    Type_of_ownership varchar(255),	Industry varchar(255),	Sector varchar(255), Revenue varchar(255), Competitors varchar(255));

load data infile 'Uncleaned_DS_jobs.csv' into table ds_jobs
fields terminated by ','
ignore 1 lines;

select * from ds_jobs;

#________________________________________________________________________
# **********DATA CLEANING & FEATURES ENGINEERING**********

use dsjobpostings;

select * from ds_jobs;

#########################################################################
# Job_Title:
select Job_Title, count(Job_Title)
from ds_jobs dj group by Job_Title;

ALTER TABLE ds_jobs ADD COLUMN Career varchar(255);

SET SQL_SAFE_UPDATES = 0;
update ds_jobs
set Career = case
	when lower(Job_Title) like '%data_scientist%' or lower(Job_Title) like '%scientist%' then 'Data Scientist'
    when lower(Job_Title) like '%data_engineer%' or lower(Job_Title) like '%engineer%' then 'Data Engineer'
	when lower(Job_Title) like '%data_analyst%' or lower(Job_Title) like '%analyst%' then 'Data Analyst'
	else 'Others'
    end;
SET SQL_SAFE_UPDATES = 1;

select Career, count(Career) from ds_jobs group by Career;

ALTER TABLE ds_jobs ADD COLUMN Job_Level varchar(255);

SET SQL_SAFE_UPDATES = 0;
update ds_jobs
set Job_Level = case
	when lower(Job_Title) like '%sr%' or lower(Job_Title) like '%senior%' or lower(Job_Title) like 'sr%' or lower(Job_Title) like '%lead%' or lower(Job_Title) like '%chief%' or lower(Job_Title) like 'instructor' then 'Senior'
	when lower(Job_Title) like '%jr%' or lower(Job_Title) like '%junior%' or lower(Job_Title) like 'jr%' then 'Junior'
	when lower(Job_Title) like '%manager%' or lower(Job_Title) like '%vp%' or lower(Job_Title) like 'vice_president' then 'Manager'
	else 'Staff'
    end;
SET SQL_SAFE_UPDATES = 1;

select Job_Level, count(Job_Level) from ds_jobs group by Job_Level;

######################################################################################
# Salary_Estimate:

ALTER TABLE ds_jobs ADD COLUMN Min_Salary varchar(255);
ALTER TABLE ds_jobs ADD COLUMN Max_Salary varchar(255);
ALTER TABLE ds_jobs ADD COLUMN Avg_Salary varchar(255);
ALTER TABLE ds_jobs ADD COLUMN Salary_Formated varchar(255);

# alter table ds_jobs drop column Min_Salary;

SET SQL_SAFE_UPDATES = 0;
update ds_jobs
set Salary_Formated = replace(replace(replace(replace(Salary_Estimate,'(Glassdoor est.)',''),'(Employer est.)',''),'$',''),'K','');
SET SQL_SAFE_UPDATES = 1;

SET SQL_SAFE_UPDATES = 0;
update ds_jobs
set Min_Salary = left(Salary_Formated, locate('-',Salary_Formated) - 1);
SET SQL_SAFE_UPDATES = 1;

SET SQL_SAFE_UPDATES = 0;
update ds_jobs
set Max_Salary = replace(Salary_Formated,left(Salary_Formated, locate('-',Salary_Formated)),'');
SET SQL_SAFE_UPDATES = 1;

SET SQL_SAFE_UPDATES = 0;
update ds_jobs
set Avg_Salary = (Min_Salary + Max_Salary)*0.5 ;
SET SQL_SAFE_UPDATES = 1;

select * from ds_jobs;

#####################################################################################
# Job_Description
with CTE_4  as (
	select Indexs,
	case
		when lower(Job_Description) like '%python%' then 1 else 0 end as Python,
	case
		when Job_Description like '%R%' then 1 else 0 end as R,
	case
		when lower(Job_Description) like '%java%' then 1 else 0 end as Java,
	case
		when lower(Job_Description) like '%scala%' then 1 else 0 end as Scala,
	case
		when Job_Description like '%C#%' then 1 else 0 end as C,    
	case
		when lower(Job_Description) like '%power_bi%' then 1 else 0 end as Power_BI ,
	case
		when lower(Job_Description) like '%tableau%' then 1 else 0 end as Tableau ,
	case 
		when lower(Job_Description) like '%excel%' then 1 else 0 end as Excel,
	case 
		when lower(Job_Description) like '%hadoop%' then 1 else 0 end as Hadoop,
	case 
		when lower(Job_Description) like '%aws%' then 1 else 0 end as AWS,
	case 
		when lower(Job_Description) like '%big_data%' then 1 else 0 end as Big_Data
	from ds_jobs)
select * from CTE_4;

select count(Indexs) from ds_jobs where lower(Job_Description) like '%big_data%';

#############################################################################
# Company_Name

select Indexs,
case
	when Company_Name like '%|%' then left(Company_Name,locate('|',Company_Name) - 1)
else Company_Name
end as Company_Name_F
from ds_jobs;

alter table ds_jobs add column Company_Name_Formated varchar(255);

SET SQL_SAFE_UPDATES = 0;
update ds_jobs
set Company_Name_Formated = case
	when Company_Name like '%|%' then left(Company_Name,locate('|',Company_Name) - 1)
    else Company_Name
    end;
SET SQL_SAFE_UPDATES = 1;

select distinct Company_Name_Formated from ds_jobs order by Company_Name_Formated asc;

#############################################################################
# Location & Headquarters

select Location, count(Location)
from ds_jobs
group by Location
having Location not like '%;%' and Location <> 'Remote';

SET SQL_SAFE_UPDATES = 0;
update ds_jobs
set Location = case
	when Location in ('United States','Utah','New Jersey','Texas', 'California') then 'US'
    when Location like '%;%' then right(Location, 2)
    else Location
    end;
SET SQL_SAFE_UPDATES = 1;		

alter table ds_jobs
add column Same_Location int;

SET SQL_SAFE_UPDATES = 0;
update ds_jobs
set Same_Location = case
	when Location = Headquarters or Location = right(Headquarters, 2) then 1
    else 0
    end;
SET SQL_SAFE_UPDATES = 1;

############################################################################
# Size

select Size, count(Size) from ds_jobs group by Size;

SET SQL_SAFE_UPDATES = 0;
update ds_jobs
set Size = case
	when Size = '-1' then 'Unknown'
    else Size
    end;
SET SQL_SAFE_UPDATES = 1;

select * from ds_jobs;

############################################################
# Founded
SET SQL_SAFE_UPDATES = 0;
update ds_jobs
set Founded = case
	when Founded <> -1 then (year(curdate()) - Founded)
    else -1
    end;
SET SQL_SAFE_UPDATES = 1;

alter table ds_jobs
rename column Founded to Company_Age;

####################################################################
# Type_of_ownership, Industry, Sector, Revenue
SET SQL_SAFE_UPDATES = 0;
update ds_jobs
set Type_of_ownership = case
	when Type_of_ownership = '-1' then 'Unknown'
    else Type_of_ownership
    end;
SET SQL_SAFE_UPDATES = 1;

select Type_of_ownership, count(Type_of_ownership) from ds_jobs group by Type_of_ownership;

SET SQL_SAFE_UPDATES = 0;
update ds_jobs
set Industry = case
	when Industry = '-1' then 'Unknown'
    else Industry
    end;
SET SQL_SAFE_UPDATES = 1;

select Industry, count(Industry) from ds_jobs group by Industry;

SET SQL_SAFE_UPDATES = 0;
update ds_jobs
set Sector = case
	when Sector = '-1' then 'Unknown'
    else Sector
    end;
SET SQL_SAFE_UPDATES = 1;

select Sector, count(Sector) from ds_jobs group by Sector order by Sector asc;

SET SQL_SAFE_UPDATES = 0;
update ds_jobs
set Revenue = case
	when Revenue = '-1' or Revenue = 'Unknown' then 'Unknown / Non-Applicable'
    else Revenue
    end;
SET SQL_SAFE_UPDATES = 1;

select Revenue, count(Revenue) from ds_jobs group by Revenue order by Revenue asc;

SET SQL_SAFE_UPDATES = 0;
update ds_jobs
set Competitors = case
	when Competitors = -1 then 'Unknown'
    else Competitors
    end;
SET SQL_SAFE_UPDATES = 1;

select Competitors, count(Competitors) from ds_jobs group by Competitors order by Competitors asc;

select * from ds_jobs;

########################################################################
# Merge ds_jobs after cleaning with CTE_4
with CTE_4  as (
	select Indexs,
	case
		when lower(Job_Description) like '%python%' then 1 else 0 end as Python,
	case
		when Job_Description like '%R%' then 1 else 0 end as R,
	case
		when lower(Job_Description) like '%java%' then 1 else 0 end as Java,
	case
		when lower(Job_Description) like '%scala%' then 1 else 0 end as Scala,
	case
		when Job_Description like '%C#%' then 1 else 0 end as C,    
	case
		when lower(Job_Description) like '%power_bi%' then 1 else 0 end as Power_BI ,
	case
		when lower(Job_Description) like '%tableau%' then 1 else 0 end as Tableau ,
	case 
		when lower(Job_Description) like '%excel%' then 1 else 0 end as Excel,
	case 
		when lower(Job_Description) like '%hadoop%' then 1 else 0 end as Hadoop,
	case 
		when lower(Job_Description) like '%aws%' then 1 else 0 end as AWS,
	case 
		when lower(Job_Description) like '%big_data%' then 1 else 0 end as Big_Data
	from ds_jobs)
select * from ds_jobs
inner join CTE_4
on ds_jobs.Indexs = CTE_4.Indexs;
