
use CpsWarehouse
go


/*Pysch 25290, therapist 277131, casemanager- 44679, outside - 445575 for patient*/
DROP view if exists  cps_all.tmp_view_PatientProvider;
go
create view cps_all.tmp_view_PatientProvider
as

WITH BHStaff as (
	select 
		PID PID, HDID HDID, OBSVALUE obsvalue, OBSDATE,
		rn = ROW_NUMBER() OVER (PARTITION BY PID,HDID ORDER BY OBSDATE DESC) 
	from [cpssql].CentricityPS.dbo.OBS 
	where HDID IN (44679,277131,25290,445575,74444,149227,372826,372827,129621)
)
,n as (
	select *, 
	replace(replace(replace(replace(substring(obsvalue, CHARINDEX(' ',obsvalue,0) + 1,LEN(obsvalue)-CHARINDEX(' ',obsvalue,0) + 1),'Psych APRN',''),',',''),'-',''),'LCSW','') lastName,
	SUBSTRING(obsvalue, 1, CHARINDEX(' ',obsvalue,0) ) firstName,
	case 
		when CHARINDEX('[', obsvalue, 0) > 0 and  CHARINDEX(']', obsvalue, 0) > 0
		then SUBSTRING(obsvalue, CHARINDEX('[', obsvalue, 0) + 1, CHARINDEX(']', obsvalue, 0) - CHARINDEX('[', obsvalue, 0) -1 )
	end username
	from BHStaff bh	
	where rn = 1
) --select * from n where hdid in (74444,149227,372826,372827)
, m as (
select n.HDID, n.pid, n.obsvalue,
	case 
		--when n.username is not null then df.ListName
		when usr.UserName is not null then usr.UserName
		when trim(obsvalue) in ('Dr.A','Dr. A') then 'userA'
		when df.listName is not null then df.UserName
	else null end [Name]

from n
	left join CpsWarehouse.cps_all.doctorfacility df on df.lastName  = n.lastName and df.firstName = n.firstName 
	left join CpsWarehouse.cps_all.doctorfacility usr on usr.UserName = n.username
)
	select 
		PID, HDID, [Name]
	from 
	(
		select PID, HDID, df.ListName [Name], rowNum = ROW_NUMBER() over(partition by pid, hdid order by hdid)
		from m
			left join cps_all.DoctorFacility df on df.UserName = m.Name
		where HDID is not null
	) x
	where rowNum = 1


go