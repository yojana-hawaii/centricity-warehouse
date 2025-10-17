
Use CpsWarehouse
GO

drop view if exists cps_all.tmp_view_PatientEducation;
go
create view cps_all.tmp_view_PatientEducation
as

-- education union from chc and obs
with pp as (
	SELECT PID,PatientProfileID,PatientID
	FROM [cpssql].CentricityPS.dbo.PatientProfile pp
	WHERE pp.PatientStatusMId NOT IN (-903,-902,-901)
)
, ed AS (
	-- from obs
	SELECT 
		obs.PID PID,pp.PatientId PatientID, pp.PatientProfileID PatientProfileID,
		OBSVALUE 'Level', obsdate Inputdate,
		(ISNULL(CASE 
				WHEN obsvalue = 'Bachelor Degree or higher'
					or obsvalue like '%master%'	or obsvalue like '%Bachelor%'
					or obsvalue like '%grad%' or obsvalue like '%PHD%' or obsvalue like '%univ%' 
				THEN 'Bachelor or Higher'
				WHEN obsvalue = 'Associate' or obsvalue like '%Assoc%' 
				THEN 'Associate'
				WHEN obsvalue = 'Some College but no degree' or obsvalue like 'colloge%'or obsvalue like '%college%' 
				THEN 'Some College'
				WHEN obsvalue = 'High School Graduate / GED' or OBSVALUE like '%ged%' or obsvalue like 'vocational%' 
				THEN 'High School Graduate / GED'
				WHEN OBSVALUE like '%High school%'
					or obsvalue like '%grade%' or obsvalue like '%12%' or obsvalue like '%11%'
					or obsvalue like '%10%' or obsvalue like '%9%' or obsvalue like '%7%' or obsvalue like '%6%' or obsvalue like '%5%'
					or obsvalue like '%8%' or obsvalue like '%high%' or obsvalue like 'elem%' 	or obsvalue like 'middle%' 
				THEN '< High School'
				END,'Unknown')) as Education
		FROM pp 
			LEFT JOIN [cpssql].[CentricityPS].dbo.obs on pp.pid = obs.pid
		WHERE obs.hdid = 3030 
	UNION
	-- education from chc registration
	SELECT pp.PID,pp.PATIENTid,pp.PatientProfileID,ed.[Description] 'Level',c.LastModified Inputdate,
		(case 
			when ed.Description IN ('BS College Degree','Doctorate Degree','Bachelor Degree','Some Grad School','Masters Degree') then 'Bachelor or Higher'
			when ed.Description IN ('AS College Degree','Associate Degree') then 'Associate'
			when ed.Description IN ('Some College') then 'Some College'
			when ed.Description IN ('High School Degree','GED','High School Diploma') then 'High School Graduate / GED'
			when ed.Description IN ('High School - No Diploma','Elementary','Intermediate or Jr High','Less than High School') then '< High School'
			when ed.Description in ('None (no education)') then 'None (no education)'
			else 'Unknown'
		end ) as Education
	from pp
		left join [cpssql].[CentricityPS].dbo.cusCHCPatientProfile c on c.PatientProfileID = pp.PatientProfileId
		left join [cpssql].[CentricityPS].dbo.cusCRIMedLists ed on ed.MedListsId = c.EducationLevelMID
	where ed.Description is not null 
) 
, c AS(
	--Cleaned up education
	select 
		e.PID,e.PatientProfileId,e.PatientId,e.Education,
		rn = ROW_NUMBER() OVER (PARTITION BY PID ORDER BY inputdate DESC) 
	from ed e
) 
	SELECT  PatientID, PatientProfileID, PID, Education, rn
	from c
	where rn = 1;


go
